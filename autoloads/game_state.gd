extends Node

@onready var pause_menu_scene = preload("res://ui/pause_menu/pause_menu.tscn")

enum {
	MAIN_MENU,
	PAUSE_MENU,
	PLAYING,
	CUTSCENE,
}

signal state_changed(from_state: int, to_state: int)

var current_state: int = PLAYING
var pause_menu: CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu = pause_menu_scene.instantiate()
	add_child(pause_menu)
	pause_menu.hide()

func change_state(new_state: int) -> void:
	state_changed.emit(current_state, new_state)
	current_state = new_state
	print(new_state)

func _input(event: InputEvent) -> void:
	if _is_main_menu_active() and event is InputEventKey and event.pressed and not event.echo:
		var level_number := _hotkey_level_number(event as InputEventKey)
		if level_number > 0 and LevelManager:
			LevelManager.start_game_at_level(level_number)
			get_viewport().set_input_as_handled()
			return

	if event.is_action_pressed("toggle_pause_menu"):
		match current_state:
			PLAYING:
				pause_menu.open()
				change_state(PAUSE_MENU)
			PAUSE_MENU:
				pause_menu.close()
				change_state(PLAYING)


func _is_main_menu_active() -> bool:
	if current_state == MAIN_MENU:
		return true
	var scene := get_tree().current_scene
	return scene != null and scene.name == "MainMenu"


func _hotkey_level_number(event: InputEventKey) -> int:
	for code in [event.keycode, event.physical_keycode]:
		match code:
			KEY_2, KEY_KP_2:
				return 2
			KEY_3, KEY_KP_3:
				return 3
			KEY_4, KEY_KP_4:
				return 4
	return 0
