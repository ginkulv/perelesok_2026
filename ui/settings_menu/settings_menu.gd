extends Node

signal settings_closed()

func _ready() -> void:
    $CanvasLayer/SettingsPanel/VBoxContainer/HBoxContainer/SFXSlider.value = AudioManager.sfx_volume_ln
    $CanvasLayer/SettingsPanel/VBoxContainer/HBoxContainer2/MusicSlider.value = AudioManager.music_volume_ln

func _on_back_button_button_up():
    settings_closed.emit()
    queue_free()

func _on_sfx_slider_value_changed(value: float) -> void:
    AudioManager.change_sfx_volume(value)

func _on_music_slider_value_changed(value: float) -> void:
    AudioManager.change_music_volume(value)
