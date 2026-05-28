extends Area2D
class_name ClickableItem

signal item_clicked(item: ClickableItem, pos: Vector2)

func _ready() -> void:
    add_to_group("clickable_item")
