extends Area2D
class_name DraggableArea2D

signal drag_started(item: DraggableArea2D, pos: Vector2)
signal drag_ended(item: DraggableArea2D, pos: Vector2)

func _ready() -> void:
    add_to_group("draggable_item")

func update_drag_position(new_pos: Vector2) -> void:
    self.global_position = new_pos
