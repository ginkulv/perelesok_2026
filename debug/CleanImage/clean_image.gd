extends Sprite2D

@export var clean_texture:Texture2D  # чистая версия
@export var dirty_texture:Texture2D  # грязная версия

var shader_material: ShaderMaterial
var cleaned_pixels = []  # массив очищенных областей

func _ready() -> void:
	setup_cleaning_effect()

func setup_cleaning_effect() -> void:
	# Создаём шейдерный материал
	shader_material = ShaderMaterial.new()
	var shader = preload("res://debug/CleanImage/CleanImage.gdshader")
	shader_material.shader = shader
	
	# Устанавливаем текстуры
	shader_material.set_shader_parameter("dirty_texture", dirty_texture)
	shader_material.set_shader_parameter("clean_texture", clean_texture)
	shader_material.set_shader_parameter("radius", 40.0)
	
	self.material = shader_material

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# Проверяем, наведён ли курсор на картину
		var mouse_uv = get_local_mouse_position() / texture.get_size()
		
		if mouse_uv.x >= 0 and mouse_uv.x <= 1 and mouse_uv.y >= 0 and mouse_uv.y <= 1:
			# Обновляем позицию курсора в шейдере
			shader_material.set_shader_parameter("mouse_pos", mouse_uv)
			
			# Запоминаем очищенную область
			cleaned_pixels.append(mouse_uv)
			
			# Создаём визуальный эффект
			create_clean_effect(mouse_uv)
			
			# Проверяем, очищена ли вся картина
			check_full_clean()

func create_clean_effect(pos: Vector2) -> void:
	# Эффект искр/звездочек при протирке
	var particle = Sprite2D.new()
	particle.texture = preload("res://debug/CleanImage/cleanParticle.tres")  # маленькая звездочка
	particle.position = get_global_mouse_position()
	particle.scale = Vector2(0.5, 0.5)
	add_child(particle)
	
	var tween = create_tween()
	tween.tween_property(particle, "modulate:a", 0, 0.3)
	tween.tween_callback(particle.queue_free)

func check_full_clean() -> void:
	# Простая проверка: если очищено больше 100 областей, считаем картину чистой
	if cleaned_pixels.size() > 100:
		on_painting_clean()

func on_painting_clean() -> void:
	print("Картина полностью чистая!")
	
	# Убираем шейдер, показываем чистую текстуру
	self.material = null
	self.texture = clean_texture
	
	# Отключаем дальнейшую очистку
	set_process_input(false)
	
	# Создаём файл на рабочем столе
