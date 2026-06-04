extends Node

@onready var expected_pos = {
	$JigsawFragment1.name: Vector2(0, 0),
	$JigsawFragment2.name: Vector2(500, 300),
}

func _ready() -> void:
	MessageManager.message_shown.connect(_on_message_shown)

	$JigsawFragment1.drag_ended.connect(_on_jigsaw_placed)
	$JigsawFragment2.drag_ended.connect(_on_jigsaw_placed)
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
