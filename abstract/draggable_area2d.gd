extends Area2D
class_name DraggableArea2D

signal drag_started(item: DraggableArea2D, pos: Vector2)
signal drag_ended(item: DraggableArea2D, pos: Vector2)
signal dragged(item: DraggableArea2D, old_pos: Vector2, new_pos: Vector2)

@export var can_drag: bool = true

func _ready() -> void:
    add_to_group("draggable_item")

func update_drag_position(new_pos: Vector2) -> void:
    dragged.emit(self, self.position, new_pos)
    self.position = new_pos
