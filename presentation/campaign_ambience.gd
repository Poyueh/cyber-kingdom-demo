extends Node
## Plays the ambience beds at the levels the cue chooser asks for, fading between them.
const Cues = preload("res://presentation/campaign_ambience_cues.gd")
const FADE := 1.8

@export_range(0.0, 1.0, 0.01) var volume: float = 0.6
@export var enabled := true:
	set(value):
		enabled = value
		if not enabled: stop()
var suspended := false
var cues = Cues.new()
var levels: Dictionary = {}
var _players: Dictionary = {}

func _ready() -> void:
	for bed in Cues.BEDS:
		var path := "res://art/audio/ambience-v002/%s.ogg" % bed
		if not ResourceLoader.exists(path):
			push_error("missing ambience bed: %s" % path)
			continue
		var stream: AudioStream = load(path)
		if stream is AudioStreamOggVorbis:
			stream = stream.duplicate()
			stream.loop = true
		var player := AudioStreamPlayer.new()
		player.bus = "Ambience"
		player.stream = stream
		player.volume_db = linear_to_db(0.0001)
		add_child(player)
		_players[bed] = player
		levels[bed] = 0.0

func observe(seconds: float, sim, x: float, paused: bool) -> void:
	var silent: bool = not enabled or suspended or volume <= 0
	var wanted: Dictionary = cues.sample(sim, x, paused or silent)
	var step: float = seconds / FADE if FADE > 0 else 1.0
	for bed in _players:
		var target: float = wanted.get(bed, 0.0)
		var current: float = levels.get(bed, 0.0)
		levels[bed] = clampf(current + clampf(target - current, -step, step), 0.0, 1.0)
		var player: AudioStreamPlayer = _players[bed]
		player.volume_db = linear_to_db(maxf(0.0001, levels[bed] * volume))
		if levels[bed] <= 0.0:
			if player.playing: player.stop()
		elif not player.playing and DisplayServer.get_name() != "headless":
			player.play()

func stop() -> void:
	for bed in _players:
		levels[bed] = 0.0
		if is_instance_valid(_players[bed]): _players[bed].stop()

func _exit_tree() -> void:
	stop()
	for bed in _players:
		if is_instance_valid(_players[bed]): _players[bed].stream = null
	_players.clear()
	cues = null
