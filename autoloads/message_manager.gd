extends Node

signal message_shown(message: String)

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
"""

var event_messages: Dictionary = {
	"first_piece": "Один кусочек на месте...",
	"half_piece": "Половина готова!",
	"last_piece": "Остался последний...",
	"puzzle_complete": "Получилось! Все выглядит совсем как раньше",
	"piece_placed": "Кусочек встал на место!",
	"full_complete": "Ты собрал все!"
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

func show_event(event_key: String) -> void:
	if event_messages.has(event_key):
		var message = event_messages[event_key]
		print("🎯 [", event_key, "] ", message)
		message_shown.emit(message)
	else:
		print("⚠️ Событие не найдено: ", event_key)

func show_text(text: String) -> void:
	print("📢 [manual] ", text)
	message_shown.emit(text)

func hide_message() -> void:
	message_shown.emit("")

func reset_dialogue() -> void:
	current_index = 0

func has_next() -> bool:
	return current_index < dialogue_list.size()

func get_dialogue_count() -> int:
	return dialogue_list.size()
