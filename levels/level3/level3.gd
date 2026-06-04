extends Node2D

@onready var room_background_sprite = $shader
var shader_material: ShaderMaterial

@export var initial_params: float = 0.0

# Текущие значения от крутилок
var current_noise_value: float = 0.0
var current_vhs_value: float = 0.0

# Допустимые диапазоны для "зелёной зоны"
@export var white_noise_min_correct: float = 0.0   # Зеленая зона при 0
@export var white_noise_max_correct: float = 0.05
@export var vhs_min_correct: float = 0.0
@export var vhs_max_correct: float = 0.05

var current_quality_noise: float = 1.0
var current_quality_vhs: float = 1.0

var is_white_noise_correct: bool = false
var is_vhs_correct: bool = false

# Новые переменные для отслеживания вращения
var is_white_knob_being_rotated: bool = false
var is_vhs_knob_being_rotated: bool = false
var has_been_in_green_zone: bool = false  # Флаг что игрок уже был в зеленой зоне

signal puzzle_completed()
signal setting_changed(setting_name: String, value: float)

func _ready() -> void:
	AudioManager.play_music(load("res://assets/music/телефизор.mp3"))
	MessageManager.start_from_text("Ты еще тут? Мне показалось, что ты пропал", true)
	
	# Создаем шейдерный материал
	var shader = room_background_sprite.material.shader
	shader_material = room_background_sprite.material
	shader_material.shader = shader
	
	# Подключаем сигналы
	var white_knob = $TvBorder/WhiteNoiseKnob
	var vhs_knob = $TvBorder/VhsKnob
	
	white_knob.value_changed.connect(_on_white_noise_changed)
	vhs_knob.value_changed.connect(_on_vhs_changed)
	
	# Подключаем сигналы начала и конца вращения
	white_knob.rotation_started.connect(_on_white_knob_rotation_started)
	white_knob.rotation_ended.connect(_on_white_knob_rotation_ended)
	
	vhs_knob.rotation_started.connect(_on_vhs_knob_rotation_started)
	vhs_knob.rotation_ended.connect(_on_vhs_knob_rotation_ended)

	$TvBorder/WhiteNoiseGreenLight.visible = false
	$TvBorder/VhsGreenLight.visible = false
	$TvBorder/WhiteNoiseRedLight.visible = true
	$TvBorder/VhsRedLight.visible = true
	
	_setup_knob_sounds()
	
	# Начальные значения
	current_noise_value = initial_params
	current_vhs_value = initial_params
	
	# Применяем эффекты
	_apply_effects()

func _setup_knob_sounds() -> void:
	var white_knob = $TvBorder/WhiteNoiseKnob
	var vhs_knob = $TvBorder/VhsKnob
	
	if not white_knob.rotated.is_connected(_on_white_knob_rotated):
		white_knob.rotated.connect(_on_white_knob_rotated)
	
	if not vhs_knob.rotated.is_connected(_on_vhs_knob_rotated):
		vhs_knob.rotated.connect(_on_vhs_knob_rotated)

func _on_white_knob_rotated() -> void:
	AudioManager.play_sfx("крутим крутилки.mp3", 0.3)

func _on_vhs_knob_rotated() -> void:
	AudioManager.play_sfx("крутим крутилки.mp3", 0.3)

# Новые обработчики начала/конца вращения
func _on_white_knob_rotation_started() -> void:
	is_white_knob_being_rotated = true
	print("🔘 Белая ручка начали крутить")

func _on_white_knob_rotation_ended() -> void:
	is_white_knob_being_rotated = false
	print("🔘 Белая ручку отпустили")
	_check_puzzle_completion()  # Проверяем когда отпустили

func _on_vhs_knob_rotation_started() -> void:
	is_vhs_knob_being_rotated = true
	print("🔘 VHS ручку начали крутить")

func _on_vhs_knob_rotation_ended() -> void:
	is_vhs_knob_being_rotated = false
	print("🔘 VHS ручку отпустили")
	_check_puzzle_completion()  # Проверяем когда отпустили

