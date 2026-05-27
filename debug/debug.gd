extends Node

var num_of_levels: int = 5
var levels: Array[String] = []
var index: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    for i in range(1, num_of_levels + 1):
        levels.append("level" + str(i))

    print(levels)
    index = 0
    $Panel/Label.text = levels[index]
    $Panel/PrevButton.visible = false

func _on_next_button_up() -> void:
    index += 1
    if index == num_of_levels - 1:
        $Panel/NextButton.visible = false
    else:
        $Panel/NextButton.visible = true
    $Panel/PrevButton.visible = true
    $Panel/Label.text = levels[index]
    get_tree().change_scene_to_file("res://levels/" + levels[index] + "/" + levels[index] + ".tscn")


func _on_prev_button_up() -> void:
    index -= 1
    if index == 0:
        $Panel/PrevButton.visible = false
    else:
        $Panel/PrevButton.visible = true
    $Panel/NextButton.visible = true
    $Panel/Label.text = levels[index]
    get_tree().change_scene_to_file("res://levels/" + levels[index] + "/" + levels[index] + ".tscn")
