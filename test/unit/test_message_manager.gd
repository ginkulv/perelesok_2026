extends GutTest

var _saved_index: int = 0


func before_each() -> void:
	_saved_index = MessageManager.current_index


func after_each() -> void:
	MessageManager.reset_dialogue()
	MessageManager.current_index = _saved_index


func test_dialogue_list_is_populated() -> void:
	assert_gt(MessageManager.get_dialogue_count(), 0, "dialogue_script should load lines")


func test_notes_array_has_five_entries() -> void:
	assert_eq(MessageManager.note.size(), 5)


func test_event_messages_has_level1_puzzle_complete() -> void:
	assert_true(MessageManager.event_messages.has("puzzle_complete"))


func test_start_from_text_exact_match() -> void:
	var phrase := "Ура, получилось!"
	assert_true(MessageManager.start_from_text(phrase, true))
	assert_eq(MessageManager.dialogue_list[MessageManager.current_index], phrase)


func test_start_from_text_unknown_returns_false() -> void:
	assert_false(MessageManager.start_from_text("__no_such_phrase__", true))


func test_find_all_matching_finds_level2_opener() -> void:
	var matches := MessageManager.find_all_matching("Знаешь, на самом деле здесь есть цвета", true)
	assert_gt(matches.size(), 0)


func test_begin_dialogue_at_text_advances_index() -> void:
	var phrase := "Ты еще тут? Мне показалось, что ты пропал"
	var idx_before := MessageManager.current_index
	assert_true(MessageManager.begin_dialogue_at_text(phrase, true))
	assert_gt(MessageManager.current_index, idx_before)


func test_begin_dialogue_opens_gate() -> void:
	assert_true(MessageManager.begin_dialogue_at_text("Пу-пу-пу…", true))
	assert_true(MessageManager.is_dialogue_gated())


func test_end_marker_closes_gate() -> void:
	assert_true(MessageManager.begin_dialogue_at_text("Ну вот, кажется, что-то получилось", true))
	assert_true(MessageManager.is_dialogue_gated())
	MessageManager.next_message()
	assert_true(MessageManager.is_dialogue_gated())
	MessageManager.next_message()
	assert_false(MessageManager.is_dialogue_gated())
