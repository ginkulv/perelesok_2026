extends Node2D

@onready var message_node: ClickableArea2D = $PlayerMessageArea2D
@onready var rich_text_label: RichTextLabel = $PlayerMessageArea2D/RichTextLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_showing: bool = false

func _ready() -> void:
    message_node.visible = false
    message_node.item_clicked.connect(_on_message_area_clicked)
    
    # Подключаемся к глобальному MessageManager
    if MessageManager:
        MessageManager.message_shown.connect(_on_message_received)
        print("✅ Character готов к диалогам")
    else:
        print("❌ MessageManager не найден!")

func show_message(message: String) -> void:
    if message.is_empty():
        hide_message()
        return
    
    rich_text_label.text = message
    message_node.visible = true
    is_showing = true
    
    if animation_player.has_animation("fade_in"):
        animation_player.play("fade_in")
    else:
        print("⚠️ Анимация 'fade_in' не найдена")
        message_node.modulate.a = 1.0

func hide_message() -> void:
    if not is_showing:
        return
    
    is_showing = false
    
    if animation_player.has_animation("fade_out"):
        animation_player.play("fade_out")
        await animation_player.animation_finished
        message_node.visible = false
    else:
        message_node.visible = false
        print("⚠️ Анимация 'fade_out' не найдена")

# Обработчик сообщений от MessageManager
func _on_message_received(message: String) -> void:
    if message.is_empty() or message == "__END__":
        hide_message()
    else:
        show_message(message)

# Обработчик клика по сообщению (ускорение диалога)
func _on_message_area_clicked(_item: ClickableArea2D, _pos: Vector2) -> void:
    print("👆 Клик по сообщению - ускоряем диалог")
    hide_message()
    
    # Показываем следующее сообщение
    if MessageManager and MessageManager.has_next():
        await get_tree().create_timer(0.1).timeout
        MessageManager.next_message()

# Метод для вызова из анимации (если нужно)
func talk() -> void:
    print("💬 talk() вызван")
    if MessageManager:
        if MessageManager.has_next():
            MessageManager.next_message()
        else:
            print("💬 Диалогов больше нет")
    else:
        print("⚠️ MessageManager не найден")

# Дополнительный метод для экстренного скрытия
func force_hide_message() -> void:
    message_node.visible = false
    is_showing = false
    if animation_player.is_playing():
        animation_player.stop()
