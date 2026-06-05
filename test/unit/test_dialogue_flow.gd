extends GutTest

## Проверяет, что у каждого уровня есть якорная фраза в dialogue_script.

const LEVEL_DIALOGUE_ANCHORS := {
	"level1_intro": "Пу-пу-пу…",
	"level1_victory": "Ура, получилось!",
	"level2": "Знаешь, на самом деле здесь есть цвета",
	"level3": "Ты еще тут? Мне показалось, что ты пропал",
	"level3_win": "Ну вот, кажется, что-то получилось",
	"level4": "Ой! Что случилось?",
	"level5": "Спасибо, что ты был рядом всё это время.",
}


func test_all_level_anchor_phrases_exist() -> void:
	for key in LEVEL_DIALOGUE_ANCHORS:
		var phrase: String = LEVEL_DIALOGUE_ANCHORS[key]
		assert_true(
			MessageManager.start_from_text(phrase, true),
			"Якорь '%s' (ключ %s) должен быть в dialogue_list" % [phrase, key]
		)


func test_end_markers_present() -> void:
	var end_count := 0
	for line in MessageManager.dialogue_list:
		if line == "__END__":
			end_count += 1
	assert_gte(end_count, 5, "Ожидаем __END__ между блоками уровней")


func test_begin_dialogue_does_not_leave_index_before_anchor() -> void:
	var phrase: String = LEVEL_DIALOGUE_ANCHORS["level3"]
	assert_true(MessageManager.begin_dialogue_at_text(phrase, true))
	var idx_after := MessageManager.current_index
	assert_gt(idx_after, 0, "begin_dialogue должен продвинуть индекс за показанную строку")


func test_next_message_handles_end_marker() -> void:
	var end_i := MessageManager.dialogue_list.find("__END__")
	assert_gte(end_i, 0)
	MessageManager.start_from_index(end_i)
	MessageManager.next_message()
	assert_eq(MessageManager.current_index, end_i + 1)
