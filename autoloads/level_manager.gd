extends Node

signal level_changed(level_from: String, level_to: String)

var num_of_levels: int = 5
var level_paths: Array[String] = []
var level_names: Array[String] = []
var index: int = 0
var current_level: Node

func _ready() -> void:
    for i in range(1, num_of_levels + 1):
        level_paths.append("res://levels/level" + str(i) + "/level" + str(i) + ".tscn")
        level_names.append("Level" + str(i))


func go_to_next_level() -> void:
    # Проверяем, есть ли следующий уровень
    if index + 1 >= level_paths.size():
        print("🏆 ИГРА ПРОЙДЕНА! Все уровни завершены.")
        return
    
    # Удаляем текущий уровень (если он существует)
    if current_level:
        current_level.queue_free()
        await current_level.tree_exited
    
    # Переходим к следующему уровню
    index += 1
    
    # Загружаем и добавляем новый уровень
    var level_scene = load(level_paths[index])
    current_level = level_scene.instantiate()
    get_tree().root.add_child(current_level)
    
    # Отправляем сигнал о смене уровня
    level_changed.emit(level_paths[index - 1], level_paths[index])
    
    print("✅ Переход на уровень: ", level_paths[index])


func go_to_prev_level() -> void:
    get_tree().root.get_node(level_names[index]).queue_free()
    await get_tree().process_frame

    index -= 1

    var level_scene = load(level_paths[index])
    current_level = level_scene.instantiate()
    get_tree().root.add_child(current_level)

    level_changed.emit(level_paths[index], level_paths[index + 1])
