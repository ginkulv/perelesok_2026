extends Node

signal level_changed(level_from: String, level_to: String)

var num_of_levels: int = 5
var level_paths: Array[String] = []
var level_names: Array[String] = []
var index: int = 0
var current_level: Node

const FADE_DURATION := 0.9

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _is_transitioning: bool = false


func _ready() -> void:
	for i in range(1, num_of_levels + 1):
		level_paths.append("res://levels/level" + str(i) + "/level" + str(i) + ".tscn")
		level_names.append("Level" + str(i))
	_setup_fade_overlay()


func _setup_fade_overlay() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 128
	_fade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.modulate.a = 0.0
	_fade_layer.add_child(_fade_rect)


func reset_for_new_game(start_level_number: int = 1) -> void:
	index = clampi(start_level_number - 1, 0, num_of_levels - 1)
	_is_transitioning = false
	_set_fade_alpha(0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func get_level_scene_path(level_number: int) -> String:
	if level_number < 1 or level_number > num_of_levels:
		return ""
	return level_paths[level_number - 1]


func start_game_at_level(level_number: int) -> void:
	var level_path := get_level_scene_path(level_number)
	if level_path == "":
		push_warning("LevelManager: неверный номер уровня: %d" % level_number)
		return
	if MessageManager:
		MessageManager.reset_dialogue()
	reset_for_new_game(level_number)
	GameState.change_state(GameState.PLAYING)
	if CursorManager:
		CursorManager.ensure_playing_mode()
	get_tree().call_deferred("change_scene_to_file", level_path)


## Плавное появление уровня из чёрного (старт игры / после меню).
func play_fade_in() -> void:
	_set_fade_alpha(1.0)
	await _fade_from_black()


func go_to_next_level() -> void:
	if _is_transitioning:
		return
	_sync_index_from_active_level()
	if index >= num_of_levels - 1:
		push_warning("LevelManager: последний уровень (index=%d), переход невозможен" % index)
		return
	
	_is_transitioning = true
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var from_path := level_paths[index]
	await _fade_to_black()
	
	_remove_level_at_index(index)
	await get_tree().process_frame
	
	index += 1
	var level_scene = load(level_paths[index])
	current_level = level_scene.instantiate()
	get_tree().root.add_child(current_level)
	if get_tree().has_method("set_current_scene"):
		get_tree().set_current_scene(current_level)
	
	level_changed.emit(from_path, level_paths[index])
	
	await get_tree().process_frame
	await _fade_from_black()
	
	_is_transitioning = false
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if CursorManager:
		CursorManager.ensure_playing_mode()


func go_to_prev_level() -> void:
	if _is_transitioning or index <= 0:
		return
	
	_is_transitioning = true
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var from_path := level_paths[index]
	await _fade_to_black()
	
	_remove_level_at_index(index)
	await get_tree().process_frame
	
	index -= 1
	var level_scene = load(level_paths[index])
	current_level = level_scene.instantiate()
	get_tree().root.add_child(current_level)
	if get_tree().has_method("set_current_scene"):
		get_tree().set_current_scene(current_level)
	
	level_changed.emit(from_path, level_paths[index])
	
	await get_tree().process_frame
	await _fade_from_black()
	
	_is_transitioning = false
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if CursorManager:
		CursorManager.ensure_playing_mode()


func _sync_index_from_active_level() -> void:
	var root := get_tree().root
	for i in range(level_names.size()):
		if root.has_node(level_names[i]):
			index = i
			return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var scene_index := level_names.find(scene.name)
	if scene_index >= 0:
		index = scene_index


func _remove_level_at_index(level_index: int) -> void:
	if level_index < 0 or level_index >= level_names.size():
		return
	var node_name := level_names[level_index]
	var root := get_tree().root
	if root.has_node(node_name):
		root.get_node(node_name).queue_free()
		return
	var scene := get_tree().current_scene
	if scene and scene.name == node_name:
		scene.queue_free()


func _fade_to_black() -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 1.0, FADE_DURATION)
	await tween.finished


func _fade_from_black() -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 0.0, FADE_DURATION)
	await tween.finished


func _set_fade_alpha(alpha: float) -> void:
	_fade_rect.modulate.a = alpha
