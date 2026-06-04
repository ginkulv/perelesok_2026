extends Node2D
@export var last_message_text: String


func _ready() -> void:
    LevelManager.level_changed.connect(_on_level_changed)

func _on_level_changed(level_from: String, level_to: String) -> void:
    set_transparent_window()
    create_text_file_on_desktop(last_message_text)

func set_transparent_window()  -> void:
    get_viewport().transparent_bg = true
    var game_window = get_viewport().get_window()
    game_window.transparent = true


func create_text_file_on_desktop(text :String) -> void:
    var desktop_path = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
    var file_path = desktop_path + "/message.txt"
    
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    if file:
        file.store_string(last_message_text)
        file.close()
        print("Файл создан: ", file_path)
    else:
        print("Не удалось создать файл")
