extends "res://presentation/settlement_controls.gd"
signal new_map_requested
signal throw_requested
signal special_requested
signal loadout_requested
const DesktopSettings=preload("res://data/desktop_control_settings.gd")
const SPRINT_KEYS: Array[int]=[KEY_A,KEY_D]
@export var desktop_settings: DesktopSettings=preload("res://data/desktop_controls.tres")
var _tap_window_ticks: int=0
var _tap_tick: int=-1
var _tap_key: int=0
var _sprint_key: int=0
var _held_keys: Dictionary[int,bool]={}
var _mouse_attack_pressed: bool=false
var mouse_exclusions: Array[Rect2]=[]
var _interaction_pressed: bool=false

func _ready() -> void:
	_tap_window_ticks=ceili(desktop_settings.double_tap_seconds*Engine.physics_ticks_per_second)

func _unhandled_input(event: InputEvent) -> void:
	# GUI controls consume their clicks first. Mobile emulation must never become a cut.
	if event is InputEventMouseButton and event.device!=InputEvent.DEVICE_ID_EMULATION:
		if event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
			for area: Rect2 in mouse_exclusions:
				if area.has_point(event.position):return
			_mouse_attack_pressed=true
			get_viewport().set_input_as_handled()

func _movement_key(event: InputEventKey) -> void:
	var code: int=event.physical_keycode
	if event.echo:return
	if not event.pressed:
		_held_keys.erase(code)
		if _sprint_key==code:_sprint_key=0;_tap_key=0
		return
	if _held_keys.has(code):return
	_held_keys[code]=true
	if _held_keys.size()>1:
		_sprint_key=0;_tap_key=0
		return
	var tick: int=Engine.get_physics_frames()
	_sprint_key=code if _tap_key==code and tick-_tap_tick<=_tap_window_ticks else 0
	_tap_tick=tick;_tap_key=code

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.physical_keycode in SPRINT_KEYS:_movement_key(event)
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_K,KEY_F]:
		if event.physical_keycode==KEY_K:special_requested.emit()
		else:loadout_requested.emit()
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_E:
		_interaction_pressed=true
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_Q:
		throw_requested.emit()
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_N:
		new_map_requested.emit()
		get_viewport().set_input_as_handled()

func read_frame() -> Dictionary:
	var frame := super.read_frame()
	frame["interaction_held"]=Input.is_physical_key_pressed(KEY_E)
	frame["interaction_pressed"]=_interaction_pressed
	_interaction_pressed=false
	# Held state is available even when just_pressed belongs to the next physics tick.
	frame["jump_held"]=false
	frame.jump=false;frame.dash=false
	for code: int in SPRINT_KEYS:
		if not Input.is_physical_key_pressed(code):_held_keys.erase(code)
	if _sprint_key!=0 and not Input.is_physical_key_pressed(_sprint_key):_sprint_key=0
	var fast: bool=(_sprint_key==KEY_A and frame.direction<0) or (_sprint_key==KEY_D and frame.direction>0)
	frame.direction=signf(frame.direction)*(1.0 if fast else 0.65)
	frame.attack=frame.attack or _mouse_attack_pressed
	_mouse_attack_pressed=false
	if frame.pause:
		release_all();frame.direction=0.0;frame.attack=false
	return frame

func release_all() -> void:
	_interaction_pressed=false
	_mouse_attack_pressed=false;_tap_key=0;_tap_tick=-1;_sprint_key=0;_held_keys.clear()
	super.release_all()
