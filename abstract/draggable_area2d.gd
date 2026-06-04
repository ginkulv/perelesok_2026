extends Area2D
class_name DraggableArea2D

signal drag_started(item: Area2D, pos: Vector2)
signal drag_ended(item: Area2D, pos: Vector2)

@export var can_drag: bool = true

func update_drag_position(new_pos: Vector2) -> void:
	if can_drag:
		position = new_pos
