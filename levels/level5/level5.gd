extends Node2D

func _ready() -> void:
    CursorManager.invert_x = true

func _exit_tree() -> void:
    CursorManager.invert_x = false
