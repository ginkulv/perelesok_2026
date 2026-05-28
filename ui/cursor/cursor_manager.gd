extends CanvasLayer

var cursor_sprite: Sprite2D
var cursor_pos: Vector2 = Vector2.ZERO
var cursor_offset: Vector2 = Vector2(-16, -16)

var dragged_item: DraggableItem = null 
var is_dragging: bool = false
var clicked_item: ClickableItem = null
var is_clicking: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var top_piece: Area2D = null

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

func _process(delta: float) -> void:
    if is_dragging and dragged_item:
        dragged_item.update_drag_position(cursor_pos + drag_offset)

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

    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        top_piece = _get_top_piece_at_position(cursor_pos)
        if top_piece and top_piece is DraggableItem:
            if event.pressed and dragged_item == null:
                _start_drag()
            elif not event.pressed and dragged_item != null:
                _end_drag()
        elif top_piece and top_piece is ClickableItem:
            if event.pressed and clicked_item == null:
                _start_click()
            elif not event.pressed and clicked_item != null:
                _end_click()

        var ui_element = _get_ui_element_at_position(cursor_pos)
        if event.pressed and ui_element:
                if ui_element is Button and ui_element.is_visible_in_tree():
                    print("UI element clicked: " + ui_element.to_string())
                    ui_element.button_up.emit()
                    return

func _start_drag() -> void:
    dragged_item = top_piece
    drag_offset = dragged_item.global_position - cursor_pos
    is_dragging = true
    dragged_item.drag_started.emit(dragged_item, cursor_pos)

func _end_drag() -> void:
    dragged_item.drag_ended.emit(dragged_item, cursor_pos)
    dragged_item = null
    is_dragging = false

func _start_click() -> void:
    clicked_item = top_piece
    is_clicking = true

func _end_click() -> void:
    var cur_top_piece = _get_top_piece_at_position(cursor_pos)
    if cur_top_piece == clicked_item:
        clicked_item.item_clicked.emit()
        clicked_item = null
    is_clicking = false


func _get_ui_element_at_position(pos: Vector2) -> Node:
    var ui_nodes: Array[Node] = get_tree().get_nodes_in_group("ui_elements")

    for node in ui_nodes:
        if node.visible and node.get_global_rect().has_point(pos):
            return node
    return null

func _get_top_piece_at_position(pos: Vector2) -> Area2D:
    var space_state = get_viewport().get_world_2d().direct_space_state
    var params = PhysicsPointQueryParameters2D.new() 
    params.position = pos 
    params.collide_with_areas = true
    params.collide_with_bodies = false

    var results = space_state.intersect_point(params)
    var highest_z = -INF
    top_piece = null

    for result in results:
        var collider = result.collider 
        if collider is Area2D:
            if collider.z_index > highest_z:
                highest_z = collider.z_index
                top_piece = collider

    return top_piece
