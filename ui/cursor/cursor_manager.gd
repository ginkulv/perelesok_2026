extends CanvasLayer

@export var invert_x: bool = false
@export var sensitivity: float = 1.0
@export var is_ui_mode: bool = true

var cursor_sprite: Sprite2D
var cursor_canvas_layer: CanvasLayer
var cursor_layer: int = 5
var cursor_pos: Vector2 = Vector2.ZERO

var dragged_item: DraggableArea2D = null 
var is_dragging: bool = false
var clicked_item: ClickableArea2D = null
var is_clicking: bool = false
var rotated_item: RotatableArea2D = null 
var is_rotating: bool = false
var rotation_pos: Vector2 = Vector2.ZERO
var drag_offset: Vector2 = Vector2.ZERO
var top_piece: Area2D = null

func _ready() -> void:
    # текущая реаизация:
    # два режима работы
    # 1. в игре используется фейковый курсор, кастомно взаимодействует через классы DraggableArea2D и ClickableArea2D
    # 2. в менюшках подменяется обычным курсором, за счёт чего все кнопки и слайдеры нормально работают
    # из проблем: курсор мигает при открытии меню, других пока не нашёл
    process_mode = Node.PROCESS_MODE_ALWAYS
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

    cursor_pos = get_viewport().get_visible_rect().size / 2

    var cursor_image = create_default_cursor_image()
    Input.set_custom_mouse_cursor(cursor_image)

    cursor_sprite = Sprite2D.new()
    cursor_sprite.texture = ImageTexture.create_from_image(cursor_image)
    cursor_sprite.centered = false
    cursor_sprite.z_index = 1000
    cursor_sprite.position = cursor_pos

    cursor_canvas_layer = CanvasLayer.new()
    cursor_canvas_layer.layer = cursor_layer
    cursor_canvas_layer.add_child(cursor_sprite)
    add_child(cursor_canvas_layer)

    GameState.state_changed.connect(_on_game_state_changed)

# жертва вайбкодинга
func create_default_cursor_image() -> Image:
    var dim = 24
    var image = Image.create(dim, dim, false, Image.FORMAT_RGBA8)
    image.fill(Color.TRANSPARENT)
    for x in range(dim):
        for y in range(dim):
            if x <= y and x < 24 and y < 24:
                image.set_pixel(x, y, Color.WHITE)
    return image

func _process(delta: float) -> void:
    if is_dragging and dragged_item:
        dragged_item.update_drag_position(cursor_pos + drag_offset)
    elif is_rotating and rotated_item:
        drag_offset = rotated_item.position - cursor_pos
        rotated_item.update_rotation(drag_offset)

func _input(event: InputEvent) -> void:
    if is_ui_mode:
        return

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
        print("---------------")
        print("cursor_pos")
        print(cursor_pos)
        print("_get_world_position()")
        print(_get_world_position())
        if event.pressed:
            # TODO этот код по сути сейчас нужен только для плашки дебага, потом поиск ui можно будет убрать, осталось от прошлой версии
            var ui_element = _get_ui_element_at_position(cursor_pos)
            if ui_element and ui_element is Button:
                print("UI element clicked: " + ui_element.to_string())
                ui_element.button_up.emit()
                return

            top_piece = _get_top_piece_at_position(_get_world_position())
            if top_piece and top_piece is DraggableArea2D and top_piece.can_drag and dragged_item == null:
                _start_drag()
            elif top_piece and top_piece is ClickableArea2D and clicked_item == null:
                _start_click()
            elif top_piece and top_piece is RotatableArea2D and rotated_item == null:
                _start_rotate()

        elif not event.pressed:
            if is_dragging:
                _end_drag()
            elif is_clicking:
                _end_click()
            elif is_rotating:
                _end_rotate()

func _start_drag() -> void:
    print("start drag " + str(cursor_pos) + ", " + top_piece.to_string())
    dragged_item = top_piece
    drag_offset = dragged_item.position - cursor_pos
    is_dragging = true
    dragged_item.drag_started.emit(dragged_item, cursor_pos)

func _end_drag() -> void:
    print("end drag " + str(cursor_pos) + ", " + top_piece.to_string())
    dragged_item.drag_ended.emit(dragged_item, cursor_pos)
    dragged_item = null
    is_dragging = false

func _start_click() -> void:
    print("start click: " + str(cursor_pos) + ", " + top_piece.to_string())
    clicked_item = top_piece
    is_clicking = true

func _end_click() -> void:
    print("end click " + str(cursor_pos) + ", " + top_piece.to_string())
    var cur_top_piece = _get_top_piece_at_position(_get_world_position())
    if cur_top_piece == clicked_item:
        clicked_item.item_clicked.emit(clicked_item, cursor_pos)
    clicked_item = null
    is_clicking = false

func _start_rotate() -> void:
    print("start rotate: " + str(cursor_pos) + ", " + top_piece.to_string())
    rotated_item = top_piece
    drag_offset = rotated_item.position - cursor_pos
    rotation_pos = cursor_pos
    cursor_sprite.visible = false
    is_rotating = true

func _end_rotate() -> void:
    print("end rotate " + str(cursor_pos) + ", " + top_piece.to_string())
    rotated_item = null
    cursor_pos = rotation_pos
    cursor_sprite.position = cursor_pos
    cursor_sprite.visible = true
    is_rotating = false

func _enter_ui() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    Input.warp_mouse(cursor_pos)
    cursor_sprite.visible = false
    is_ui_mode = true

func _exit_ui() -> void:
    cursor_pos = get_viewport().get_mouse_position()
    cursor_sprite.position = cursor_pos
    cursor_sprite.visible = true
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    is_ui_mode = false

func _get_ui_element_at_position(pos: Vector2) -> Node:
    var ui_nodes: Array[Node] = get_tree().get_nodes_in_group("ui_elements")

    for node in ui_nodes:
        if node.is_visible_in_tree() and node.get_global_rect().has_point(pos):
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
        if collider is Area2D and collider.is_visible_in_tree():
            if collider.z_index > highest_z:
                highest_z = collider.z_index
                top_piece = collider

    return top_piece


func _on_game_state_changed(_from_state: int, new_state: int) -> void:
    match new_state:
        GameState.PLAYING:
            print("exit_ui")
            _exit_ui()
        GameState.MAIN_MENU, GameState.PAUSE_MENU:
            print("enter_ui")
            _enter_ui()


func _get_world_position() -> Vector2:
    var cam = get_viewport().get_camera_2d()
    var screen_center = get_viewport().size / 2.0
    print("screen_center")
    print(screen_center)
    var cursor_offset = cursor_pos - screen_center
    print("cursor_offset")
    print(cursor_offset)
    print("cam.zoom")
    print(cam.zoom)
    return cam.global_position + cursor_offset / cam.zoom
