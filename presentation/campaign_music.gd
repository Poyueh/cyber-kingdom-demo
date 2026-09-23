extends Node
## Plays the score the cue chooser asks for. Tracks are loaded on demand so a phone
## never holds every piece in memory at once.
const Cues = preload("res://presentation/campaign_music_cues.gd")
const LOOPS := ["title", "day_explore", "day_refuge", "night_watch", "night_raid", "dragon_boss"]
const STINGS := ["victory_theme", "defeat_theme", "dawn_sting"]
const CROSSFADE := 2.0
const LAYER_FADE := 1.0
const PAUSE_DUCK_DB := -12.0

signal track_changed(name: String)

@export_range(0.0, 1.0, 0.01) var volume: float = 0.4
@export var enabled := true:
	set(value):
		enabled = value
		if not enabled: stop()
var suspended := false
var cues = Cues.new()
var current := ""
var layer := ""
var _players: Array[AudioStreamPlayer] = []
var _layer_player: AudioStreamPlayer
var _sting_player: AudioStreamPlayer
var _mix := 1.0
var _layer_mix := 0.0
var _cache: Dictionary = {}

func _ready() -> void:
	for index in range(2):
		var player := AudioStreamPlayer.new()
		player.bus = "Music"
		add_child(player)
		_players.append(player)
	_layer_player = AudioStreamPlayer.new(); _layer_player.bus = "Music"; add_child(_layer_player)
	_sting_player = AudioStreamPlayer.new(); _sting_player.bus = "Music"; add_child(_sting_player)

func _stream(name: String) -> AudioStream:
	if name.is_empty(): return null
	if not _cache.has(name):
		var folder := "res://art/audio/music-v002/%s.ogg" % name
		if not ResourceLoader.exists(folder): return null
		var stream: AudioStream = load(folder)
		if stream is AudioStreamOggVorbis:
			stream = stream.duplicate()
			stream.loop = name in LOOPS
		_cache[name] = stream
	return _cache[name]

func observe(seconds: float, sim, x: float, paused: bool) -> void:
	var silent: bool = not enabled or suspended or volume <= 0
	_duck(paused)
	var wanted: Dictionary = cues.sample(sim, x, paused or silent)
	if silent:
		stop()
		return
	_advance_track(seconds, wanted.track)
	_advance_layer(seconds, wanted.layer)
	if not wanted.sting.is_empty(): _play_sting(wanted.sting)

func _duck(paused: bool) -> void:
	var bus := AudioServer.get_bus_index("Music")
	if bus < 0: return
	AudioServer.set_bus_volume_db(bus, PAUSE_DUCK_DB if paused else 0.0)
	if AudioServer.get_bus_effect_count(bus) > 0:
		AudioServer.set_bus_effect_enabled(bus, 0, paused)

func _advance_track(seconds: float, wanted: String) -> void:
	if wanted != current:
		current = wanted
		_players.reverse()
		_players[0].stream = _stream(wanted)
		_mix = 0.0
		if _players[0].stream != null and not _headless(): _players[0].play()
		track_changed.emit(wanted)
	_mix = minf(1.0, _mix + (seconds / CROSSFADE if CROSSFADE > 0 else 1.0))
	_players[0].volume_db = _gain(volume * _mix)
	_players[1].volume_db = _gain(volume * (1.0 - _mix))
	if _mix >= 1.0 and _players[1].playing: _players[1].stop()
	if current.is_empty() and _players[0].playing: _players[0].stop()

func _advance_layer(seconds: float, wanted: String) -> void:
	if wanted != layer:
		layer = wanted
		if not layer.is_empty():
			_layer_player.stream = _stream(layer)
			if _layer_player.stream != null and not _headless(): _layer_player.play()
	var target := 1.0 if not layer.is_empty() else 0.0
	var step: float = seconds / LAYER_FADE if LAYER_FADE > 0 else 1.0
	_layer_mix = clampf(_layer_mix + (step if target > _layer_mix else -step), 0.0, 1.0)
	_layer_player.volume_db = _gain(volume * _layer_mix)
	if _layer_mix <= 0.0 and _layer_player.playing: _layer_player.stop()

func _play_sting(name: String) -> void:
	_sting_player.stream = _stream(name)
	_sting_player.volume_db = _gain(volume)
	if _sting_player.stream != null and not _headless(): _sting_player.play()

func _gain(level: float) -> float:
	return linear_to_db(maxf(0.0001, level))

func _headless() -> bool:
	return DisplayServer.get_name() == "headless"

func stop() -> void:
	for player in _players:
		if is_instance_valid(player): player.stop()
	if is_instance_valid(_layer_player): _layer_player.stop()
	if is_instance_valid(_sting_player): _sting_player.stop()
	current = ""
	layer = ""
	_mix = 1.0
	_layer_mix = 0.0

func _exit_tree() -> void:
	stop()
	for player in _players:
		if is_instance_valid(player): player.stream = null
	if is_instance_valid(_layer_player): _layer_player.stream = null
	if is_instance_valid(_sting_player): _sting_player.stream = null
	_cache.clear()
	cues = null
