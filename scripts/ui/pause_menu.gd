extends Node2D

@onready var settings_scene = preload("res://scenes/ui/settings_menu.tscn")

func _on_resume_button_button_up() -> void:
    GameState.change_state(GameState.PLAYING)
    queue_free()

func _on_settings_button_button_up() -> void:
    var settings = settings_scene.instantiate()
    add_child(settings)
    await settings.settings_closed

func _on_exit_button_up() -> void:
    get_tree().quit()
