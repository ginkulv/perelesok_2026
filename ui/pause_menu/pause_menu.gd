extends CanvasLayer

@onready var settings_scene = preload("res://ui/settings_menu/settings_menu.tscn")

var invert_x: bool = false

func _ready() -> void:
    invert_x = CursorManager.invert_x
    CursorManager.invert_x = false

func _on_resume_button_button_up() -> void:
    close()

func _on_settings_button_button_up() -> void:
    var settings = settings_scene.instantiate()
    add_child(settings)
    await settings.settings_closed

func _on_exit_button_up() -> void:
    get_tree().quit()

func open() -> void:
    invert_x = CursorManager.invert_x
    CursorManager.invert_x = false
    get_tree().paused = true
    show()

func close() -> void:
    GameState.change_state(GameState.PLAYING)
    CursorManager.invert_x = invert_x
    hide()
