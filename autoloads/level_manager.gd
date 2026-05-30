extends Node

var num_of_levels: int = 5
var levels: Array[String] = []
var index: int = 0
var camera: Camera2D
var current_level: Node
var scale: float = 0.1
var anim_duration: float = 3.0

var initial_zoom: float = 1 / scale ** 3

func _ready() -> void:
    for i in range(1, num_of_levels + 1):
        levels.append("res://levels/level" + str(i) + "/level" + str(i) + ".tscn")

    camera = Camera2D.new()
    camera.zoom = Vector2(initial_zoom, initial_zoom)  # Start zoomed in
    camera.position = get_viewport().size / (2 * initial_zoom)
    add_child(camera)
    camera.make_current()


func go_to_next_level() -> void:
    # print(levels[index])
    # current_level = get_tree().root.get_node("Level1")
    # index += 1
    # print(current_level)

    # var next_level = load(levels[index]).instantiate()
    # current_level.get_parent().remove_child(current_level)
    # next_level.add_child(current_level)

    # add_child(next_level)

    # current_level.position = Vector2(0, 0)
    # current_level.scale = Vector2(scale, scale)

    var target_zoom = camera.zoom.x * scale
    var tween = camera.create_tween()
    tween.tween_property(camera, "zoom", Vector2(target_zoom, target_zoom), anim_duration)
    tween.parallel().tween_property(camera, "position", camera.position / scale, anim_duration)
    await tween.finished


func go_to_prev_level() -> void:
    var target_zoom = camera.zoom.x / scale
    var tween = camera.create_tween()
    tween.tween_property(camera, "zoom", Vector2(target_zoom, target_zoom), anim_duration)
    tween.parallel().tween_property(camera, "position", camera.position * scale, anim_duration)
    await tween.finished
