extends Node2D

const INTRO_START_PHRASE := "Ой! Что случилось?"
const DIALOGUE_UNMIRROR_PHRASE := "Сейчас, подожди, тебе неудобно, наверное"
const STUCK_HINT := "Застряла… Протяни к широкому месту."
const NOTE_ID := 3

const LEVEL_START_DELAY := 1.0
const DIALOGUE_LINE_PAUSE := 2.5
const DIALOGUE_END_PAUSE := 3.0
const MIRROR_NOTE_FLIP_DELAY := 2.0
const TEXT_UNMIRROR_DURATION := 0.6
const Z_CHARACTER := 10
const Z_NOTE_COLLECTIBLE := 12

var _puzzle_finished: bool = false
var _intro_done: bool = false
var _hint_shown: bool = false
var _carpet_open: bool = false
var _saved_invert_x: bool = false
var _dialogue_readable: bool = false


@onready var _room: Sprite2D = $RoomBackground
@onready var _carpet: Area2D = $CarpetArea2D
@onready var _floor_note: Node = $NoteArea2D
@onready var _character: Node2D = $Character


func _ready() -> void:
	GameState.change_state(GameState.PLAYING)
	if CursorManager:
		CursorManager.ensure_playing_mode()
		_saved_invert_x = CursorManager.invert_x
		CursorManager.invert_x = true

	AudioManager.play_music(load("res://assets/music/зеркало.mp3"))
	_setup_scene()
	_connect_puzzle_signals()
	_run_level_flow()


func _setup_scene() -> void:
	_character.z_index = Z_CHARACTER
	_dialogue_readable = false
	_apply_dialogue_text_style()
	if has_node("Note"):
		$Note.visible = false
		$Note.z_index = Z_NOTE_COLLECTIBLE
	_floor_note.set_phase(_floor_note.Phase.HIDDEN)
	_floor_note.z_index = 11
	_carpet.z_index = 8
	_set_carpet_open(false)
	_lock_puzzle_interactions()


func _connect_puzzle_signals() -> void:
	_carpet.item_clicked.connect(_on_carpet_clicked)
	_floor_note.tug_requested.connect(_on_note_tugged)
	_floor_note.reached_end.connect(_on_note_reached_end)


func _lock_puzzle_interactions() -> void:
	_carpet.input_pickable = false
	_carpet.monitorable = false


func _unlock_puzzle_interactions() -> void:
	_carpet.input_pickable = true
	_carpet.monitorable = true


func _run_level_flow() -> void:
	await get_tree().create_timer(LEVEL_START_DELAY).timeout
	await _wait_for_character_ready()
	_dialogue_readable = false
	_apply_dialogue_text_style()
	if MessageManager.begin_dialogue_at_text(INTRO_START_PHRASE, true):
		_sync_character_dialogue()
		await _auto_finish_dialogue_block(DIALOGUE_END_PAUSE, DIALOGUE_LINE_PAUSE)
	_intro_done = true
	_unlock_puzzle_interactions()


func _on_carpet_clicked(_area: Area2D, _pos: Vector2) -> void:
	if not _intro_done or _puzzle_finished:
		return
	_carpet_open = not _carpet_open
	_set_carpet_open(_carpet_open)
	if _carpet_open:
		_floor_note.set_phase(_floor_note.Phase.STUCK)
	else:
		if _floor_note.phase != _floor_note.Phase.AT_END:
			_floor_note.set_phase(_floor_note.Phase.HIDDEN)


func _set_carpet_open(open: bool) -> void:
	_carpet_open = open
	var closed_col: Node = _carpet.get_node("CarpetClosedCollision")
	var opened_col: Node = _carpet.get_node("CarpetOpenedCollision")
	var closed_sprite: Node = _carpet.get_node("CarpetClosedSprite")
	var opened_sprite: Node = _carpet.get_node("CarpetOpenedSprite")
	closed_col.visible = not open
	closed_sprite.visible = not open
	opened_col.visible = open
	opened_sprite.visible = open


