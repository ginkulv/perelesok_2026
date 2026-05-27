extends Area2D

static var dragged_item: Area2D = null
var is_dragging = false
var drag_offset = Vector2.ZERO

func _ready() -> void:
    pass

func _input_event(viewport, event, shape_idx):
    # небольшой прототип всё-таки начался, план, чтобы не забыть
    # 1. сейчас иногда кусочки дальние берутся, исправить
    # 2. сделать какую-то рамку, куда надо попасть
    # 3. примагничивать при условном попадании
    # откладываем до лучших времён ¯\_(ツ)_/¯
    print("Input event received by: ", name, " (z_index: ", z_index, ")")
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        print(dragged_item)
        if event.pressed and dragged_item == null:
            dragged_item = self
            drag_offset = global_position - get_global_mouse_position()
            is_dragging = true
        else:
            dragged_item = null
            is_dragging = false


func _process(delta: float) -> void:
    if is_dragging:
        global_position = get_global_mouse_position() + drag_offset
