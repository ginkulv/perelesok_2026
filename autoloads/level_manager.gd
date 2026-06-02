extends Node

signal level_changed(level_from: String, level_to: String)

var num_of_levels: int = 5
var levels: Array[String] = []
var index: int = 0
var camera: Camera2D
var current_level: Node
var scale: float = 0.1
var anim_duration: float = 1.0

var initial_zoom: float = 1 / scale ** 3

func _ready() -> void:
    for i in range(1, num_of_levels + 1):
        levels.append("Level" + str(i))

    camera = Camera2D.new()
    camera.zoom = Vector2(initial_zoom, initial_zoom)  # Start zoomed in
    camera.position = get_viewport().size / (2 * initial_zoom)
    add_child(camera)
    camera.make_current()


func go_to_next_level() -> void:
    index += 1

    var target_zoom = camera.zoom.x * scale
    var tween = camera.create_tween()
    tween.tween_property(camera, "zoom", Vector2(target_zoom, target_zoom), anim_duration)
    tween.parallel().tween_property(camera, "position", camera.position / scale, anim_duration)

    level_changed.emit(levels[index - 1], levels[index])


func go_to_prev_level() -> void:
    index -= 1

    var target_zoom = camera.zoom.x / scale
    var tween = camera.create_tween()
    tween.tween_property(camera, "zoom", Vector2(target_zoom, target_zoom), anim_duration)
    tween.parallel().tween_property(camera, "position", camera.position * scale, anim_duration)
    await tween.finished

    level_changed.emit(levels[index], levels[index + 1])
