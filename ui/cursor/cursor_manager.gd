extends CanvasLayer

var cursor_sprite: Sprite2D
var cursor_pos: Vector2 = Vector2.ZERO
var cursor_offset: Vector2 = Vector2(-16, -16)

@export var invert_x: bool = false
@export var sensitivity: float = 1.0


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    # Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

    cursor_pos = get_viewport().get_visible_rect().size / 2

    cursor_sprite = Sprite2D.new()
    cursor_sprite.texture = create_default_cursor_texture()
    cursor_sprite.centered = false
    cursor_sprite.z_index = 1000
    cursor_sprite.position = cursor_pos
    add_child(cursor_sprite)

# жертва вайбкодинга
func create_default_cursor_texture() -> Texture2D:
    var dim = 24
    var image = Image.create(dim, dim, false, Image.FORMAT_RGBA8)
    image.fill(Color.TRANSPARENT)
    for x in range(dim):
        for y in range(dim):
            if x <= y and x < 24 and y < 24:
                image.set_pixel(x, y, Color.WHITE)

    return ImageTexture.create_from_image(image)


func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        var movement = event.relative

        if invert_x == true:
            cursor_pos.x -= movement.x * sensitivity
        else:
            cursor_pos.x += movement.x * sensitivity
        cursor_pos.y += movement.y * sensitivity
        var screen_size = get_viewport().get_visible_rect().size
        cursor_pos = cursor_pos.clamp(Vector2.ZERO, screen_size)
        cursor_sprite.position = cursor_pos

    if event is InputEventMouseButton and event.pressed:
        var fake_click = event.duplicate()
        var cursor_pos_top_right = cursor_pos #+ cursor_offset
        fake_click.global_position = cursor_pos_top_right
        fake_click.position = cursor_pos_top_right

        var ui_element = _get_ui_element_at_position(cursor_pos)
        if ui_element:
            if ui_element is Button:
                print("UI element clicked: " + ui_element.to_string())
                ui_element.button_up.emit()
                return

func _get_ui_element_at_position(pos: Vector2) -> Node:
    var ui_nodes: Array[Node] = get_tree().get_nodes_in_group("ui_elements")

    for node in ui_nodes:
        if node.visible and node.get_global_rect().has_point(pos):
            return node
    return null
