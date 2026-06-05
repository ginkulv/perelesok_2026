extends Node2D

const INTRO_START_PHRASE := "Спасибо, что ты был рядом всё это время."
const RESPONSE_ENCOURAGE := "Спасибо... Тогда я попробую. Правда попробую."
const RESPONSE_WARN := "Значит, не надо притворяться, что легко. Это честно. Спасибо."
const FAREWELL_PHRASE := "Прощай. И спасибо ещё раз."

const TRAVEL_MESSAGE_DIR := "res://travel_message/"
const TRAVEL_IMAGE_EXTENSIONS := ["png", "jpg", "jpeg", "webp"]

const LEVEL_START_DELAY := 1.0
const INTRO_LINE_PAUSE := 2.8
const INTRO_END_PAUSE := 3.5
const RESPONSE_PAUSE := 3.0
const FAREWELL_PAUSE := 2.5
const ROOM_FADE_DURATION := 0.9
const GOODBYE_WAVE_DURATION := 3.0
const DESKTOP_FADE_DURATION := 2.5
const AFTER_GOODBYE_PAUSE := 5.0

const Z_CHARACTER := 10
const Z_NOTE := 12

var _choice_layer: CanvasLayer
var _choice_picked: bool = false
var _choice_value: int = 0
var _desktop_mode_active: bool = false


@onready var _room: Sprite2D = $RoomBackground
@onready var _character: Node2D = $Character


func _ready() -> void:
	GameState.change_state(GameState.PLAYING)
	_ensure_opaque_room_window()
	if CursorManager:
		CursorManager.invert_x = false
		CursorManager.ensure_playing_mode()

	_setup_scene()
	AudioManager.play_music(load("res://assets/music/счастливый финал.mp3"))
	_run_level_flow()


func _setup_scene() -> void:
	_character.z_index = Z_CHARACTER
	if has_node("Note"):
		$Note.visible = true
		$Note.modulate.a = 1.0
		$Note.z_index = Z_NOTE
		var area: Area2D = $Note.get_node_or_null("ClickableArea2D")
		if area:
			area.z_index = Z_NOTE
			area.input_pickable = true
			area.monitorable = true


func _run_level_flow() -> void:
	await get_tree().create_timer(LEVEL_START_DELAY).timeout
	await _wait_for_character_ready()
	if MessageManager.begin_dialogue_at_text(INTRO_START_PHRASE, true):
		_sync_character_dialogue()
		await _auto_finish_dialogue_block(INTRO_END_PAUSE, INTRO_LINE_PAUSE)
	await _show_choice()
	await _play_response_and_farewell()
	await _play_desktop_sequence()
	_disable_desktop_mode()
	_go_to_main_menu()


func _show_choice() -> void:
	if _character.has_method("force_hide_message"):
		_character.force_hide_message()

	_choice_layer = CanvasLayer.new()
	_choice_layer.layer = 20
	add_child(_choice_layer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 420.0
	_choice_layer.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)

	var encourage_btn := _make_choice_button("Ты справишься!", 0)
	var warn_btn := _make_choice_button("Будет непросто.", 1)
	box.add_child(encourage_btn)
	box.add_child(warn_btn)

	if CursorManager:
		CursorManager.enter_reading_mode()
	_choice_picked = false
	while not _choice_picked:
		await get_tree().process_frame
	if CursorManager:
		CursorManager.ensure_playing_mode()
	_choice_layer.queue_free()
	_choice_layer = null


func _make_choice_button(label_text: String, choice_id: int) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(520, 56)
	button.add_to_group("ui_elements")
	button.pressed.connect(func() -> void:
		_choice_value = choice_id
		_choice_picked = true
		AudioManager.play_sfx("выбор предмета 1.mp3", 0.4)
	)
	return button


