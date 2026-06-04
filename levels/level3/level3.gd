extends Node

@onready var room_background_sprite = $RoomBackground
var material: ShaderMaterial

@export var initial_params: float = 1.0

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
            
var is_white_noise_correct: bool = false
var is_vhs_correct: bool = false

func _ready() -> void:
    var shader = preload("res://levels/level3/noise_vhs_shader.gdshader")
    material = ShaderMaterial.new()
    material.shader = shader

    noise_strength = initial_params
    noise_speed = initial_params
    vhs_strength = initial_params
    jitter_amount = initial_params
    color_bleed = initial_params
    scanline_intensity = initial_params

    room_background_sprite.material = material

    $TvBorder/WhiteNoiseKnob.value_changed.connect(_on_white_noise_changed)
    $TvBorder/VhsKnob.value_changed.connect(_on_vhs_changed)

    $TvBorder/WhiteNoiseGreenLight.visible = false
    $TvBorder/VhsGreenLight.visible = false

func _on_white_noise_changed(value: float, is_correct: bool) -> void:
    noise_strength = value
    noise_speed = value
    
    is_white_noise_correct = is_correct 

    if is_white_noise_correct:
        $TvBorder/WhiteNoiseGreenLight.visible = true
        $TvBorder/WhiteNoiseRedLight.visible = false
    else:
        $TvBorder/WhiteNoiseGreenLight.visible = false
        $TvBorder/WhiteNoiseRedLight.visible = true

    if is_white_noise_correct and is_vhs_correct:
        print("who hoo!")

func _on_vhs_changed(value: float, is_correct: bool) -> void:
    vhs_strength = value
    jitter_amount = value
    color_bleed = value
    scanline_intensity = value
    
    if is_vhs_correct:
        $TvBorder/VhsGreenLight.visible = true
        $TvBorder/VhsRedLight.visible = false
    else:
        $TvBorder/VhsGreenLight.visible = false
        $TvBorder/VhsRedLight.visible = true

    is_vhs_correct = is_correct
    if is_white_noise_correct and is_vhs_correct:
        print("who hoo!")
    
