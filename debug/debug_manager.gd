extends Node

func _ready() -> void:
    var debug_scene = preload("res://debug/debug.tscn")
    debug_scene = debug_scene.instantiate()
    add_child(debug_scene)
