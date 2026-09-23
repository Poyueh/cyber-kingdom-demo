extends Node2D
## Composition root: the only place that chooses concrete adapters and wires layers.
const Session = preload("res://application/training_session.gd")
const ArenaCues = preload("res://presentation/arena_audio_cues.gd")
const AudioPreferences = preload("res://infrastructure/audio_preferences.gd")
const FileStore = preload("res://infrastructure/json_progress_store.gd")
const Mapper = preload("res://bootstrap/tuning_mapper.gd")
@export var combo_tuning: Resource = preload("res://data/knight_combo.tres")
@export var knight_tuning: Resource = preload("res://data/knight.tres")
@export var sentinel_tuning: Resource = preload("res://data/sentinel.tres")
@export_range(0, 1000) var defeat_reward: int = 20
@export_group("Hit Feedback")
@export_range(0.0, 0.15, 0.005) var hit_stop_seconds: float = 0.025
@export_range(0.0, 4.0, 0.5) var impact_shake_pixels: float = 1.0
signal retreat_requested
var expedition_mode: bool = false
var _initial_scrap: int = 0
var _buffered_actions: Dictionary = {}
@onready var knight = $Knight
@onready var sentinel = $Sentinel
@onready var impacts = $Impacts
@onready var camera: Camera2D = $Knight/Camera2D
@onready var controls = $InputAdapter
@onready var hud = $HUD
@onready var audio = $ArenaAudio
var arena_cues = ArenaCues.new()
@export var audio_preferences_path: String = "user://audio.cfg"
var session: Session
var progress_path: String = "user://progress_v1.json"
var store: FileStore
var paused: bool = false

func _ready() -> void:
	if session == null:
		store = FileStore.new(progress_path)
		session = Session.new(Mapper.knight_stats(knight_tuning,combo_tuning), Mapper.enemy_stats(sentinel_tuning), store, defeat_reward)
	_initial_scrap = session.scrap
	hud.refuge_requested.connect(_visit_refuge)
	hud.configure_expedition(expedition_mode)
	session.hit_stop_seconds = hit_stop_seconds
	if not audio_preferences_path.is_empty():
		var levels: Dictionary = AudioPreferences.new(audio_preferences_path).read()
		audio.music_volume = 0.0
		audio.effects_volume = levels.effects
		audio.enabled = not levels.muted
	_reset_bodies()

func _reset_bodies() -> void:
	_buffered_actions.clear()
	impacts.clear()
	camera.offset = Vector2.ZERO
	knight.position = Vector2(150, 420)
	sentinel.position = Vector2(680, 420)
	knight.configure(session.hero, knight_tuning)
	sentinel.configure(session.enemy, sentinel_tuning)
	controls.release_all()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		paused = true
		if session != null: session.hero.clear_attack_buffer()
		_buffered_actions.clear()
		if is_instance_valid(controls):
			controls.release_all()

func _physics_process(seconds: float) -> void:
	var command: Dictionary = controls.read_frame()
	if command.pause:
		paused = not paused
		session.hero.clear_attack_buffer()
		_buffered_actions.clear()
		controls.release_all()
	if command.retry_save:
		session.retry_save()
	if command.restart and expedition_mode:
		retreat_requested.emit()
		return
	if command.restart:
		session.restart_encounter()
		paused = false
		_reset_bodies()
	if not paused:
		_tick_encounter(seconds, command)
	hud.present({"hp": session.hero.hp, "shield": session.hero.shield, "max_hp": session.hero.stats.max_hp,
		"stamina": int(session.hero.stamina), "scrap": session.scrap - _initial_scrap if expedition_mode else session.scrap,
		"dead": not session.hero.is_alive(), "victory": not session.enemy.is_alive(),
		"paused": paused, "warning": store.last_error if store != null and not store.last_error.is_empty() else ("SAVE PENDING — press P to retry" if session.save_pending else "")})

func _tick_encounter(seconds: float, command: Dictionary) -> void:
	for action in ["jump", "attack", "dash"]:
		if command[action]:
			_buffered_actions[action] = true
	seconds = session.advance(seconds)
	if seconds <= 0.000001:
		return
	for action in ["jump", "attack", "dash"]:
		command[action] = _buffered_actions.get(action, false)
	_buffered_actions.clear()
	impacts.advance(seconds)
	if command.direction != 0.0 and session.hero.dash_remaining <= 0.0:
		session.hero.facing = int(signf(command.direction))
	if command.attack:
		session.hero.start_attack()
	if command.dash:
		session.hero.start_dash()
	var distance: Vector2 = knight.position - sentinel.position
	var enemy_direction: float = session.update_enemy_decision(seconds, distance.x, distance.y)
	knight.advance_motion(command.direction, command.jump, seconds)
	sentinel.advance_motion(enemy_direction, false, seconds)
	sentinel.telegraph = session.enemy_windup_remaining > 0.0
	distance = sentinel.position - knight.position
	if session.resolve_sword(distance.x, distance.y):
		impacts.trigger(sentinel.position + Vector2(0, -26), session.hero.attack_facing, Color("8ce9e1"))
	if session.resolve_enemy_sword(-distance.x, -distance.y):
		impacts.trigger(knight.position + Vector2(0, -26), session.enemy.attack_facing, Color("ffbd68"))
	camera.offset = impacts.camera_offset(impact_shake_pixels)
	knight.refresh_visual(seconds)
	sentinel.refresh_visual(seconds)
	_sound_the_duel(paused)

## The arena has two fighters and no world, so it reports its own combat.
func _sound_the_duel(is_paused: bool) -> void:
	if not is_instance_valid(audio): return
	for kind in arena_cues.sample(session.hero, session.enemy, session.enemy_windup_remaining, is_paused):
		audio.request(kind)

func _visit_refuge() -> void:
	controls.release_all()
	if expedition_mode:
		retreat_requested.emit()
	else:
		get_tree().change_scene_to_file("res://scenes/frontier.tscn")
