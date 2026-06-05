extends CanvasLayer

@onready var settings_scene = preload("res://ui/settings_menu/settings_menu.tscn")

func _ready():
	GameState.change_state(GameState.MAIN_MENU)
	AudioManager.play_music(load("res://assets/music/музыка для меню.mp3"))


func _on_exit_button_button_up():
	get_tree().quit()

func _on_settings_button_button_up():
	var settings = settings_scene.instantiate()
	add_child(settings)

func _on_play_button_button_up() -> void:
	if LevelManager:
		LevelManager.start_game_at_level(1)