func _on_note_tugged() -> void:
	if _puzzle_finished or _floor_note.phase != _floor_note.Phase.STUCK:
		return
	if not _hint_shown:
		_hint_shown = true
		_dialogue_readable = true
		_apply_dialogue_text_style()
		MessageManager.show_text(STUCK_HINT)
		_sync_character_dialogue()
	_floor_note.set_phase(_floor_note.Phase.DRAGGABLE)


func _on_note_reached_end() -> void:
	if _puzzle_finished:
		return
	await get_tree().process_frame
	_complete_puzzle()


func _complete_puzzle() -> void:
	if _puzzle_finished:
		return
	_puzzle_finished = true
	_lock_puzzle_interactions()
	_floor_note.input_pickable = false
	if _character.has_method("force_hide_message"):
		_character.force_hide_message()

	var note_text := _get_note_text()
	await _show_mirror_note_ui(note_text)
	_reset_mirror_controls()
	await LevelManager.go_to_next_level()


func _get_note_text() -> String:
	if MessageManager and NOTE_ID >= 0 and NOTE_ID < MessageManager.note.size():
		return MessageManager.note[NOTE_ID]
	return "Спасибо, что был рядом."


func _show_mirror_note_ui(text: String) -> void:
	var note_ui = get_tree().get_first_node_in_group("note_ui")
	if note_ui == null:
		push_warning("Level4: note_ui не найден, переход через 2 с")
		await get_tree().create_timer(2.0).timeout
		return
	if note_ui.has_method("show_note_mirror_reveal"):
		await note_ui.show_note_mirror_reveal(text, MIRROR_NOTE_FLIP_DELAY)
	else:
		note_ui.show_note(text)
	while is_instance_valid(note_ui) and note_ui.visible:
		await get_tree().process_frame


func _reset_mirror_controls() -> void:
	if CursorManager:
		CursorManager.invert_x = _saved_invert_x


func _apply_dialogue_text_style(tween_duration: float = 0.0) -> void:
	if _character.has_method("set_dialogue_text_readable"):
		_character.set_dialogue_text_readable(_dialogue_readable, tween_duration)


func _sync_character_dialogue() -> void:
	var message := MessageManager.get_last_shown_message()
	if message == "" or not is_instance_valid(_character):
		return
	if _character.has_method("show_message"):
		_character.show_message(message)


func _wait_for_character_ready() -> void:
	for _i in range(30):
		if not get_tree().get_nodes_in_group("character").is_empty():
			await get_tree().process_frame
			return
		await get_tree().process_frame


func _auto_finish_dialogue_block(end_pause_sec: float, line_pause_sec: float) -> void:
	while MessageManager.is_dialogue_gated() and MessageManager.has_next():
		var next_line: String = MessageManager.dialogue_list[MessageManager.current_index]
		if next_line == "__END__":
			MessageManager.next_message()
			_sync_character_dialogue()
			return
		var line_to_show: String = MessageManager.dialogue_list[MessageManager.current_index]
		var is_unmirror_line := line_to_show == DIALOGUE_UNMIRROR_PHRASE
		MessageManager.next_message()
		_sync_character_dialogue()
		if not is_unmirror_line:
			_apply_dialogue_text_style(0.0)
		if MessageManager.current_index < MessageManager.dialogue_list.size():
			next_line = MessageManager.dialogue_list[MessageManager.current_index]
		else:
			next_line = ""
		var delay := end_pause_sec if next_line == "__END__" else line_pause_sec
		await get_tree().create_timer(delay).timeout
		if is_unmirror_line:
			_dialogue_readable = true
			_apply_dialogue_text_style(TEXT_UNMIRROR_DURATION)
			await get_tree().create_timer(TEXT_UNMIRROR_DURATION).timeout
