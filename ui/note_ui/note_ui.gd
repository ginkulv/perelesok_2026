extends Control

signal note_closed()

@onready var rich_text_label: RichTextLabel = $TextureRect/RichTextLabel
@onready var _paper: Control = $TextureRect

var _paper_layout_saved: bool = false
var _paper_offset_left: float
var _paper_offset_top: float
var _paper_offset_right: float
var _paper_offset_bottom: float
var _paper_pivot: Vector2
var _paper_scale: Vector2


func _ready() -> void:
	visible = false
	_save_paper_layout()


func show_note(text: String) -> void:
	rich_text_label.text = text
	_restore_paper_layout()
	_center_paper()
	rich_text_label.scale = Vector2.ONE
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	if CursorManager:
		CursorManager.enter_reading_mode()


func show_note_mirror_reveal(text: String, mirror_delay_sec: float = 2.0) -> void:
	show_note(text)
	_center_paper()
	_paper.pivot_offset = _paper_size() * 0.5
	_paper.scale = Vector2(-1.0, 1.0)
	await get_tree().create_timer(mirror_delay_sec).timeout
	var tween := create_tween()
	tween.tween_property(_paper, "scale:x", 1.0, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	await tween.finished


func hide_note() -> void:
	if not visible:
		return
	_restore_paper_layout()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if CursorManager:
		CursorManager.ensure_playing_mode()
	note_closed.emit()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		hide_note()
		accept_event()


func _save_paper_layout() -> void:
	if _paper_layout_saved:
		return
	_paper_offset_left = _paper.offset_left
	_paper_offset_top = _paper.offset_top
	_paper_offset_right = _paper.offset_right
	_paper_offset_bottom = _paper.offset_bottom
	_paper_pivot = _paper.pivot_offset
	_paper_scale = _paper.scale
	_paper_layout_saved = true


func _restore_paper_layout() -> void:
	_save_paper_layout()
	_paper.offset_left = _paper_offset_left
	_paper.offset_top = _paper_offset_top
	_paper.offset_right = _paper_offset_right
	_paper.offset_bottom = _paper_offset_bottom
	_paper.pivot_offset = _paper_pivot
	_paper.scale = _paper_scale


func _paper_size() -> Vector2:
	return Vector2(
		_paper.offset_right - _paper.offset_left,
		_paper.offset_bottom - _paper.offset_top
	)


func _center_paper() -> void:
	var size := _paper_size()
	var vp := get_viewport_rect().size
	var left := (vp.x - size.x) * 0.5
	var top := (vp.y - size.y) * 0.5
	_paper.offset_left = left
	_paper.offset_top = top
	_paper.offset_right = left + size.x
	_paper.offset_bottom = top + size.y
	_paper.pivot_offset = size * 0.5
