extends Node

var mask_image: Image
var mask_texture: ImageTexture
var material
var texture_pos: Vector2
@onready var dust_sprite = $KartinaPyle

var brush_size = 10

var color_value: float = 0.0

func _ready() -> void:
    setup_mask_system()
    $TrapochkaArea.dragged.connect(_on_trapochka_dragged)

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


func erase_dust() -> void:
    if color_value >= 1:
        # Тут логика, когда всё вытерли
        return
    color_value += 0.01
    mask_image.fill(Color.from_hsv(color_value, color_value, color_value))
    mask_texture.update(mask_image)

func _on_trapochka_dragged(_trapochka: DraggableArea2D, old_pos: Vector2, new_pos: Vector2) -> void:
    print(old_pos.distance_to(new_pos))
    if old_pos.distance_to(new_pos) > 0.5 and $KartinaPyle.get_rect().has_point(new_pos):
        erase_dust()
