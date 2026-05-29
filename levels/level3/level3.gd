extends Node

@onready var room_sprite = $RoomSprite
var material: ShaderMaterial

@export var noise_strength: float = 0.1:
    set(value):
        noise_strength = value
        if material:
            material.set_shader_parameter("noise_strength", value)

@export var noise_speed: float = 0.1:
    set(value):
        noise_speed = value
        if material:
            material.set_shader_parameter("noise_speed", value)

@export var vhs_strength: float = 0.1:
    set(value):
        vhs_strength = value
        if material:
            material.set_shader_parameter("vhs_strength", value)

@export var jitter_amount: float = 0.1:
    set(value):
        jitter_amount = value
        if material:
            material.set_shader_parameter("jitter_amount", value)

@export var color_bleed: float = 0.1:
    set(value):
        color_bleed = value
        if material:
            material.set_shader_parameter("color_bleed", value)

@export var scanline_intensity: float = 0.1:
    set(value):
        scanline_intensity = value
        if material:
            material.set_shader_parameter("scanline_intensity", value)

func _ready() -> void:
    var shader = preload("res://levels/level3/noise_vhs_shader.gdshader")
    material = ShaderMaterial.new()
    material.shader = shader

    material.set_shader_parameter("strength", 0.15)

    room_sprite.material = material

    $Knob1.value_changed.connect(_on_white_noise_changed)
    $Knob2.value_changed.connect(_on_vhs_changed)


func _process(delta: float) -> void:
    pass

func _on_white_noise_changed(value: float) -> void:
    noise_strength = value
    noise_speed = value

func _on_vhs_changed(value: float) -> void:
    vhs_strength = value
    jitter_amount = value
    color_bleed = value
    scanline_intensity = value
