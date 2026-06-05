extends Node

signal message_shown(message: String)
signal dialogue_gate_changed(active: bool)
signal dialogue_segment_finished

#каждая новая строка это новое облачко __END__ заканчивает монолог по длине не больше чем в примере строчки
var dialogue_script: String = """
Пу-пу-пу…
Что? Кто здесь??? Ты... настоящий?
Ты что, меня слышишь? 
Ну и дела! Я так давно никого не слышал
только свои мысли…
Где мы? Это мое тихое уютное воспоминание
В нем так привычно и безопасно
что я решил в нем спрятаться.
Только вот оно почему-то порвалось… 
Может потому, что я слишком крепко за него держался?
Весь мой мир замкнулся на этом воспоминании,
и я уже не уверен,
что за краем этого снимка что-то есть…
Но все равно, может поможешь починить его?
__END__
Ура, получилось!
Все выглядит совсем как раньше.
И знаешь, кажется я готов посмотреть
что там есть, вне этой фотографии.
__END__
Знаешь, на самом деле здесь есть цвета
Просто пока я сидел в прошлом
Мой нынешний мир совсем запылился
Прости за беспорядок, пожалуйста…
Слушай, если у тебя есть время и силы, может
Поможешь протереть эту пыль?
Станет гораздо легче дышать
__END__
Спасибо, спасибо, спасибо!
Жаль, правда, что здесь так пусто…
Иногда мне кажется, Что я все так запустил
Что и смысла пытаться что-то изменить нет
Но все же тут уже стало гораздо лучше…
Ладно, давай попытаемся добавить немного уюта!
Для начала включим свет..
Хочется чтобы было место, куда можно плюхнуться..
И выпить чаю!
Вот так! Теперь здесь хорошо.
__END__
Ты еще тут? Мне показалось, что ты пропал
Или это я пропал?
Хорошо, когда внутри все красиво и чисто
Но как сложно это кому-то показать...
Я не уверен, что умею
Увидят ли они именно настоящего меня?
Связь - это непросто..
Ты мне поможешь наладить сигнал?
__END__
Ну вот, кажется, что-то получилось
Тебе хорошо видно? А другим тоже будет видно?
__END__
Ой! Что случилось?
Сейчас, подожди, тебе неудобно, наверное
Вот, так лучше?
Все какое-то... странное.
Это вот так комнату видят другие?
Я все совсем не так представлял!!
Кажется, я сейчас начну паниковать
Может это значит, что все в порядке?
Наверное, это нормально, что люди снаружи
Видят меня чуть иначе чем я изнутри
Они же смотрят через призмы своих миров..
__END__
Спасибо, что ты был рядом всё это время.
Мы столько всего починили...
И комната теперь настоящая. Обычная. Моя.
Я чувствую, что пора выходить.
Но мне страшно — я так долго здесь сидел.
Скажи... что мне ждать там, снаружи?
__END__

"""

