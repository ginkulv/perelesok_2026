extends Area2D
class_name DraggableArea2D

signal drag_started(item: DraggableArea2D, pos: Vector2)
signal drag_ended(item: DraggableArea2D, pos: Vector2)
signal dragged(item: DraggableArea2D, old_pos: Vector2, new_pos: Vector2)

@export var can_drag: bool = true

func _ready() -> void:
	add_to_group("draggable_item")

## new_world_pos — позиция в координатах мира (как у курсора).
func update_drag_position(new_world_pos: Vector2) -> void:
	var old_pos := position
	var local_pos := new_world_pos
	var parent_2d := get_parent() as Node2D
	if parent_2d:
		local_pos = parent_2d.to_local(new_world_pos)
	dragged.emit(self, old_pos, local_pos)
	position = local_pos
