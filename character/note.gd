extends Node2D

@export var note_id: int = 0

@onready var clickable_area: Area2D = $ClickableArea2D

var note_text: String = ""  # 👈 Объявляем переменную

func _ready() -> void:
	clickable_area.add_to_group("note_click")
	clickable_area.item_clicked.connect(_on_click)
	
	# Получаем текст записки из MessageManager
	if MessageManager and note_id < MessageManager.note.size():
		note_text = MessageManager.note[note_id]
		print("📝 Записка ", note_id, " загружена: ", note_text)
	else:
		print("⚠️ Записка с ID ", note_id, " не найдена в MessageManager!")

func _on_click(_area: Area2D, _pos: Vector2) -> void:
	var note_ui = get_tree().get_first_node_in_group("note_ui")
	if note_ui:
		note_ui.show_note(note_text)
	else:
		print("⚠️ NoteUi не найден в группе 'note_ui'")
