extends Node2D

@onready var expected_pos = {
    "JigsawFragment2": Vector2(766, 212),
    "JigsawFragment3": Vector2(306, 198),
    "JigsawFragment4": Vector2(1219, 832),
    "JigsawFragment5": Vector2(1509, 383),
    "JigsawFragment6": Vector2(790, 547),
    "JigsawFragment7": Vector2(1390, 547),
    "JigsawFragment8": Vector2(239, 668),
    "JigsawFragment9": Vector2(496, 404),
}

var pieces_placed = 0
var total_pieces = 8
var puzzle_completed = false

func _ready() -> void:
    if AudioManager:
        AudioManager.play_music(load("res://assets/music/фото.mp3"))
    
    _setup_anchor_piece()
    
    $JigsawFragment2.drag_ended.connect(_on_jigsaw_placed)
    $JigsawFragment3.drag_ended.connect(_on_jigsaw_placed)
    $JigsawFragment4.drag_ended.connect(_on_jigsaw_placed)
    $JigsawFragment5.drag_ended.connect(_on_jigsaw_placed)
    $JigsawFragment7.drag_ended.connect(_on_jigsaw_placed)
    $JigsawFragment8.drag_ended.connect(_on_jigsaw_placed)
    $JigsawFragment9.drag_ended.connect(_on_jigsaw_placed)
    

    MessageManager.message_shown.connect(_on_message_shown)
    

    LevelManager.level_changed.connect(_on_level_changed)
    
    _setup_sound_player()
    
    print("=== УРОВЕНЬ 1 ЗАГРУЖЕН ===")

func _setup_anchor_piece() -> void:
    var anchor = $JigsawFragment6
    anchor.position = expected_pos["JigsawFragment6"]
    anchor.can_drag = false
    anchor.input_pickable = false
    
    var sprite = anchor.get_node_or_null("JigsawFragmentSprite")
    if sprite:
        sprite.modulate = Color(0.8, 0.8, 0.8, 1)
    
    pieces_placed += 1

func _setup_sound_player() -> void:
    if not has_node("PlaceSound"):
        var sound_player = AudioStreamPlayer2D.new()
        sound_player.name = "PlaceSound"
        add_child(sound_player)
        sound_player.stream = load("res://assets/sfx/берем кусочек фотографии.mp3")

func _play_place_sound() -> void:
    if has_node("PlaceSound") and $PlaceSound.stream:
        $PlaceSound.play()

func _on_jigsaw_placed(item: Area2D, pos: Vector2) -> void:
    if puzzle_completed:
        return
    
    var item_name = item.name
    
    if item_name == "JigsawFragment6":
        return
    
    if not expected_pos.has(item_name):
        return
    
    var target_pos = expected_pos[item_name]
    var distance = pos.distance_to(target_pos)
    
    if distance < 150:
        item.can_drag = false
        item.input_pickable = false
        item.position = target_pos
        
        if item.drag_ended.is_connected(_on_jigsaw_placed):
            item.drag_ended.disconnect(_on_jigsaw_placed)
        
        _play_place_sound()
        pieces_placed += 1
        
        print("✅ Собрано: ", pieces_placed, "/", total_pieces)
        
        # 👇 КРАСИВЫЕ ВЫЗОВЫ С СОБЫТИЯМИ
        if pieces_placed == 1:
            MessageManager.show_event("first_piece")
        elif pieces_placed == total_pieces / 2:
            MessageManager.show_event("half_piece")
        elif pieces_placed == total_pieces - 1:
            MessageManager.show_event("last_piece")
        
        if pieces_placed >= total_pieces:
            _on_puzzle_complete()
    else:
        print("❌ Слишком далеко")

func _on_puzzle_complete() -> void:
    if puzzle_completed:
        return
    
    puzzle_completed = true
    
    _fade_out_all_pieces()
    
    if has_node("PhotoBackground"):
        $PhotoBackground.visible = true
        var tween = create_tween()
        tween.tween_property($PhotoBackground, "modulate:a", 1.0, 0.8)
    
    MessageManager.show_event("puzzle_complete")
    
    await get_tree().create_timer(3.5).timeout
    
    if LevelManager:
        LevelManager.go_to_next_level()

func _fade_out_all_pieces() -> void:
    var fragments = [
        $JigsawFragment2, $JigsawFragment3, $JigsawFragment4,
        $JigsawFragment5, $JigsawFragment6, $JigsawFragment7,
        $JigsawFragment8, $JigsawFragment9
    ]
    
    for fragment in fragments:
        if fragment:
            _fade_out_single_piece(fragment)

func _on_level_changed(level_from: String, level_to: String) -> void:
    print("Уровень изменён: ", level_from, " -> ", level_to)
    if level_from == self.name and MessageManager:
        if MessageManager.message_shown.is_connected(_on_message_shown):
            MessageManager.message_shown.disconnect(_on_message_shown)

func _fade_out_single_piece(item: Area2D) -> void:
    var sprite = item.get_node_or_null("JigsawFragmentSprite")
    if not sprite:
        sprite = item.get_node_or_null("Sprite2D")
    
    if sprite:
        var tween = create_tween()
        tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
        await tween.finished
        sprite.visible = false
    
    item.process_mode = PROCESS_MODE_DISABLED

func _on_message_shown(message: String) -> void:
    if message == "":
        if $Character.has_method("hide_message"):
            $Character.hide_message()
    else:
        if $Character.has_method("show_message"):
            $Character.show_message(message)
