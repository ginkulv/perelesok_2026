extends Node

## Стирание пыли: маска + простой шейдер (как на godotshaders.com).
## AtlasTexture заменяется на ImageTexture региона — UV и маска совпадают 1:1.

signal dust_fully_cleaned

const SHADER := preload("res://levels/level2/dust.gdshader")
const STROKE_STEP_PX := 8.0
const SCREEN_BRUSH_RADIUS_PX := 36.0
const MASK_RESOLUTION_SCALE := 0.25
const FADE_OUT_DURATION := 1.4

@export var debug_coords: bool = false

@export var dust_sprite: Sprite2D
@export var clean_ratio: float = 0.4
@export var fade_duration: float = FADE_OUT_DURATION

var mask_image: Image
var mask_texture: ImageTexture
var shader_material: ShaderMaterial

var erased_pixels: int = 0
var total_pixels: int = 0
var is_cleaned: bool = false
var is_fading: bool = false

var _fade_tween: Tween

var _texture_size: Vector2 = Vector2.ZERO
var _mask_size: Vector2i = Vector2i.ZERO
var _sprite_rect: Rect2 = Rect2()
var _last_dust_local: Vector2 = Vector2.INF
var _brush_radius_mask_px: int = 16
var _mask_dirty: bool = false


func _process(_delta: float) -> void:
	if _mask_dirty:
		mask_texture.update(mask_image)
		_mask_dirty = false


func setup() -> void:
	if dust_sprite == null or dust_sprite.texture == null:
		push_error("DustWipeSystem: нет спрайта пыли или текстуры")
		return

	_replace_atlas_with_image_texture()
	_texture_size = dust_sprite.texture.get_size()
	_sprite_rect = dust_sprite.get_rect()

	var mask_w := maxi(1, int(_texture_size.x * MASK_RESOLUTION_SCALE))
	var mask_h := maxi(1, int(_texture_size.y * MASK_RESOLUTION_SCALE))
	_mask_size = Vector2i(mask_w, mask_h)

	mask_image = Image.create(mask_w, mask_h, false, Image.FORMAT_RGBA8)
	mask_image.fill(Color.BLACK)
	erased_pixels = 0
	total_pixels = mask_w * mask_h
	is_cleaned = false
	is_fading = false
	_last_dust_local = Vector2.INF
	_mask_dirty = false
	if dust_sprite:
		dust_sprite.visible = true
		dust_sprite.modulate.a = 1.0
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
		_fade_tween = null

	var sprite_scale := maxf(
		maxf(absf(dust_sprite.scale.x), absf(dust_sprite.scale.y)),
		0.001
	)
	_brush_radius_mask_px = maxi(
		4,
		int(SCREEN_BRUSH_RADIUS_PX / sprite_scale * MASK_RESOLUTION_SCALE)
	)

	mask_texture = ImageTexture.create_from_image(mask_image)
	shader_material = ShaderMaterial.new()
	shader_material.shader = SHADER
	shader_material.set_shader_parameter("mask_texture", mask_texture)
	dust_sprite.material = shader_material


func reset() -> void:
	setup()


func reset_stroke() -> void:
	_last_dust_local = Vector2.INF


func process_wipe_at_global(global_pos: Vector2) -> void:
	process_wipe_at_dust_local(dust_sprite.to_local(global_pos))


func process_wipe_at_dust_local(dust_local: Vector2) -> void:
	if is_cleaned or is_fading or mask_image == null:
		return

	if _last_dust_local != Vector2.INF:
		_paint_stroke(_last_dust_local, dust_local)
	else:
		_paint_dab(dust_local)
	_last_dust_local = dust_local


func _replace_atlas_with_image_texture() -> void:
	var atlas_tex := dust_sprite.texture as AtlasTexture
	if atlas_tex == null:
		return
	var region_image := atlas_tex.get_image()
	if region_image == null or region_image.is_empty():
		push_warning("DustWipeSystem: не удалось извлечь регион из AtlasTexture")
		return
	dust_sprite.texture = ImageTexture.create_from_image(region_image)


func _local_to_mask_pixel(local_pos: Vector2) -> Vector2i:
	if not _sprite_rect.has_point(local_pos):
		return Vector2i(-1, -1)

	var uv := Vector2(
		(local_pos.x - _sprite_rect.position.x) / _sprite_rect.size.x,
		(local_pos.y - _sprite_rect.position.y) / _sprite_rect.size.y
	)
	return Vector2i(
		int(clampf(uv.x, 0.0, 1.0) * float(_mask_size.x - 1)),
		int(clampf(uv.y, 0.0, 1.0) * float(_mask_size.y - 1))
	)


func _paint_dab(dust_local: Vector2) -> void:
	var pixel := _local_to_mask_pixel(dust_local)
	if pixel.x < 0:
		return
	if _stamp_brush(pixel):
		_mask_dirty = true
		_check_progress()


func _paint_stroke(from_local: Vector2, to_local: Vector2) -> void:
	var distance := from_local.distance_to(to_local)
	if distance < 0.5:
		return
	var steps := maxi(int(distance / STROKE_STEP_PX), 1)
	var changed := false
	for step in range(steps + 1):
		var t := float(step) / float(steps)
		var pos := from_local.lerp(to_local, t)
		var pixel := _local_to_mask_pixel(pos)
		if pixel.x < 0:
			continue
		changed = _stamp_brush(pixel) or changed
	if changed:
		_mask_dirty = true
		_check_progress()


func _stamp_brush(center: Vector2i) -> bool:
	var radius := _brush_radius_mask_px
	var radius_sq := radius * radius
	var changed := false
	for dy in range(-radius, radius + 1):
		var dx_limit := int(sqrt(float(radius_sq - dy * dy)))
		for dx in range(-dx_limit, dx_limit + 1):
			var px := center.x + dx
			var py := center.y + dy
			if px < 0 or py < 0 or px >= _mask_size.x or py >= _mask_size.y:
				continue
			if mask_image.get_pixel(px, py).r >= 0.95:
				continue
			mask_image.set_pixel(px, py, Color.WHITE)
			erased_pixels += 1
			changed = true
	return changed


func _check_progress() -> void:
	if is_cleaned or is_fading or total_pixels <= 0:
		return
	if float(erased_pixels) / float(total_pixels) >= clean_ratio:
		_begin_fade_out()


func _begin_fade_out() -> void:
	if is_cleaned or is_fading or dust_sprite == null:
		return
	is_fading = true
	_last_dust_local = Vector2.INF
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	dust_sprite.modulate.a = 1.0
	_fade_tween = create_tween()
	_fade_tween.tween_property(dust_sprite, "modulate:a", 0.0, fade_duration)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	_fade_tween.finished.connect(_on_fade_out_finished)


func _on_fade_out_finished() -> void:
	is_fading = false
	is_cleaned = true
	if dust_sprite:
		dust_sprite.visible = false
		dust_sprite.modulate.a = 1.0
	dust_fully_cleaned.emit()
