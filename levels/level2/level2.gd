extends Node2D
# Переменные для механики пыли
var mask_image: Image
var mask_texture: ImageTexture
var shader_material = null
var texture_pos: Vector2
var brush_size = 10
var color_value: float = 0.0

# Переменные для головоломки
var dust_cleaned: bool = false
var lamp_on: bool = false
var items_placed: bool = false
var sofa_placed: bool = false
var puzzle_completed: bool = false
var transition_started: bool = false

@onready var dust_sprite = $KartinaPyle
@onready var lamp_off_sprite = $RoomObjects/Item3/LampaOff
@onready var lamp_on_sprite = $RoomObjects/Item3/LampaOn
@onready var chashka = $RoomObjects/Item/Chashka
@onready var chainik = $RoomObjects/Item/Chainik
@onready var divan = $RoomObjects/Item2/Divan

func _ready() -> void:
    # Настройка механики пыли
    AudioManager.play_music(load("res://assets/music/картина.mp3"))
    setup_mask_system()
    MessageManager.start_from_index(12)
    # Подключаем сигналы
    _setup_connections()
    
    # Изначальное состояние предметов (прозрачные для плавного появления)
    chashka.modulate.a = 0.0
    chashka.visible = true
    chainik.modulate.a = 0.0
    chainik.visible = true
    divan.modulate.a = 0.0
    divan.visible = true
    
    # Лампа: выключенная видна, включенная скрыта
    lamp_off_sprite.visible = true
    lamp_on_sprite.visible = false
    
    # Подключаем сигнал от тряпки
    $TrapochkaArea.dragged.connect(_on_trapochka_dragged)
    
    print("=== УРОВЕНЬ 2 ЗАГРУЖЕН ===")
    print("Задача: 1) Протереть картину 2) Включить лампу 3) Поставить чайник и чашку 4) Поставить диван")

func _setup_connections() -> void:
    # Подключаем клик по лампе
    var lamp_area = $RoomObjects/Item3/ClickableArea2D3
    if lamp_area:
        lamp_area.item_clicked.connect(_on_lamp_clicked)
    
    # Подключаем клик по столу (для появления чайника и чашки)
    var table_area = $RoomObjects/Item/ClickableArea2D
    if table_area:
        table_area.item_clicked.connect(_on_table_clicked)
    
    # Подключаем клик по области дивана
    var sofa_area = $RoomObjects/Item2/ClickableArea2D2
    if sofa_area:
        sofa_area.item_clicked.connect(_on_sofa_area_clicked)
    
    # Подключаем MessageManager
    if MessageManager:
        MessageManager.message_shown.connect(_on_message_shown)

# ============ МЕХАНИКА ПЫЛИ ============
func setup_mask_system() -> void:
    var mask_size = Vector2($KartinaPyle.texture.get_size().x, $KartinaPyle.texture.get_size().y)
    mask_image = Image.create(mask_size.x, mask_size.y, false, Image.FORMAT_RGBA8)
    mask_image.fill(Color.BLACK)
    
    print("mask_image.size: ", mask_image.get_width(), " ", mask_image.get_height())
    
    mask_texture = ImageTexture.create_from_image(mask_image)
    $KartinaPyle.material = create_shader_material()

func create_shader_material() -> ShaderMaterial:
    var shader = preload("res://levels/level2/dust.gdshader")
    shader_material = ShaderMaterial.new()
    shader_material.shader = shader
    shader_material.set_shader_parameter("mask_texture", mask_texture)
    return shader_material

func erase_dust(global_pos: Vector2) -> void:
    if color_value >= 1:
        _on_dust_cleaned()
        return
    
    color_value += 0.01
    mask_image.fill(Color.from_hsv(color_value, color_value, color_value))
    mask_texture.update(mask_image)

func _on_trapochka_dragged(_trapochka: DraggableArea2D, old_pos: Vector2, new_pos: Vector2) -> void:
    if dust_cleaned or puzzle_completed:
        return
    
    if old_pos.distance_to(new_pos) > 0.5 and $KartinaPyle.get_rect().has_point(new_pos):
        erase_dust(new_pos)

