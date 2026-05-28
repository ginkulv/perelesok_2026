extends Node2D

var mouse_sensitivity: float = 0.1

func _ready() -> void:
    CursorManager.invert_x = true

func _exit_tree() -> void:
    CursorManager.invert_x = false
