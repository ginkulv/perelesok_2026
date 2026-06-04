extends Node

var num_of_levels: int = 5
var levels: Array[String] = []
var index: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    for i in range(1, num_of_levels + 1):
        levels.append("level" + str(i))

    index = 0
    $CanvasLayer/Panel/Label.text = levels[index]
    $CanvasLayer/Panel/PrevButton.visible = false

func _on_next_button_up() -> void:
    index += 1
    if index == num_of_levels - 1:
        $CanvasLayer/Panel/NextButton.visible = false
    else:
        $CanvasLayer/Panel/NextButton.visible = true
    $CanvasLayer/Panel/PrevButton.visible = true
    $CanvasLayer/Panel/Label.text = levels[index]
    LevelManager.go_to_next_level()


func _on_prev_button_up() -> void:
    index -= 1
    if index == 0:
        $CanvasLayer/Panel/PrevButton.visible = false
    else:
        $CanvasLayer/Panel/PrevButton.visible = true
    $CanvasLayer/Panel/NextButton.visible = true
    $CanvasLayer/Panel/Label.text = levels[index]
    LevelManager.go_to_prev_level()
