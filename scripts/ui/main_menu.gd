extends Node2D

@onready var settings_scene = preload("res://scenes/ui/settings_menu.tscn")

func _ready():
    GameState.change_state(GameState.PLAYING)

func _on_exit_button_button_up():
    get_tree().quit()

func _on_settings_button_button_up():
    var settings = settings_scene.instantiate()
    add_child(settings)

func _on_play_button_button_up() -> void:
    queue_free()
