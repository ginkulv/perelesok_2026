extends Node2D

const INTRO_START_PHRASE := "Пу-пу-пу…"
const VICTORY_START_PHRASE := "Ура, получилось!"
const PLACED_PIECE_Z := 3
const ANCHOR_Z := 3
const NOTE_Z := 35
const VICTORY_END_PAUSE := 3.0
const VICTORY_LINE_PAUSE := 2.5

const DRAGGABLE_FRAGMENT_NAMES := [
	"JigsawFragment2", "JigsawFragment3", "JigsawFragment4",
	"JigsawFragment5", "JigsawFragment7", "JigsawFragment8", "JigsawFragment9",
]

@onready var expected_pos = {
	"JigsawFragment2": Vector2(1156.0, 312.0),
	"JigsawFragment3": Vector2(478.0, 291.0),
	"JigsawFragment4": Vector2(1873.0, 1222.0),
	"JigsawFragment5": Vector2(2327.0, 580.0),
	"JigsawFragment6": Vector2(1205.0, 806.0),
	"JigsawFragment7": Vector2(2126.0, 805.0),
	"JigsawFragment8": Vector2(370.0, 988.0),
	"JigsawFragment9": Vector2(756.0, 589.0),
}

var pieces_placed = 0
var total_pieces = 8
var puzzle_completed = false
var intro_complete = false
var _intro_active = false

func _ready() -> void:
	if AudioManager:
		AudioManager.play_music(load("res://assets/music/фото.mp3"))
	
	_remove_cutscene_overlay()
	_setup_anchor_piece()
	_connect_jigsaw_fragments()
	_lock_puzzle()
	LevelManager.level_changed.connect(_on_level_changed)
	_setup_sound_player()
	_setup_note_on_scene()
	
	MessageManager.message_shown.connect(_on_dialogue_shown)
	
	await LevelManager.play_fade_in()
	await _wait_for_character_ready()
	_start_intro_dialogue()
	
	print("=== УРОВЕНЬ 1 ЗАГРУЖЕН ===")


func _remove_cutscene_overlay() -> void:
	if has_node("AnimationPlayer"):
		$AnimationPlayer.queue_free()


func _setup_note_on_scene() -> void:
	if not has_node("Note"):
		return
	$Note.visible = true
	$Note.z_index = NOTE_Z
	var area: Area2D = $Note.get_node_or_null("ClickableArea2D")
	if area:
		area.z_index = NOTE_Z
		area.input_pickable = true
		area.monitorable = true


func _lock_puzzle() -> void:
	for name in DRAGGABLE_FRAGMENT_NAMES:
		var piece: DraggableArea2D = get_node(name)
		piece.can_drag = false


func _unlock_puzzle() -> void:
	for name in DRAGGABLE_FRAGMENT_NAMES:
		var piece: DraggableArea2D = get_node(name)
		piece.can_drag = true


func _connect_jigsaw_fragments() -> void:
	for name in DRAGGABLE_FRAGMENT_NAMES:
		get_node(name).drag_ended.connect(_on_jigsaw_placed)


func _wait_for_character_ready() -> void:
	for _i in range(30):
		if not get_tree().get_nodes_in_group("character").is_empty():
			await get_tree().process_frame
			return
		await get_tree().process_frame


func _start_intro_dialogue() -> void:
	_intro_active = true
	intro_complete = false
	MessageManager.begin_dialogue_at_text(INTRO_START_PHRASE, true)


func _on_dialogue_shown(message: String) -> void:
	if not _is_end_marker_ack(message):
		return
	if _intro_active:
		_intro_active = false
		intro_complete = true
		_unlock_puzzle()


func _is_end_marker_ack(message: String) -> bool:
	if message != "":
		return false
	var idx := MessageManager.current_index
	return idx > 0 and MessageManager.dialogue_list[idx - 1] == "__END__"


