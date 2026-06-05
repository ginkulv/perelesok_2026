extends Node2D

const DustWipeSystemScript := preload("res://levels/level2/dust_wipe_system.gd")

const INTRO_START_PHRASE := "Знаешь, на самом деле здесь есть цвета"
const LEVEL_START_DELAY := 1.0
const INTRO_LINE_PAUSE := 2.8
const AFTER_DUST_END := "Для начала включим свет.."
const AFTER_LAMP := "Хочется чтобы было место, куда можно плюхнуться.."
const AFTER_SOFA := "И выпить чаю!"
const AFTER_TEA := "Вот так! Теперь здесь хорошо."

const DUST_CLEAN_RATIO := 0.4
const Z_CHARACTER_BODY := 3
const Z_KOVER := 5
const Z_DUST := 10
const Z_TRAPOCHKA := 15
const Z_DIALOGUE := 50

var dust_wipe: Node
var lamp_on: bool = false
var items_placed: bool = false
var sofa_placed: bool = false
var puzzle_completed: bool = false
var transition_started: bool = false
@onready var dust_sprite: Sprite2D = $KartinaPyle
@onready var trapochka_area: DraggableArea2D = $TrapochkaArea
@onready var lamp_off_sprite: Sprite2D = $RoomObjects/Item3/LampaOff
@onready var lamp_on_sprite: Sprite2D = $RoomObjects/Item3/LampaOn
@onready var chashka: Sprite2D = $RoomObjects/Item/Chashka
@onready var chainik: Sprite2D = $RoomObjects/Item/Chainik
@onready var divan: Sprite2D = $RoomObjects/Item2/Divan

func _ready() -> void:
	GameState.change_state(GameState.PLAYING)
	if CursorManager:
		CursorManager.ensure_playing_mode()
	
	AudioManager.play_music(load("res://assets/music/картина.mp3"))
	_setup_dust_wipe()
	MessageManager.dialogue_segment_finished.connect(_on_dialogue_segment_finished)
	_setup_character()
	_setup_interaction_areas()
	_setup_connections()
	_setup_initial_visibility()
	
	await get_tree().create_timer(LEVEL_START_DELAY).timeout
	await _wait_for_character_ready()
	await get_tree().process_frame
	_run_intro_dialogue()
	
	print("=== УРОВЕНЬ 2 ЗАГРУЖЕН ===")


func _setup_character() -> void:
	if not has_node("Character"):
		return
	$Character.z_index = Z_CHARACTER_BODY
	if $Character.has_node("CharacterBody2D"):
		$Character/CharacterBody2D.z_index = 0
	if $Character.has_node("PlayerMessageArea2D"):
		var bubble: CanvasItem = $Character.get_node("PlayerMessageArea2D")
		bubble.z_as_relative = false
		bubble.z_index = Z_DIALOGUE
		if bubble is Area2D:
			bubble.input_pickable = true
			bubble.monitorable = true


func _setup_interaction_areas() -> void:
	var kover := get_node_or_null("RoomObjects/Item/ClickableArea2D/Kover1") as Sprite2D
	if kover:
		kover.z_as_relative = false
		kover.z_index = Z_KOVER
	dust_sprite.z_index = Z_DUST
	trapochka_area.z_index = Z_TRAPOCHKA
	trapochka_area.input_pickable = true
	trapochka_area.monitorable = true
	trapochka_area.add_to_group("dust_wipe")
	
	for path in [
		"RoomObjects/Item/ClickableArea2D",
		"RoomObjects/Item2/ClickableArea2D2",
		"RoomObjects/Item3/ClickableArea2D3",
	]:
		var area := get_node_or_null(path) as Area2D
		if area:
			area.z_index = 12
			area.input_pickable = true
			area.monitorable = true


func _setup_initial_visibility() -> void:
	chashka.modulate.a = 0.0
	chashka.visible = true
	chainik.modulate.a = 0.0
	chainik.visible = true
	divan.modulate.a = 0.0
	divan.visible = true
	lamp_off_sprite.visible = true
	lamp_off_sprite.modulate.a = 1.0
	lamp_on_sprite.visible = false
	lamp_on_sprite.modulate.a = 1.0


