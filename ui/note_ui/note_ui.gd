extends Control

@onready var rich_text_label: RichTextLabel = $TextureRect/RichTextLabel

func _ready() -> void:
	visible = false

func show_note(text: String) -> void:
	rich_text_label.text = text
	visible = true

func hide_note() -> void:
	visible = false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		hide_note()
