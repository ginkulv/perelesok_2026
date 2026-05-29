extends Node

@onready var level2 = preload("res://levels/level2/level2.tscn")

func _ready() -> void:
    var current_size = DisplayServer.window_get_size()
    var new_size = Vector2i(current_size.x * 0.1, current_size.y * 0.1)
    DisplayServer.window_set_size(new_size)



func _process(delta: float) -> void:
    pass
