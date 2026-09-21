extends "res://presentation/settlement_controls.gd"
signal new_map_requested
signal throw_requested
signal special_requested
signal loadout_requested
var _interaction_pressed: bool=false
func _unhandled_key_input(event: InputEvent) -> void:
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
	frame.direction=signf(frame.direction)*(1.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 0.65)
	return frame

func release_all() -> void:
	_interaction_pressed=false
	super.release_all()
