extends Node
## Audio for the start page: the title theme and the presses that leave it.
## The campaign rack is not used here because there is no run to observe yet.
const Music = preload("res://presentation/campaign_music.gd")
const CLICKS = {
	"ui_select": preload("res://art/audio/campaign-v002/ui_select.wav"),
	"ui_confirm": preload("res://art/audio/campaign-v002/ui_confirm.wav"),
}

signal cue_requested(kind: String)

@export_range(-40.0, 0.0, 1.0) var volume_db: float = -10.0
var enabled := true:
	set(value):
		enabled = value
		if music != null: music.enabled = value
		if not enabled and is_instance_valid(_voice): _voice.stop()
var effects_volume := 0.8
var music: Node
var _voice: AudioStreamPlayer

func _ready() -> void:
	music = Music.new()
	music.name = "Music"
	add_child(music)
	_voice = AudioStreamPlayer.new()
	_voice.bus = "UI"
	add_child(_voice)
	set_process(true)

func apply(levels: Dictionary) -> void:
	music.volume = float(levels.get("music", 0.4))
	effects_volume = float(levels.get("effects", 0.8))
	enabled = not bool(levels.get("muted", false))

func _process(seconds: float) -> void:
	if is_instance_valid(music): music.observe(seconds, null, 0.0, false)

func click(kind: String) -> void:
	if not enabled or effects_volume <= 0 or not CLICKS.has(kind): return
	_voice.stream = CLICKS[kind]
	_voice.volume_db = volume_db + linear_to_db(maxf(0.0001, effects_volume))
	if DisplayServer.get_name() != "headless": _voice.play()
	cue_requested.emit(kind)

func _exit_tree() -> void:
	if is_instance_valid(music): music.stop()
	if is_instance_valid(_voice): _voice.stream = null
