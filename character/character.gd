extends Node2D

@onready var message_node: ClickableArea2D = $PlayerMessageArea2D
@onready var rich_text_label: RichTextLabel = $PlayerMessageArea2D/RichTextLabel
@onready var cloud_sprite: Sprite2D = $PlayerMessageArea2D/Placeholder
@onready var _body_sprite: AnimatedSprite2D = $CharacterBody2D/Placeholder

var is_showing: bool = false
var _dialogue_text_readable: bool = true
var _label_scale_tween: Tween


func _enter_tree() -> void:
	add_to_group("character")


func _ready() -> void:
	message_node.visible = false
	message_node.scale = Vector2.ONE
	message_node.add_to_group("dialogue_click")
	$CharacterBody2D/Placeholder.play("default")
	message_node.item_clicked.connect(_on_message_area_clicked)

	if MessageManager:
		if not MessageManager.message_shown.is_connected(_on_message_received):
			MessageManager.message_shown.connect(_on_message_received)
		var replay := MessageManager.get_last_shown_message()
		if replay != "" and MessageManager.is_dialogue_gated():
			show_message(replay)
		print("✅ Character готов к диалогам")
	else:
		print("❌ MessageManager не найден!")


func set_dialogue_text_readable(readable: bool, tween_duration: float = 0.0) -> void:
	_dialogue_text_readable = readable
	_apply_label_scale(tween_duration)


func show_message(message: String) -> void:
	if message.is_empty():
		hide_message()
		return

	message_node.scale = Vector2.ONE
	rich_text_label.text = message
	rich_text_label.visible = true
	rich_text_label.modulate.a = 1.0
	if cloud_sprite:
		cloud_sprite.visible = true
		cloud_sprite.modulate.a = 1.0
	message_node.visible = true
	message_node.modulate.a = 1.0
	is_showing = true


func _target_label_scale_x() -> float:
	if scale.x < 0.0 and _dialogue_text_readable:
		return -1.0
	return 1.0


func _apply_label_scale(duration: float) -> void:
	if _label_scale_tween and _label_scale_tween.is_valid():
		_label_scale_tween.kill()

	var target := _target_label_scale_x()
	if duration <= 0.0:
		rich_text_label.scale.x = target
		rich_text_label.scale.y = 1.0
		return

	_label_scale_tween = create_tween()
	_label_scale_tween.tween_property(rich_text_label, "scale:x", target, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func hide_message() -> void:
	if not is_showing:
		return
	is_showing = false
	message_node.visible = false


func _on_message_received(message: String) -> void:
	if message.is_empty() or message == "__END__":
		hide_message()
	else:
		show_message(message)


func _on_message_area_clicked(_item: ClickableArea2D, _pos: Vector2) -> void:
	if not MessageManager:
		return
	if MessageManager.has_next():
		MessageManager.next_message()
	else:
		hide_message()


func talk() -> void:
	if MessageManager and MessageManager.has_next():
		MessageManager.next_message()


func force_hide_message() -> void:
	message_node.visible = false
	is_showing = false


func play_goodbye(duration_sec: float = 3.0) -> void:
	if _body_sprite.sprite_frames == null or not _body_sprite.sprite_frames.has_animation("goodbye"):
		push_warning("Character: анимация goodbye не найдена")
		await get_tree().create_timer(duration_sec).timeout
		return
	_body_sprite.play("goodbye")
	await get_tree().create_timer(duration_sec).timeout
	_body_sprite.stop()
