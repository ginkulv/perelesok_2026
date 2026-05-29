extends Area2D
class_name RotatableArea2D

@export var rotation_low_deg: float = 0.0
@export var rotation_high_deg: float = 180.0

var value: float = 0

signal value_changed(value: float)

func _ready() -> void:
    add_to_group("rotatable_item")

func update_rotation(drag_offset: Vector2) -> void:
    print(drag_offset.y)
    var add_rotation = clamp(-5.0, drag_offset.y * 0.8, 5.0)
    rotation_degrees = clamp(rotation_low_deg, rotation_degrees + add_rotation, rotation_high_deg)
    print(rotation_degrees)

    value = rotation_degrees / rotation_high_deg

    value_changed.emit(value)
