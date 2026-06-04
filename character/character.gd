extends Node2D

@onready var message_node: ClickableArea2D = $PlayerMessageArea2D

signal message_closed()

func _ready() -> void:
    message_node.visible = false
    message_node.item_clicked.connect(_on_message_area_clicked)
    MessageManager.message_shown.connect(_on_show_message)

func _on_show_message(message: String) -> void:
    $PlayerMessageArea2D/RichTextLabel.text = message
    message_node.visible = true

func _on_message_area_clicked(_item: ClickableArea2D, _pos: Vector2) -> void:
    message_node.visible = false
    message_closed.emit()
