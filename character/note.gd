extends Node2D

@export var note_text: String = "Текст записки"

@onready var clickable_area: Area2D = $ClickableArea2D

func _ready() -> void:
	clickable_area.item_clicked.connect(_on_click)

func _on_click(_area: Area2D, _pos: Vector2) -> void:
	var note_ui = get_tree().get_first_node_in_group("note_ui")
	if note_ui:
		note_ui.show_note(note_text)
