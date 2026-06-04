extends Node

@onready var expected_pos = {
    $JigsawFragment2.name: Vector2(766, 212),
    $JigsawFragment3.name: Vector2(306, 198),
    $JigsawFragment4.name: Vector2(1219,832),
    $JigsawFragment5.name: Vector2(1509, 383),
    $JigsawFragment6.name: Vector2(790, 547),
    $JigsawFragment7.name: Vector2(1390, 547),
    $JigsawFragment8.name: Vector2(239, 668),
    $JigsawFragment9.name: Vector2(496, 404),
}

@export var pull_distance: float = 100.0

func _ready() -> void:
    $JigsawFragment2.drag_ended.connect(_on_jigsaw_placed)
    $JigsawFragment3.drag_ended.connect(_on_jigsaw_placed)
    $JigsawFragment4.drag_ended.connect(_on_jigsaw_placed)
    $JigsawFragment5.drag_ended.connect(_on_jigsaw_placed)
    $JigsawFragment6.drag_ended.connect(_on_jigsaw_placed)
    $JigsawFragment7.drag_ended.connect(_on_jigsaw_placed)
    $JigsawFragment8.drag_ended.connect(_on_jigsaw_placed)
    $JigsawFragment9.drag_ended.connect(_on_jigsaw_placed)

func _on_jigsaw_placed(item: DraggableArea2D, pos: Vector2) -> void:
    var item_name = item.name
    if pos.distance_to(expected_pos[item_name]) < pull_distance:
        item.position = expected_pos[item_name]
        item.can_drag = false
        MessageManager.emit_message_by_id("1")