func _on_dust_cleaned() -> void:
    if dust_cleaned:
        return
    
    dust_cleaned = true
    print("✅ Картина протёрта!")
    
    if MessageManager:
        MessageManager.show_event("dust_cleaned")
    
    _check_puzzle_complete()

# ============ ЛОГИКА ГОЛОВОЛОМКИ ============
func _on_lamp_clicked(_area: Area2D, _click_position: Vector2) -> void:
    if lamp_on or puzzle_completed:
        return
    
    if not dust_cleaned:
        if MessageManager:
            MessageManager.show_text("Сначала нужно протереть картину...")
        return
    
    lamp_on = true
    
    # Плавное переключение лампы
    _fade_switch_lamps()
    
    print("💡 Лампа включена!")
    
    if MessageManager:
        MessageManager.show_event("lamp_on")
    
    _check_puzzle_complete()

func _fade_switch_lamps() -> void:
    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(lamp_off_sprite, "modulate:a", 0.0, 0.5)
    
    lamp_on_sprite.visible = true
    lamp_on_sprite.modulate.a = 0.0
    tween.tween_property(lamp_on_sprite, "modulate:a", 1.0, 0.5)
    
    await tween.finished
    lamp_off_sprite.visible = false
    lamp_off_sprite.modulate.a = 1.0

func _on_table_clicked(_area: Area2D, _click_position: Vector2) -> void:
    if items_placed or puzzle_completed:
        return
    
    if not lamp_on:
        if MessageManager:
            MessageManager.show_text("Слишком темно, нужно включить лампу")
        return
    
    items_placed = true
    
    # Плавное появление чайника и чашки
    _fade_in_items([chashka, chainik])
    
    print("🍵 Чайник и чашка появились на столе!")
    
    if MessageManager:
        MessageManager.show_event("items_placed")
    
    _check_puzzle_complete()

func _on_sofa_area_clicked(_area: Area2D, _click_position: Vector2) -> void:
    if sofa_placed or puzzle_completed:
        return
    
    if not items_placed:
        if MessageManager:
            MessageManager.show_text("Сначала нужно расставить чайник и чашку на столе")
        return
    
    sofa_placed = true
    
    # Плавное появление дивана
    _fade_in_item(divan)
    
    print("🛋️ Диван поставлен на место!")
    
    if MessageManager:
        MessageManager.show_event("sofa_placed")
    
    _check_puzzle_complete()

func _fade_in_items(items: Array) -> void:
    var tween = create_tween()
    tween.set_parallel(true)
    
    for item in items:
        item.modulate.a = 0.0
        item.visible = true
        tween.tween_property(item, "modulate:a", 1.0, 0.8)

func _fade_in_item(item: Node2D) -> void:
    item.modulate.a = 0.0
    item.visible = true
    var tween = create_tween()
    tween.tween_property(item, "modulate:a", 1.0, 0.8)

func _check_puzzle_complete() -> void:
    if puzzle_completed or transition_started:
        return
    
    if dust_cleaned and lamp_on and items_placed and sofa_placed:
        puzzle_completed = true
        _on_puzzle_complete()

func _on_puzzle_complete() -> void:
    print("🎉 ГОЛОВОЛОМКА РЕШЕНА! Переход на следующий уровень...")
    
    transition_started = true
    
    if MessageManager:
        MessageManager.show_event("puzzle_complete")
        await get_tree().create_timer(2.5).timeout
    
    if LevelManager:
        LevelManager.go_to_next_level()
    else:
        print("❌ LevelManager не найден!")

func _on_message_shown(message: String) -> void:
    pass  # Character сам обрабатывает сообщения

func reset_level() -> void:
    dust_cleaned = false
    lamp_on = false
    items_placed = false
    sofa_placed = false
    puzzle_completed = false
    transition_started = false
    color_value = 0.0
    
    chashka.modulate.a = 0.0
    chainik.modulate.a = 0.0
    divan.modulate.a = 0.0
    
    lamp_off_sprite.visible = true
    lamp_off_sprite.modulate.a = 1.0
    lamp_on_sprite.visible = false
    lamp_on_sprite.modulate.a = 1.0
    
    # Сброс маски пыли
    setup_mask_system()
    
    print("🔄 Уровень сброшен")
