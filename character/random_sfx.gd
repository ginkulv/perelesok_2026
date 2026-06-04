extends Node
class_name RandomSFX

@export var audio_players: Array[AudioStreamPlayer2D] = []
@export var random_pitch: bool = true
@export var min_pitch: float = 0.8
@export var max_pitch: float = 1.2

func _ready() -> void:
	if audio_players.is_empty():
		_find_audio_players()

func _find_audio_players() -> void:
	for child in get_children():
		if child is AudioStreamPlayer2D:
			audio_players.append(child)

func play_random() -> void:
	if audio_players.is_empty():
		return
	
	var random_index = randi() % audio_players.size()
	var player = audio_players[random_index]
	
	if player and player.stream:
		if random_pitch:
			player.pitch_scale = randf_range(min_pitch, max_pitch)
		player.play()
