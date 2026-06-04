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

func _ready() -> void:
	MessageManager.message_shown.connect(_on_message_shown)

	$JigsawFragment2.drag_ended.connect(_on_jigsaw_placed)
	$JigsawFragment3.drag_ended.connect(_on_jigsaw_placed)
	$JigsawFragment4.drag_ended.connect(_on_jigsaw_placed)
	$JigsawFragment5.drag_ended.connect(_on_jigsaw_placed)
	$JigsawFragment6.drag_ended.connect(_on_jigsaw_placed)
	$JigsawFragment7.drag_ended.connect(_on_jigsaw_placed)
	$JigsawFragment8.drag_ended.connect(_on_jigsaw_placed)
	$JigsawFragment9.drag_ended.connect(_on_jigsaw_placed)
	LevelManager.level_changed.connect(_on_level_changed)


func _on_level_changed(level_from: String, level_to: String) -> void:
	if level_to == self.name:
		$JigsawFragment.drag_ended.connect(_on_jigsaw_placed)
	elif level_from == self.name:
		MessageManager.message_shown.disconnect(_on_message_shown)


func _on_jigsaw_placed(item: DraggableArea2D, pos: Vector2) -> void:
	var item_name = item.name
	if pos.distance_to(expected_pos[item_name]) < 100:
		item.position = expected_pos[item_name]
		item.can_drag = false
		MessageManager.emit_message_by_id("1")

func _on_message_shown(message) -> void:
	$Character.show_message(message)
