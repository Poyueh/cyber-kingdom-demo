extends Node
## Plays the continuous effect loops at the levels the chooser asks for.
const Cues = preload("res://presentation/campaign_loop_cues.gd")
const FADE := 0.45

@export_range(0.0, 1.0, 0.01) var volume: float = 0.8
var enabled := true:
	set(value):
		enabled = value
		if not enabled: stop()
var suspended := false
var cues = Cues.new()
var levels: Dictionary = {}
var _players: Dictionary = {}

func _ready() -> void:
	for loop in Cues.LOOPS:
		var path := "res://art/audio/campaign-v002/%s.wav" % loop
		if not ResourceLoader.exists(path): continue
		var stream: AudioStream = load(path)
		if stream is AudioStreamWAV:
			stream = stream.duplicate()
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_end = stream.data.size() / 2
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		player.stream = stream
		player.volume_db = linear_to_db(0.0001)
		add_child(player)
		_players[loop] = player
		levels[loop] = 0.0

func observe(seconds: float, sim, x: float, paused: bool) -> void:
	var silent: bool = not enabled or suspended or volume <= 0
	var wanted: Dictionary = cues.sample(sim, x, seconds, paused or silent)
	var step: float = seconds / FADE if FADE > 0 else 1.0
	for loop in _players:
		var target: float = wanted.get(loop, 0.0)
		var current: float = levels.get(loop, 0.0)
		levels[loop] = clampf(current + clampf(target - current, -step, step), 0.0, 1.0)
		var player: AudioStreamPlayer = _players[loop]
		player.volume_db = linear_to_db(maxf(0.0001, levels[loop] * volume))
		if levels[loop] <= 0.0:
			if player.playing: player.stop()
		elif not player.playing and DisplayServer.get_name() != "headless":
			player.play()

func stop() -> void:
	for loop in _players:
		levels[loop] = 0.0
		if is_instance_valid(_players[loop]): _players[loop].stop()

func _exit_tree() -> void:
	stop()
	for loop in _players:
		if is_instance_valid(_players[loop]): _players[loop].stream = null
	_players.clear()
	cues = null