func _setup_connections() -> void:
	trapochka_area.drag_started.connect(_on_trapochka_drag_started)
	trapochka_area.dragged.connect(_on_trapochka_dragged)
	trapochka_area.drag_ended.connect(_on_trapochka_drag_ended)
	var lamp_area = $RoomObjects/Item3/ClickableArea2D3
	if lamp_area:
		lamp_area.item_clicked.connect(_on_lamp_clicked)
	var table_area = $RoomObjects/Item/ClickableArea2D
	if table_area:
		table_area.item_clicked.connect(_on_table_clicked)
	var sofa_area = $RoomObjects/Item2/ClickableArea2D2
	if sofa_area:
		sofa_area.item_clicked.connect(_on_sofa_area_clicked)


func _align_dust_sprite_to_frame() -> void:
	var frame := get_node_or_null("RoomObjects/RamkaKartin") as Sprite2D
	if frame == null or frame.texture == null or dust_sprite.texture == null:
		return
	var frame_tex_size := frame.texture.get_size()
	var dust_tex_size := dust_sprite.texture.get_size()
	if dust_sprite.get_parent() != frame:
		dust_sprite.reparent(frame)
	dust_sprite.position = Vector2.ZERO
	dust_sprite.scale = Vector2(
		frame_tex_size.x / dust_tex_size.x * absf(frame.scale.x),
		frame_tex_size.y / dust_tex_size.y * absf(frame.scale.y)
	)


func _reparent_trapochka_to_dust() -> void:
	if trapochka_area.get_parent() == dust_sprite:
		return
	var global_pos := trapochka_area.global_position
	trapochka_area.reparent(dust_sprite)
	trapochka_area.position = dust_sprite.to_local(global_pos)


func _setup_dust_wipe() -> void:
	dust_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	dust_wipe = DustWipeSystemScript.new()
	dust_wipe.dust_sprite = dust_sprite
	dust_wipe.clean_ratio = DUST_CLEAN_RATIO
	add_child(dust_wipe)
	dust_wipe.setup()
	_align_dust_sprite_to_frame()
	_reparent_trapochka_to_dust()
	dust_wipe.dust_fully_cleaned.connect(_on_dust_cleaned)


func _on_trapochka_drag_started(_item: DraggableArea2D, _cursor_pos: Vector2) -> void:
	if dust_wipe:
		dust_wipe.reset_stroke()


func _on_trapochka_dragged(_item: DraggableArea2D, _old_pos: Vector2, _new_pos: Vector2) -> void:
	if puzzle_completed or dust_wipe == null:
		return
	dust_wipe.process_wipe_at_global(_item.global_position)


func _on_trapochka_drag_ended(_item: DraggableArea2D, _pos: Vector2) -> void:
	if dust_wipe:
		dust_wipe.reset_stroke()


func _wait_for_character_ready() -> void:
	for _i in range(90):
		if not get_tree().get_nodes_in_group("character").is_empty():
			await get_tree().process_frame
			return
		await get_tree().process_frame


func _sync_character_dialogue() -> void:
	var message := MessageManager.get_last_shown_message()
	if message == "" or not has_node("Character"):
		return
	if $Character.has_method("show_message"):
		$Character.show_message(message)


func _run_intro_dialogue() -> void:
	if not MessageManager.begin_dialogue_at_text(INTRO_START_PHRASE, true):
		push_warning("Level2: не найден интро-диалог")
		return
	_sync_character_dialogue()
	await _auto_finish_dialogue_block(INTRO_LINE_PAUSE)