func _play_response_and_farewell() -> void:
	var response := RESPONSE_ENCOURAGE if _choice_value == 0 else RESPONSE_WARN
	MessageManager.show_text(response)
	_sync_character_dialogue()
	await get_tree().create_timer(RESPONSE_PAUSE).timeout

	MessageManager.show_text(FAREWELL_PHRASE)
	_sync_character_dialogue()
	await get_tree().create_timer(FAREWELL_PAUSE).timeout

	if _character.has_method("force_hide_message"):
		_character.force_hide_message()


func _play_desktop_sequence() -> void:
	if _character.has_method("force_hide_message"):
		_character.force_hide_message()
	_hide_character_bubble()

	var room_tween := create_tween()
	room_tween.set_parallel(true)
	room_tween.tween_property(_room, "modulate:a", 0.0, ROOM_FADE_DURATION)
	if has_node("Note"):
		room_tween.tween_property($Note, "modulate:a", 0.0, ROOM_FADE_DURATION)
	await room_tween.finished

	_room.visible = false
	if has_node("Note"):
		$Note.visible = false

	_enable_desktop_mode()
	_character.modulate.a = 1.0
	_character.visible = true

	if _character.has_method("play_goodbye"):
		await _character.play_goodbye(GOODBYE_WAVE_DURATION)

	var disappear := create_tween()
	disappear.tween_property(_character, "modulate:a", 0.0, DESKTOP_FADE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await disappear.finished

	_character.visible = false
	_place_desktop_travel_image()
	await get_tree().create_timer(AFTER_GOODBYE_PAUSE).timeout


func _enable_desktop_mode() -> void:
	_desktop_mode_active = true
	get_viewport().transparent_bg = true
	var window := get_viewport().get_window()
	if window:
		window.transparent = true


func _disable_desktop_mode() -> void:
	if not _desktop_mode_active:
		return
	_desktop_mode_active = false
	_ensure_opaque_room_window()


func _ensure_opaque_room_window() -> void:
	get_viewport().transparent_bg = false
	var window := get_viewport().get_window()
	if window:
		window.transparent = false


func _hide_character_bubble() -> void:
	var bubble := _character.get_node_or_null("PlayerMessageArea2D")
	if bubble:
		bubble.visible = false


func _place_desktop_travel_image() -> void:
	var images := _list_travel_images()
	if images.is_empty():
		push_warning("Level5: в %s нет картинок" % TRAVEL_MESSAGE_DIR)
		return

	var picked: String = images[randi() % images.size()]
	var desktop := OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	if desktop.is_empty():
		desktop = OS.get_user_data_dir()

	var dest_name := "записка_%s" % picked.get_file()
	var dest_path := desktop.path_join(dest_name)
	var src_path := ProjectSettings.globalize_path(picked)

	if FileAccess.file_exists(dest_path):
		DirAccess.remove_absolute(dest_path)

	var err := DirAccess.copy_absolute(src_path, dest_path)
	if err != OK:
		push_warning("Level5: не удалось скопировать %s → %s (err %d)" % [src_path, dest_path, err])
		return
	print("✅ Записка на рабочем столе: ", dest_path)


func _list_travel_images() -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(TRAVEL_MESSAGE_DIR)
	if dir == null:
		return result
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and _is_travel_image(entry):
			result.append(TRAVEL_MESSAGE_DIR.path_join(entry))
		entry = dir.get_next()
	dir.list_dir_end()
	return result


func _is_travel_image(filename: String) -> bool:
	var lower := filename.to_lower()
	for ext in TRAVEL_IMAGE_EXTENSIONS:
		if lower.ends_with("." + ext):
			return true
	return false


func _go_to_main_menu() -> void:
	_disable_desktop_mode()
	get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")


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
		MessageManager.next_message()
		_sync_character_dialogue()
		if MessageManager.current_index < MessageManager.dialogue_list.size():
			next_line = MessageManager.dialogue_list[MessageManager.current_index]
		else:
			next_line = ""
		var delay := end_pause_sec if next_line == "__END__" else line_pause_sec
		await get_tree().create_timer(delay).timeout