func _setup_anchor_piece() -> void:
	var anchor = $JigsawFragment6
	anchor.position = expected_pos["JigsawFragment6"]
	anchor.z_index = ANCHOR_Z
	anchor.can_drag = false
	anchor.input_pickable = false
	anchor.visible = true
	
	var sprite = anchor.get_node_or_null("JigsawFragmentSprite")
	if sprite:
		sprite.visible = true
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	pieces_placed += 1


func _setup_sound_player() -> void:
	if not has_node("PlaceSound"):
		var sound_player = AudioStreamPlayer2D.new()
		sound_player.name = "PlaceSound"
		add_child(sound_player)
		sound_player.stream = load("res://assets/sfx/берем кусочек фотографии.mp3")


func _play_place_sound() -> void:
	if has_node("PlaceSound") and $PlaceSound.stream:
		$PlaceSound.play()


func _on_jigsaw_placed(item: Area2D, _pos: Vector2) -> void:
	if puzzle_completed or not intro_complete:
		return
	
	var item_name = item.name
	
	if item_name == "JigsawFragment6":
		return
	
	if not expected_pos.has(item_name):
		return
	
	var target_pos = expected_pos[item_name]
	if item.position.distance_to(target_pos) >= 150:
		print("❌ Слишком далеко")
		return
	
	item.can_drag = false
	item.z_index = PLACED_PIECE_Z
	item.input_pickable = false
	item.position = target_pos
	
	var sprite = item.get_node_or_null("JigsawFragmentSprite")
	if sprite:
		sprite.visible = true
		sprite.modulate.a = 1.0
	
	if item.drag_ended.is_connected(_on_jigsaw_placed):
		item.drag_ended.disconnect(_on_jigsaw_placed)
	
	_play_place_sound()
	pieces_placed += 1
	
	print("✅ Собрано: ", pieces_placed, "/", total_pieces)
	
	match pieces_placed:
		2:
			MessageManager.show_event("first_piece")
		4:
			MessageManager.show_event("half_piece")
		7:
			MessageManager.show_event("last_piece")
	
	if pieces_placed >= total_pieces:
		_on_puzzle_complete()


func _on_puzzle_complete() -> void:
	if puzzle_completed:
		return
	
	puzzle_completed = true
	_lock_puzzle()
	
	if has_node("PhotoBackground"):
		$PhotoBackground.visible = true
		$PhotoBackground.modulate.a = 0.0
		var tween = create_tween()
		await tween.tween_property($PhotoBackground, "modulate:a", 1.0, 0.8).finished
	
	_hide_all_pieces()
	_bring_story_to_front()
	
	if MessageManager.begin_dialogue_at_text(VICTORY_START_PHRASE, true):
		await _auto_finish_dialogue_block(VICTORY_END_PAUSE, VICTORY_LINE_PAUSE)
	
	if LevelManager:
		await LevelManager.go_to_next_level()


func _bring_story_to_front() -> void:
	if has_node("Character"):
		$Character.z_index = 10
		$Character.visible = true
	_setup_note_on_scene()


func _auto_finish_dialogue_block(end_pause_sec: float, line_pause_sec: float) -> void:
	while MessageManager.is_dialogue_gated() and MessageManager.has_next():
		var next_line: String = MessageManager.dialogue_list[MessageManager.current_index]
		if next_line == "__END__":
			MessageManager.next_message()
			return
		MessageManager.next_message()
		if MessageManager.current_index < MessageManager.dialogue_list.size():
			next_line = MessageManager.dialogue_list[MessageManager.current_index]
		else:
			next_line = ""
		var delay := end_pause_sec if next_line == "__END__" else line_pause_sec
		await get_tree().create_timer(delay).timeout


func _hide_all_pieces() -> void:
	for name in expected_pos.keys():
		var fragment := get_node_or_null(name) as Area2D
		if fragment:
			fragment.visible = false
			fragment.process_mode = PROCESS_MODE_DISABLED


func _on_level_changed(_level_from: String, _level_to: String) -> void:
	if MessageManager.message_shown.is_connected(_on_dialogue_shown):
		MessageManager.message_shown.disconnect(_on_dialogue_shown)
