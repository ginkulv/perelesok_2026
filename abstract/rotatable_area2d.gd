extends Area2D
class_name RotatableArea2D

@export var min_rotation_deg: float = 0.0
@export var max_rotation_deg: float = 180.0
@export var max_rotation_speed: float = 3.0
@export var deg_to_val_ratio: float = 0.01

@export var first_threshold_deg: float = 100.0
@export var second_threshold_deg: float = 120.0 
@export var min_value: float = 0.0

# Настройки звука
@export var noise_volume_multiplier: float = 1.0
@export var min_noise_volume: float = -80.0
@export var max_noise_volume: float = 0.0

var value: float = 0
var noise_audio: AudioStreamPlayer = null
var _is_being_rotated: bool = false  # Флаг что ручку сейчас крутят

# Сигналы
signal value_changed(value: float, is_correct: bool)
signal rotated()  # Сигнал для звука вращения
signal rotation_started()  # НОВЫЙ СИГНАЛ: начали крутить
signal rotation_ended()    # НОВЫЙ СИГНАЛ: закончили крутить

func _ready() -> void:
    add_to_group("rotatable_item")
    _find_noise_source()

func _find_noise_source() -> void:
    for child in get_children():
        if child is AudioStreamPlayer:
            noise_audio = child
            print("🔊 Найден AudioStreamPlayer: ", child.name)
            break
    
    if noise_audio == null:
        print("⚠️ AudioStreamPlayer не найден в дочерних узлах")

func update_rotation(drag_offset: Vector2) -> void:
    # Если начали вращать первый раз в этом движении
    if not _is_being_rotated:
        _is_being_rotated = true
        rotation_started.emit()  # Эмитим сигнал начала вращения
        print("🔄 ", name, " начали крутить")
    
    var add_rotation = clamp(-max_rotation_speed, drag_offset.y * 0.8, max_rotation_speed)
    rotation_degrees = clamp(min_rotation_deg, rotation_degrees + add_rotation, max_rotation_deg)
    
    # Рассчитываем value
    if rotation_degrees < first_threshold_deg:
        value = (first_threshold_deg - rotation_degrees) * deg_to_val_ratio
    elif rotation_degrees > second_threshold_deg:
        value = (rotation_degrees - second_threshold_deg) * deg_to_val_ratio
    else:
        value = min_value
    
    value = clamp(value, 0.0, 1.0)
    
    # Обновляем громкость шума
    _update_noise_volume()
    
    # Эмитируем сигналы
    value_changed.emit(value, rotation_degrees >= first_threshold_deg and rotation_degrees <= second_threshold_deg)
    rotated.emit()  # Эмитируем сигнал для звука

# НОВЫЙ МЕТОД: вызывается когда игрок отпустил ручку
func end_rotation() -> void:
    if _is_being_rotated:
        _is_being_rotated = false
        rotation_ended.emit()  # Эмитим сигнал окончания вращения
        print("🔄 ", name, " отпустили")

func _update_noise_volume() -> void:
    if noise_audio == null:
        return
    
    var is_correct = rotation_degrees >= first_threshold_deg and rotation_degrees <= second_threshold_deg
    
    if is_correct:
        noise_audio.volume_db = min_noise_volume
    else:
        var distance_to_range: float = 0.0
        
        if rotation_degrees < first_threshold_deg:
            distance_to_range = first_threshold_deg - rotation_degrees
        else:
            distance_to_range = rotation_degrees - second_threshold_deg
        
        var max_possible_distance = max(
            first_threshold_deg - min_rotation_deg,
            max_rotation_deg - second_threshold_deg
        )
        var normalized_distance = clamp(distance_to_range / max_possible_distance, 0.0, 1.0)
        
        var volume_range = (max_noise_volume - min_noise_volume) * 3
        var volume = min_noise_volume + (normalized_distance * volume_range * noise_volume_multiplier)
        
        noise_audio.volume_db = clamp(volume, min_noise_volume, max_noise_volume)

# Метод для сброса (если нужен)
func reset_dialogue() -> void:
    rotation_degrees = min_rotation_deg
    value = 0.0
    _is_being_rotated = false
    _update_noise_volume()
    value_changed.emit(value, false)
