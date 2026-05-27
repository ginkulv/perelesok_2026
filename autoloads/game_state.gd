extends Node

@onready var pause_menu_scene = preload("res://ui/pause_menu/pause_menu.tscn")

enum {
    MAIN_MENU,
    PAUSE_MENU,
    PLAYING,
    CUTSCENE,
}

signal state_changed(from_state: int, to_state: int)

var current_state: int = MAIN_MENU
var pause_menu: Node2D

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    change_state(MAIN_MENU)

func change_state(new_state: int) -> void:
    state_changed.emit(current_state, new_state)
    current_state = new_state

    match current_state:
        PLAYING,CUTSCENE:
            get_tree().paused = false
        PAUSE_MENU, MAIN_MENU:
            get_tree().paused = true

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_pause_menu"):
        match current_state:
            PLAYING:
                pause_menu = pause_menu_scene.instantiate()
                add_child(pause_menu)
                change_state(PAUSE_MENU)
            PAUSE_MENU:
                pause_menu.queue_free()
                change_state(PLAYING)