func _check_puzzle_completion() -> void:
	# Проверяем: обе ручки в зеленой зоне И их не крутят
	if is_white_noise_correct and is_vhs_correct:
		if not is_white_knob_being_rotated and not is_vhs_knob_being_rotated:
			if not has_been_in_green_zone:
				# Первый раз попали в зеленую зону и отпустили
				has_been_in_green_zone = true
				MessageManager.show_text("Ну вот, кажется, что-то получилось
Тебе хорошо видно? А другим тоже будет видно?")
				_complete_puzzle()
		else:
			if has_been_in_green_zone:
				# Игрок снова начал крутить после того как уже было правильно
				has_been_in_green_zone = false
				print("⚠️ Игрок снова крутит ручки, сброс флага завершения")
	else:
		# Если вышли из зеленой зоны - сбрасываем флаг
		if has_been_in_green_zone:
			has_been_in_green_zone = false
			print("🟡 Выход из зеленой зоны, флаг сброшен")

func _calculate_quality_noise() -> float:
	# Качество для шума (0-1)
	if current_noise_value < white_noise_min_correct:
		var distance = white_noise_min_correct - current_noise_value
		var max_distance = white_noise_min_correct
		return 1.0 - clamp(distance / max_distance, 0.0, 0.95)
	elif current_noise_value > white_noise_max_correct:
		var distance = current_noise_value - white_noise_max_correct
		var max_distance = 1.0 - white_noise_max_correct
		return 1.0 - clamp(distance / max_distance, 0.0, 0.95)
	else:
		return 1.0

func _calculate_quality_vhs() -> float:
	# Качество для VHS (0-1)
	if current_vhs_value < vhs_min_correct:
		var distance = vhs_min_correct - current_vhs_value
		var max_distance = vhs_min_correct
		return 1.0 - clamp(distance / max_distance, 0.0, 0.95)
	elif current_vhs_value > vhs_max_correct:
		var distance = current_vhs_value - vhs_max_correct
		var max_distance = 1.0 - vhs_max_correct
		return 1.0 - clamp(distance / max_distance, 0.0, 0.95)
	else:
		return 1.0

func _apply_effects() -> void:
	if not shader_material:
		return
	
	# Обновляем статус правильности
	var new_white_correct = (current_noise_value >= white_noise_min_correct and 
							   current_noise_value <= white_noise_max_correct)
	var new_vhs_correct = (current_vhs_value >= vhs_min_correct and 
						   current_vhs_value <= vhs_max_correct)
	
	if new_white_correct != is_white_noise_correct:
		is_white_noise_correct = new_white_correct
		_update_indicators("white_noise", is_white_noise_correct)
		# Когда статус меняется, проверяем завершение
		_check_puzzle_completion()
	
	if new_vhs_correct != is_vhs_correct:
		is_vhs_correct = new_vhs_correct
		_update_indicators("vhs", is_vhs_correct)
		# Когда статус меняется, проверяем завершение
		_check_puzzle_completion()
	
	# Рассчитываем качество для каждого типа эффектов
	current_quality_noise = _calculate_quality_noise()
	current_quality_vhs = _calculate_quality_vhs()
	
	# === ЭФФЕКТЫ БЕЛОГО ШУМА (управляются левой ручкой) ===
	var max_noise = 2.35
	var min_noise = 0.01
	var final_noise = lerp(max_noise, min_noise, current_quality_noise)
	
	var max_noise_speed = 2.0
	var min_noise_speed = 0.3
	var final_noise_speed = lerp(max_noise_speed, min_noise_speed, current_quality_noise)
	
	# Обесцвечивание (усиливается при плохом качестве шума)
	var desaturate_factor = 1.0 - current_quality_noise
	shader_material.set_shader_parameter("desaturate_start", 0.05 + desaturate_factor * 0.15)
	shader_material.set_shader_parameter("desaturate_end", 0.15 + desaturate_factor * 0.25)
	
	# === ЭФФЕКТЫ VHS (управляются правой ручкой) ===
	var max_vhs = 0.4
	var min_vhs = 0.01
	var final_vhs = lerp(max_vhs, min_vhs, current_quality_vhs)
	
	var max_jitter = 0.035
	var min_jitter = 0.001
	var final_jitter = lerp(max_jitter, min_jitter, current_quality_vhs)
	
	var max_bleed = 0.025
	var min_bleed = 0.001
	var final_bleed = lerp(max_bleed, min_bleed, current_quality_vhs)
	
	var max_scanline = 0.25
	var min_scanline = 0.01
	var final_scanline = lerp(max_scanline, min_scanline, current_quality_vhs)
	
	# Применяем все параметры к шейдеру
	shader_material.set_shader_parameter("noise_strength", final_noise)
	shader_material.set_shader_parameter("noise_speed", final_noise_speed)
	
	shader_material.set_shader_parameter("vhs_strength", final_vhs)
	shader_material.set_shader_parameter("jitter_amount", final_jitter)
	shader_material.set_shader_parameter("color_bleed", final_bleed)
	shader_material.set_shader_parameter("scanline_intensity", final_scanline)

func _on_white_noise_changed(value: float, is_correct: bool) -> void:
	current_noise_value = value
	_apply_effects()

func _on_vhs_changed(value: float, is_correct: bool) -> void:
	current_vhs_value = value
	_apply_effects()

func _update_indicators(knob_type: String, is_correct: bool) -> void:
	match knob_type:
		"white_noise":
			$TvBorder/WhiteNoiseGreenLight.visible = is_correct
			$TvBorder/WhiteNoiseRedLight.visible = not is_correct
		"vhs":
			$TvBorder/VhsGreenLight.visible = is_correct
			$TvBorder/VhsRedLight.visible = not is_correct

func _complete_puzzle() -> void:
	print("✅ Puzzle complete! TV настроен правильно!")
	_celebrate_success()
	puzzle_completed.emit()
	
	# Небольшая задержка перед переходом
	await get_tree().create_timer(1.5).timeout
	LevelManager.go_to_next_level()

func _celebrate_success() -> void:
	var tween = create_tween()
	tween.tween_method(_fade_out_effects, 1.0, 0.0, 1.0)

func _fade_out_effects(factor: float) -> void:
	if shader_material:
		shader_material.set_shader_parameter("noise_strength", 0.01 * (1.0 - factor))
		shader_material.set_shader_parameter("vhs_strength", 0.01 * (1.0 - factor))
		shader_material.set_shader_parameter("jitter_amount", 0.001 * (1.0 - factor))
		shader_material.set_shader_parameter("color_bleed", 0.001 * (1.0 - factor))
		shader_material.set_shader_parameter("scanline_intensity", 0.01 * (1.0 - factor))

func reset_puzzle() -> void:
	is_white_noise_correct = false
	is_vhs_correct = false
	has_been_in_green_zone = false
	is_white_knob_being_rotated = false
	is_vhs_knob_being_rotated = false
	
	if $TvBorder/WhiteNoiseKnob.has_method("reset_dialogue"):
		$TvBorder/WhiteNoiseKnob.reset_dialogue()
	if $TvBorder/VhsKnob.has_method("reset_dialogue"):
		$TvBorder/VhsKnob.reset_dialogue()
	
	_update_indicators("white_noise", false)
	_update_indicators("vhs", false)
	
	current_noise_value = initial_params
	current_vhs_value = initial_params
	_apply_effects()

func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_F3):
		print("=== ОТЛАДКА ===")
		print("White Noise: %.3f | Зелёная зона: %.2f-%.2f | ✅: %s | Качество: %d%% | Крутят: %s" % [
			current_noise_value, white_noise_min_correct, white_noise_max_correct, 
			is_white_noise_correct, current_quality_noise * 100, is_white_knob_being_rotated
		])
		print("VHS: %.3f | Зелёная зона: %.2f-%.2f | ✅: %s | Качество: %d%% | Крутят: %s" % [
			current_vhs_value, vhs_min_correct, vhs_max_correct, 
			is_vhs_correct, current_quality_vhs * 100, is_vhs_knob_being_rotated
		])
		print("Обе в зеленой зоне и не крутят: ", is_white_noise_correct and is_vhs_correct and not is_white_knob_being_rotated and not is_vhs_knob_being_rotated)
