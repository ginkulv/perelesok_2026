extends Node

@onready var expected_pos = {
    $JigsawFragment.name: Vector2(500, 500),
    $JigsawFragment2.name: Vector2(500, 300),
}

func _ready() -> void:
    $JigsawFragment.drag_ended.connect(_on_jigsaw_placed)
    LevelManager.level_changed.connect(_on_level_changed)

func _on_level_changed(level_from: String, level_to: String) -> void:
    if level_to == self.name:
        $JigsawFragment.drag_ended.connect(_on_jigsaw_placed)
    elif level_from == self.name:
        pass


func _on_jigsaw_placed(item: DraggableArea2D, pos: Vector2) -> void:
    var item_name = item.name
    if pos.distance_to(expected_pos[item_name]) < 100:
        item.position = expected_pos[item_name]
        item.can_drag = false
