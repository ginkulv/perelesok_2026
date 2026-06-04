extends Node

var mask_image: Image
var mask_texture: ImageTexture
var material
var texture_pos: Vector2
@onready var dust_sprite = $KartinaPyle

var brush_size = 10

func _ready() -> void:
	setup_mask_system()

func _process(delta: float) -> void:
	var global_mouse = CursorManager.cursor_pos
	erase_at_position(CursorManager.cursor_pos)
	var sprite_global = dust_sprite.global_position
	var tex_size = dust_sprite.texture.get_size()
	var scale = dust_sprite.scale
	
	# Calculate the sprite's bounds in global coordinates
	var half_width = (tex_size.x * scale.x) / 2
	var half_height = (tex_size.y * scale.y) / 2
	
	var sprite_left = sprite_global.x - half_width
	var sprite_top = sprite_global.y - half_height
	
	# Convert global mouse to sprite-local pixel coordinates
	var local_x = (global_mouse.x - sprite_left) / scale.x
	var local_y = (global_mouse.y - sprite_top) / scale.y
	
	# Convert to texture pixel coordinates (0 to texture size)
	var tex_x = int(local_x)
	var tex_y = int(local_y)

	# Should show 0 to tex_size.x/y when moving mouse across sprite
	# print("Texture pixel: (", tex_x, ", ", tex_y, ") / (", tex_size.x, ", ", tex_size.y, ")")


func setup_mask_system() -> void:
	var mask_size = Vector2($KartinaPyle.texture.get_size().x, $KartinaPyle.texture.get_size().y)
	mask_image = Image.create(mask_size.x, mask_size.y, false, Image.FORMAT_RGBA8)
	mask_image.fill(Color.BLACK)

	print("mask_image.size")
	print(mask_image.get_width(), " ", mask_image.get_height())

	mask_texture = ImageTexture.create_from_image(mask_image)
	$KartinaPyle.material = create_shader_material()

func create_shader_material() -> ShaderMaterial:
	var shader = preload("res://levels/level2/dust.gdshader")
	material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("mask_texture", mask_texture)
	return material

func erase_at_position(pos: Vector2):
	var global_mouse = CursorManager.cursor_pos
	# erase_at_position(CursorManager.cursor_pos)
	var sprite_global = dust_sprite.global_position
	var tex_size = dust_sprite.texture.get_size()
	var scale = dust_sprite.scale

	# Calculate the sprite's bounds in global coordinates
	var half_width = (tex_size.x * scale.x) / 2
	var half_height = (tex_size.y * scale.y) / 2

	var sprite_left = sprite_global.x - half_width
	var sprite_top = sprite_global.y - half_height

	# Convert global mouse to sprite-local pixel coordinates
	var local_x = (global_mouse.x - sprite_left) / scale.x
	var local_y = (global_mouse.y - sprite_top) / scale.y

	# Convert to texture pixel coordinates (0 to texture size)
	var mask_x = int(local_x)
	var mask_y = int(local_y)

	draw_brush_on_mask(mask_x, mask_y, brush_size)


func draw_brush_on_mask(center_x: int, center_y: int, radius: int):
	var pixels_changed = 0

	for x in range(-radius, radius):
		for y in range(-radius, radius):
			var px = center_x + x
			var py = center_y + y
			if px >= 0 and px < mask_image.get_width() and py >= 0 and py < mask_image.get_height():
				var dist = sqrt(float(x*x + y*y))
				if dist < radius:
					var before = mask_image.get_pixel(px, py)
					mask_image.set_pixel(px, py, Color.WHITE)
					var after = mask_image.get_pixel(px, py)
					if before != after:
						pixels_changed += 1
	print("Pixels changed: ", pixels_changed)
	mask_texture.update(mask_image)
	print("Mask texture updated")