#каждая новая строка в кавычках и через запятую это следующая записка 
var note: Array = [
"Если слишком зарыться в воспоминания, можно оказаться в их плену и перестать различать, где реальность а где ее имитация. Наверное, память — это фундамент для дальнейших действий, а не крепость, в которой стоит прятаться от мира. Да и потом, как двигаться вперед, если смотришь всегда в прошлое?",
"В каждом скрыто много удивительного. Но иногда чтобы найти это, нужно не ругать себя за внутренний беспорядок, а просто начать делать хоть небольшие шаги, чтобы тебе самому стало уютнее. В конце концов как иначе понять, где настоящий ты?",
"Связь с другими, это и правда непросто. Однако чем лучше ты понимаешь себя, тем проще тебе донести то что внутри до окружающих. И тем меньше опасность, что они увидят твою искаженную внешними помехами версию",
"Со стороны все может выглядеть иначе, и иногда очень важно взглянуть оттуда на себя. Кто я? Где я? Не запутался ли я во внутренних слоях? Осознаю ли я реальность?",
"Спасибо, что дошёл до конца вместе со мной. Эта комната была моим убежищем, а ты помог мне снова увидеть её — и себя — яснее. Не знаю, что будет дальше, но теперь мне чуть менее страшно попробовать. Береги себя.",
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
var _dialogue_gate_active: bool = false
var _segment_end_text: String = ""
var _awaiting_segment_dismiss: bool = false
var _last_shown_message: String = ""

func _ready() -> void:
	_parse_dialogue_script()
# НОВЫЙ МЕТОД: Поиск индекса по тексту и установка текущего индекса
func start_from_text(text: String, exact_match: bool = false) -> bool:
	#"""
	#Начинает диалог с фразы, содержащей указанный текст (или точно совпадающей)
	#
	#Параметры:
	#- text: строка для поиска
	#- exact_match: если true - ищем точное совпадение, если false - частичное
	#
	#Возвращает: true если фраза найдена, false если нет
	#"""
	var found_index = -1
	
	for i in range(dialogue_list.size()):
		var dialogue_text = dialogue_list[i]
		
		if exact_match:
			if dialogue_text == text:
				found_index = i
				break
		else:
			if dialogue_text.find(text) != -1:
				found_index = i
				break
	
	if found_index != -1:
		current_index = found_index
		print("✅ Найдена фраза '", text, "' на индексе ", found_index)
		print("📢 Текст фразы: ", dialogue_list[found_index])
		return true
	else:
		print("❌ Фраза '", text, "' не найдена в диалогах")
		return false


func is_dialogue_gated() -> bool:
	return _dialogue_gate_active


func get_last_shown_message() -> String:
	return _last_shown_message


func _set_dialogue_gate(active: bool) -> void:
	if _dialogue_gate_active == active:
		return
	_dialogue_gate_active = active
	dialogue_gate_changed.emit(active)


## Ставит индекс на фразу и сразу показывает её в облачке персонажа.
func begin_dialogue_at_text(text: String, exact_match: bool = false) -> bool:
	_clear_segment_state()
	_cancel_auto_hide_timer()
	if not start_from_text(text, exact_match):
		return false
	_set_dialogue_gate(true)
	next_message()
	return true


## Показывает от start_text до end_text; следующий клик после end_text закрывает сегмент.
func begin_dialogue_segment(start_text: String, end_text: String, exact_match: bool = true) -> bool:
	_clear_segment_state()
	_cancel_auto_hide_timer()
	if not start_from_text(start_text, exact_match):
		return false
	_segment_end_text = end_text
	_set_dialogue_gate(true)
	next_message()
	return true


func _clear_segment_state() -> void:
	_segment_end_text = ""
	_awaiting_segment_dismiss = false

# ДОПОЛНИТЕЛЬНЫЙ МЕТОД: Поиск по ключевому слову и показ конкретной фразы
func show_specific_message(text: String, exact_match: bool = false) -> bool:
	#"""
	#Находит и сразу показывает конкретную фразу, не меняя глобальный индекс диалога
	#
	#Возвращает: true если фраза найдена и показана, false если нет
	#"""
	var found_index = -1
	
	for i in range(dialogue_list.size()):
		var dialogue_text = dialogue_list[i]
		
		if exact_match:
			if dialogue_text == text:
				found_index = i
				break
		else:
			if dialogue_text.find(text) != -1:
				found_index = i
				break
	
	if found_index != -1:
		var message = dialogue_list[found_index]
		print("📢 [специально] ", message)
		message_shown.emit(message)
		return true
	else:
		print("❌ Фраза '", text, "' не найдена")
		return false

# ДОПОЛНИТЕЛЬНЫЙ МЕТОД: Поиск всех вхождений текста
func find_all_matching(text: String, exact_match: bool = false) -> Array[int]:
	#"""
	#Находит все индексы, где встречается указанный текст
	#
	#Возвращает: массив индексов
	#"""
	var matches: Array[int] = []
	
	for i in range(dialogue_list.size()):
		var dialogue_text = dialogue_list[i]
		
		if exact_match:
			if dialogue_text == text:
				matches.append(i)
		else:
			if dialogue_text.find(text) != -1:
				matches.append(i)
	
	print("🔍 Найдено ", matches.size(), " совпадений для '", text, "': ", matches)
	return matches

# ДОПОЛНИТЕЛЬНЫЙ МЕТОД: Начать с первой фразы, содержащей текст
func start_from_containing(text: String) -> bool:
	#"""
	#Упрощенный вариант - начинает с первой фразы, содержащей указанный текст
	#"""
	return start_from_text(text, false)

# Пример использования:
# start_from_text("поможешь починить")  # Начнет с фразы содержащей "поможешь починить"
# start_from_text("Ура, получилось!", true)  # Начнет с точной фразы
# show_specific_message("Спасибо")  # Покажет конкретную фразу, не меняя индекс

func _parse_dialogue_script() -> void:
	var raw_lines = dialogue_script.split("\n", false)
	
	for line in raw_lines:
		var trimmed = line.strip_edges()
		if trimmed != "":  # Пропускаем пустые строки
			dialogue_list.append(trimmed)
	
	print("📚 Загружено диалогов: ", dialogue_list.size())

func next_message() -> void:
	_cancel_auto_hide_timer()
	if _awaiting_segment_dismiss:
		_clear_segment_state()
		_set_dialogue_gate(false)
		message_shown.emit("")
		dialogue_segment_finished.emit()
		return
	if current_index >= dialogue_list.size():
		print("🏁 Все диалоги показаны")
		return
	var message := dialogue_list[current_index]
	current_index += 1
	print("📢 [", current_index, "] ", message)
	if message == "__END__":
		_clear_segment_state()
		_set_dialogue_gate(false)
		message_shown.emit("")
		return
	_last_shown_message = message
	message_shown.emit(message)
	if _segment_end_text != "" and message == _segment_end_text:
		_awaiting_segment_dismiss = true

func show_event(event_key: String, auto_hide_delay: float = 2.0) -> void:
	if event_messages.has(event_key):
		_cancel_auto_hide_timer()
		var message = event_messages[event_key]
		print("🎯 [", event_key, "] ", message)
		message_shown.emit(message)
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
	_cancel_auto_hide_timer()
	print("📢 [manual] ", text)
	_last_shown_message = text
	message_shown.emit(text)

func hide_message() -> void:
	_cancel_auto_hide_timer()
	message_shown.emit("")

func _cancel_auto_hide_timer() -> void:
	if _hide_timer != null and is_instance_valid(_hide_timer):
		if _hide_timer.is_inside_tree():
			_hide_timer.queue_free()
	_hide_timer = null

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
	_cancel_auto_hide_timer()
	_clear_segment_state()
	_set_dialogue_gate(false)
	_last_shown_message = ""
	current_index = 0

func has_next() -> bool:
	return current_index < dialogue_list.size()

func get_dialogue_count() -> int:
	return dialogue_list.size()
