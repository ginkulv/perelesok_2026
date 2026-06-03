extends Node2D

@onready var message_node: ClickableArea2D = $PlayerMessageArea2D

func _ready() -> void:
	message_node.visible = false
	message_node.item_clicked.connect(_on_message_area_clicked)

func show_message(message: String) -> void:
	$PlayerMessageArea2D/RichTextLabel.text = message
	message_node.visible = true

func _on_message_area_clicked(_item: ClickableArea2D, _pos: Vector2) -> void:
	print("message area clisladfSl")
	message_node.visible = false
