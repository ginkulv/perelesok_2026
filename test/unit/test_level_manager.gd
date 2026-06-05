extends GutTest


func test_level_paths_count() -> void:
	assert_eq(LevelManager.num_of_levels, 5)
	assert_eq(LevelManager.level_paths.size(), 5)
	assert_eq(LevelManager.level_names.size(), 5)


func test_level_paths_and_names_match_convention() -> void:
	for i in range(LevelManager.num_of_levels):
		var n := i + 1
		assert_eq(
			LevelManager.level_paths[i],
			"res://levels/level%d/level%d.tscn" % [n, n]
		)
		assert_eq(LevelManager.level_names[i], "Level%d" % n)


func test_level_scene_files_exist() -> void:
	for path in LevelManager.level_paths:
		assert_file_exists(path)


func test_reset_for_new_game_sets_index_zero() -> void:
	LevelManager.index = 3
	LevelManager.reset_for_new_game()
	assert_eq(LevelManager.index, 0)


func test_reset_for_new_game_can_start_at_specific_level() -> void:
	LevelManager.reset_for_new_game(4)
	assert_eq(LevelManager.index, 3)
	assert_eq(LevelManager.get_level_scene_path(4), "res://levels/level4/level4.tscn")
