extends Node2D
const Session = preload("res://application/settlement_session.gd")
const Mapper = preload("res://bootstrap/tuning_mapper.gd")
@export var tuning: Resource = preload("res://data/settlement.tres")
@export var combo_tuning: Resource = preload("res://data/knight_combo.tres")
@export var knight_tuning: Resource = preload("res://data/knight.tres")
@onready var knight = $Knight
@onready var view = $WorldView
@onready var controls = $InputAdapter
@onready var hud = $HUD
var sim: Session
var paused := false
var _requested_interaction := false

func _ready() -> void:
	hud.interact_requested.connect(func(): _requested_interaction = true)
	hud.refuge_requested.connect(_leave)
	restart()

func restart() -> void:
	sim = Session.new({"scrap":tuning.starting_scrap,"crystals":tuning.starting_crystals,
		"first_raid":tuning.first_raid_seconds,"raid_gap":tuning.raid_gap_seconds,
		"person_speed":tuning.resident_speed,"shield_value":tuning.shield_per_crystal},Mapper.knight_stats(knight_tuning,combo_tuning))
	knight.configure(sim.hero,knight_tuning)
	knight.position = Vector2(150,430)
	paused = false
	_requested_interaction = false
	controls.release_all()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		paused = true
		if sim != null: sim.hero.clear_attack_buffer()
		_requested_interaction = false
		if is_instance_valid(controls): controls.release_all()

func _physics_process(seconds: float) -> void:
	var command: Dictionary = controls.read_frame()
	if hud.has_method("movement_axis") and command.direction==0:command.direction=hud.movement_axis()
	if command.restart:
		restart()
	if command.pause:
		paused = not paused
		sim.hero.clear_attack_buffer()
		_requested_interaction = false
		controls.release_all()
	if not paused:
		sim.advance(seconds,knight.position.x,knight.position.y)
		if sim.is_running():
			if command.direction != 0 and sim.hero.dash_remaining <= 0:
				sim.hero.facing = int(signf(command.direction))
			if command.attack and _can_attack(): sim.hero.start_attack()
			if command.dash: sim.hero.start_dash()
			_apply_interaction(command,seconds)
			knight.advance_motion(_travel_axis(command.direction,seconds),command.jump,seconds)
			sim.strike_from(knight.position.x,knight.position.y)
		knight.refresh_visual(seconds)
	_requested_interaction = false
	view.present(sim,knight.position.x)
	hud.present_world(sim,paused,knight.position.x,knight.is_on_floor())

func _travel_axis(direction: float, _seconds: float) -> float:return direction

func _apply_interaction(command: Dictionary, _seconds: float) -> void:
	if (command.interact or _requested_interaction) and knight.is_on_floor():
		sim.interact(knight.position.x)

func _leave() -> void:
	controls.release_all()
	get_tree().change_scene_to_file("res://scenes/training.tscn")

func _can_attack() -> bool:return true