func _auto_finish_dialogue_block(line_pause_sec: float) -> void:
	while MessageManager.is_dialogue_gated() and MessageManager.has_next():
		var next_line: String = MessageManager.dialogue_list[MessageManager.current_index]
		if next_line == "__END__":
			MessageManager.next_message()
			return
		MessageManager.next_message()
		_sync_character_dialogue()
		if MessageManager.current_index < MessageManager.dialogue_list.size():
			next_line = MessageManager.dialogue_list[MessageManager.current_index]
		else:
			next_line = ""
		var delay := line_pause_sec
		if next_line == "__END__":
			delay = line_pause_sec * 0.5
		await get_tree().create_timer(delay).timeout


func _on_dust_cleaned() -> void:
	if dust_wipe == null or dust_wipe.is_cleaned == false:
		return
	print("✅ Картина протёрта!")
	MessageManager.begin_dialogue_segment("Спасибо, спасибо, спасибо!", AFTER_DUST_END, true)
	_sync_character_dialogue()


func _on_lamp_clicked(_area: Area2D, _click_position: Vector2) -> void:
	if lamp_on or puzzle_completed:
		return
	if dust_wipe == null or not dust_wipe.is_cleaned:
		MessageManager.show_text("Сначала нужно протереть картину...")
		return
	lamp_on = true
	_fade_switch_lamps()
	print("💡 Лампа включена!")
	MessageManager.begin_dialogue_segment(AFTER_LAMP, AFTER_LAMP, true)
	_sync_character_dialogue()


func _fade_switch_lamps() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(lamp_off_sprite, "modulate:a", 0.0, 0.5)
	lamp_on_sprite.visible = true
	lamp_on_sprite.modulate.a = 0.0
	tween.tween_property(lamp_on_sprite, "modulate:a", 1.0, 0.5)
	await tween.finished
	lamp_off_sprite.visible = false
	lamp_off_sprite.modulate.a = 1.0


func _on_sofa_area_clicked(_area: Area2D, _click_position: Vector2) -> void:
	if sofa_placed or puzzle_completed:
		return
	if not lamp_on:
		MessageManager.show_text("Слишком темно, нужно включить лампу")
		return
	sofa_placed = true
	_fade_in_item(divan)
	print("🛋️ Диван поставлен на место!")
	MessageManager.begin_dialogue_segment(AFTER_SOFA, AFTER_SOFA, true)
	_sync_character_dialogue()


func _on_table_clicked(_area: Area2D, _click_position: Vector2) -> void:
	if items_placed or puzzle_completed:
		return
	if not sofa_placed:
		MessageManager.show_text("Сначала нужно поставить диван")
		return
	items_placed = true
	_fade_in_items([chashka, chainik])
	print("🍵 Чайник и чашка появились на столе!")
	MessageManager.begin_dialogue_segment(AFTER_TEA, AFTER_TEA, true)
	_sync_character_dialogue()


func _fade_in_items(items: Array) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	for item in items:
		item.modulate.a = 0.0
		item.visible = true
		tween.tween_property(item, "modulate:a", 1.0, 0.8)


func _fade_in_item(item: Node2D) -> void:
	item.modulate.a = 0.0
	item.visible = true
	var tween := create_tween()
	tween.tween_property(item, "modulate:a", 1.0, 0.8)


func _on_dialogue_segment_finished() -> void:
	if puzzle_completed or transition_started:
		return
	if dust_wipe and dust_wipe.is_cleaned and lamp_on and sofa_placed and items_placed:
		_on_puzzle_complete()


func _on_puzzle_complete() -> void:
	if transition_started:
		return
	puzzle_completed = true
	transition_started = true
	print("🎉 ГОЛОВОЛОМКА РЕШЕНА! Переход на следующий уровень...")
	if MessageManager.has_next() and MessageManager.dialogue_list[MessageManager.current_index] == "__END__":
		MessageManager.next_message()
	await get_tree().create_timer(3.0).timeout
	if LevelManager:
		await LevelManager.go_to_next_level()


func reset_level() -> void:
	lamp_on = false
	items_placed = false
	sofa_placed = false
	puzzle_completed = false
	transition_started = false
	_setup_initial_visibility()
	if dust_wipe:
		dust_wipe.reset()
