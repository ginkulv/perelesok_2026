extends Node

const max_sfx_players: int = 10
const layer_fade_in_time_sec: float = 3.0
const ending_fade_time_sec: float = 10

var music_player: AudioStreamPlayer
var sync_stream: AudioStreamSynchronized
var music_streams: Array[Resource] = [ ]
var sfx_players: Array[AudioStreamPlayer]

var bus_index: int
var sync_stream_index: int = 0

@export var music_volume_ln : float = 80
@export var sfx_volume_ln : float = 80

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	bus_index = AudioServer.get_bus_index("SFX")
	if bus_index == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
	AudioServer.set_bus_volume_linear(bus_index, sfx_volume_ln / 100)

	bus_index = AudioServer.get_bus_index("Music")
	if bus_index == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")
	AudioServer.set_bus_volume_linear(bus_index, music_volume_ln / 100)

	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

	sync_stream = AudioStreamSynchronized.new()
	sync_stream.stream_count = music_streams.size()
	for i in range(music_streams.size()):
		sync_stream.set_sync_stream(i, music_streams[i])
		sync_stream.set_sync_stream_volume(i, linear_to_db(0))
	music_player.stream = sync_stream

	for i in range(max_sfx_players):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.bus = "SFX"
		sfx_players.append(sfx_player)
		add_child(sfx_player)

func play_sfx(sfx_name_with_extension: String, volume_linear: float = 1) -> void:
	var stream = load("res://assets/sfx/" + sfx_name_with_extension)

	for player: AudioStreamPlayer in sfx_players:
		if !player.playing:
			player.stream = stream
			player.volume_linear = volume_linear
			player.play()
			break

func stop_sfx(sfx_name_with_extension: String) -> void:
	for player in sfx_players:
		if not player.stream:
			continue
		if player.stream.resource_path.get_file() == sfx_name_with_extension:
			player.stop()

func fade_in_sfx(sfx_name_with_extension: String, volume_linear: float = 1) -> void:
	var stream = load("res://assets/sfx/" + sfx_name_with_extension)

	for player: AudioStreamPlayer in sfx_players:
		if !player.playing:
			player.stream = stream
			player.volume_linear = 0
			player.play()
			var tween = get_tree().create_tween() 
			tween.tween_property(player, "volume_linear", volume_linear, ending_fade_time_sec)
			break

func start_music() -> void:
	sync_stream.set_sync_stream_volume(0, 0)
	music_player.play()

func play_music(music:AudioStream) -> void:
	sync_stream.set_sync_stream_volume(0, 0)
	music_player.stream = music;
	music_player.play()

func is_music_playing() -> bool:
	return music_player.playing

func add_layer() -> void:
	var tween = get_tree().create_tween()

	sync_stream_index += 1 
	if sync_stream_index >= music_streams.size():
		print("Больше нечего добавлять")
		return

	tween.tween_method(
		_change_volume_of_synced_stream.bind(sync_stream_index), 
		-80.0, 
		0.0, 
		layer_fade_in_time_sec
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	if sync_stream_index == 5:
		tween.tween_method(
			_change_volume_of_synced_stream.bind(sync_stream_index - 1), 
			0.0,
			-80.0, 
			layer_fade_in_time_sec
		).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

func stop_music():
	music_player.stop()

func fade_out_music():
	var tween = get_tree().create_tween() 
	tween.tween_property(music_player, "volume_linear", 0, ending_fade_time_sec)


func change_sfx_volume(volume: float) -> void:
	sfx_volume_ln = volume
	bus_index = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_linear(bus_index, volume / 100)

func change_music_volume(volume: float) -> void:
	music_volume_ln = volume
	bus_index = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_linear(bus_index, volume / 100)

func _change_volume_of_synced_stream(volume: float, index: int) -> void:
	sync_stream.set_sync_stream_volume(index, volume)
