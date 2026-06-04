extends Area2D
class_name RotatableArea2D

@export var min_rotation_deg: float = 0.0
@export var max_rotation_deg: float = 180.0
@export var max_rotation_speed: float = 3.0
@export var deg_to_val_ratio: float = 0.01

@export var first_threshold_deg: float = 100.0
@export var second_threshold_deg: float = 120.0 
@export var min_value: float = 0.0

var value: float = 0

signal value_changed(value: float, is_correct: bool)

func _ready() -> void:
    add_to_group("rotatable_item")

func update_rotation(drag_offset: Vector2) -> void:
    print(drag_offset.y)
    var add_rotation = clamp(-max_rotation_speed, drag_offset.y * 0.8, max_rotation_speed)
    rotation_degrees = clamp(min_rotation_deg, rotation_degrees - add_rotation, max_rotation_deg)
    
    if rotation_degrees < first_threshold_deg:
        value = (first_threshold_deg - rotation_degrees) * deg_to_val_ratio
    elif rotation_degrees > second_threshold_deg:
        value = (rotation_degrees - second_threshold_deg) * deg_to_val_ratio
    else:
        value = min_value # если захочется, чтобы немножко эффекта осталось, хз
    value = clamp(0.0, value, 1.0)

    value_changed.emit(value, rotation_degrees >= first_threshold_deg and rotation_degrees <= second_threshold_deg)
