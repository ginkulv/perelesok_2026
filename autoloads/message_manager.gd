extends Node

signal message_shown(message: String)

#каждая новая строка это новое облвчко __END__ заканчивает монолог по длине не больше чем в примере строчки
var dialogue_script: String = """
Пу-пу-пу…
Что? Кто здесь???
Ты что, меня слышишь? 
Ну и дела!
Я здесь, кажется, уже давно, и все время был один
Хотя насчет "времени" не уверен 
Ладно, это ничего. 
Поможешь собрать кусочки?
Видишь, они все разлетелись, выглядит ужасно
Стоит ли вообще пытаться чинить настолько сломанное?
__END__
НАчало текста следующего разговора
Конец
__END__
"""

#каждая новая строка в кавычках и через запятую это следующая записка
var note: Array = [
"Текст записки первый",
"Текст записки второй"
]

#это не обязательно 
var event_messages: Dictionary = {
    "first_piece": "Один кусочек на месте...",
    "half_piece": "Половина готова!",
    "last_piece": "Остался последний...",
    "puzzle_complete": "Получилось! Все выглядит совсем как раньше",
    "piece_placed": "Кусочек встал на место!",
    "full_complete": "Ты собрал все!",
    "dust_cleaned": "Картина теперь чистая!",
    "lamp_on": "В комнате стало светлее...",
    "items_placed": "Чайник и чашка на месте, теперь можно поставить диван",
    "sofa_placed": "Диван на месте! Комната обустроена.",
    "puzzle2_complete": "Отлично! Комната полностью обустроена. Пора идти дальше!",
}


var dialogue_list: Array[String] = []
var current_index: int = 0

func _ready() -> void:
    _parse_dialogue_script()

func _parse_dialogue_script() -> void:
    var raw_lines = dialogue_script.split("\n", false)
    
    for line in raw_lines:
        var trimmed = line.strip_edges()
        if trimmed != "":  # Пропускаем пустые строки
            dialogue_list.append(trimmed)
    
    print("📚 Загружено диалогов: ", dialogue_list.size())

func next_message() -> void:
    if current_index < dialogue_list.size():
        var message = dialogue_list[current_index]
        print("📢 [", current_index + 1, "] ", message)
        message_shown.emit(message)
        current_index += 1
    else:
        print("🏁 Все диалоги показаны")

func show_event(event_key: String, auto_hide_delay: float = 2.0) -> void:
    if event_messages.has(event_key):
        var message = event_messages[event_key]
        print("🎯 [", event_key, "] ", message)
        message_shown.emit(message)
        
        # Автоматически скрыть через delay секунд
        _start_auto_hide_timer(auto_hide_delay)
    else:
        print("⚠️ Событие не найдено: ", event_key)

var _hide_timer: Timer = null

func _start_auto_hide_timer(delay: float) -> void:
    # Удаляем старый таймер если есть
    if _hide_timer and _hide_timer.is_inside_tree():
        _hide_timer.queue_free()
    
    # Создаём новый таймер
    _hide_timer = Timer.new()
    _hide_timer.wait_time = delay
    _hide_timer.one_shot = true
    _hide_timer.timeout.connect(_on_auto_hide_timeout)
    add_child(_hide_timer)
    _hide_timer.start()

func _on_auto_hide_timeout() -> void:
    hide_message()
    print("🔇 Событие автоматически скрыто")

# Также модифицируем show_text для единообразия
#func show_text(text: String, auto_hide_delay: float = 2.0) -> void:
    #print("📢 [manual] ", text)
    #message_shown.emit(text)
    #_start_auto_hide_timer(auto_hide_delay)
#    else:
 #       print("⚠️ Событие не найдено: ", event_key)

func show_text(text: String) -> void:
    print("📢 [manual] ", text)
    message_shown.emit(text)

func hide_message() -> void:
    message_shown.emit("")

func start_from_index(index: int) -> bool:
    if index >= 0 and index < dialogue_list.size():
        current_index = index
        print("🎬 Начинаем диалог с индекса ", index)
        return true
    else:
        print("❌ Ошибка: индекс ", index, " вне диапазона (0-", dialogue_list.size() - 1, ")")
        return false

# Пример использования:
# start_from_index(3)  # Начнёт с 4-го сообщения

func reset_dialogue() -> void:
    current_index = 0

func has_next() -> bool:
    return current_index < dialogue_list.size()

func get_dialogue_count() -> int:
    return dialogue_list.size()
