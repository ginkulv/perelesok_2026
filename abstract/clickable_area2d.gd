extends Area2D
class_name ClickableArea2D

signal item_clicked(item: ClickableArea2D, pos: Vector2)

func _ready() -> void:
    add_to_group("clickable_item")
