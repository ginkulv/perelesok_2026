extends DraggableArea2D

@export var start_pos: Vector2 = Vector2(400.0, 580.0)
@export var end_pos: Vector2 = Vector2(700.0, 900.0)
@export var dot_product_threshold: float = 0.5
@export var move_threshold: float = 15.0

var direction: Vector2 = Vector2(end_pos.x - start_pos.x, end_pos.y - start_pos.y)

signal dragged_to_the_end()

func _ready() -> void:
    self.global_position = start_pos # TODO скорее всего надо будет убрать

func update_drag_position(new_position: Vector2) -> void:
    var drag_direction: Vector2 = Vector2(new_position.x - global_position.x, new_position.y - global_position.y)
    var dot_product = direction.normalized().dot(drag_direction.normalized())
    if abs(dot_product) > dot_product_threshold:
        var move_vector = direction.normalized() * drag_direction.length() * dot_product
        if move_vector.length() <= move_threshold:
            var expected_pos = global_position + move_vector
            self.global_position = expected_pos.clamp(start_pos, end_pos)
            if self.global_position == end_pos:
                dragged_to_the_end.emit()
