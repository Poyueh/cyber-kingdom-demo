extends Node2D
## Observe confirmed sword-hit records; do not infer contact from animation.
const Style = preload("res://data/sword_feedback_tuning.gd")
const CAMERA_LIFETIME: float = 0.18
const SPARK_COUNT: int = 9
class Contact extends RefCounted:
	var at: Vector2
	var facing: int
	var heavy: bool
	var age: float = 0.0
	var lifetime: float
var style: Style
var camera: Camera2D
var _contacts: Array[Contact] = []
# Read-only references to application effect records, bounded by their lifetimes.
var _seen: Array[Dictionary] = []
var _stop: float = 0.0
var _kick_age: float = CAMERA_LIFETIME
var _kick: Vector2 = Vector2.ZERO

func reset(effects: Array[Dictionary]) -> void:
	_seen.assign(effects)
	_contacts.clear()
	_stop = 0.0
	_kick_age = CAMERA_LIFETIME
	_kick = Vector2.ZERO
	if is_instance_valid(camera): camera.offset = Vector2.ZERO
	queue_redraw()

## Called only while the game is unpaused. UI and input keep their own clocks.
func advance(seconds: float) -> float:
	if seconds <= 0: return 0.0
	for index: int in range(_contacts.size()-1,-1,-1):
		_contacts[index].age += seconds
		if _contacts[index].age >= _contacts[index].lifetime: _contacts.remove_at(index)
	_kick_age = minf(CAMERA_LIFETIME,_kick_age+seconds)
	_present_camera()
	queue_redraw()
	var held: float = minf(_stop,seconds)
	_stop = maxf(0,_stop-seconds)
	return seconds-held

func observe(effects: Array[Dictionary], knight_at: Vector2) -> void:
	for effect: Dictionary in effects:
		# Arrow impacts also use 'hit', but never carry the sword's heavy field.
		if effect.kind != "hit" or not effect.has("heavy"): continue
		if _seen.any(func(old: Dictionary) -> bool: return is_same(old,effect)): continue
		var heavy: bool = effect.heavy
		var facing: int = effect.facing
		var contact: Contact = Contact.new()
		contact.at = Vector2(clampf(effect.x,knight_at.x-80,knight_at.x+80),knight_at.y-23)
		contact.facing = facing
		contact.heavy = heavy
		contact.lifetime = style.heavy_lifetime if heavy else style.light_lifetime
		if _contacts.size() >= style.max_contacts: _contacts.pop_front()
		_contacts.append(contact)
		# Hitting a group produces one stop, never a stop multiplied by enemies.
		_stop = maxf(_stop,style.heavy_stop if heavy else style.light_stop)
		var strength: float = style.heavy_kick if heavy else style.light_kick
		_kick = Vector2(-facing*strength,-strength*0.3)
		_kick_age = 0.0
	_seen.assign(effects)
	_present_camera()
	queue_redraw()

func _present_camera() -> void:
	if not is_instance_valid(camera): return
	var progress: float = clampf(_kick_age/CAMERA_LIFETIME,0,1)
	camera.offset = _kick * cos(progress*PI*2.5) * pow(1-progress,2)
	if progress >= 1: camera.offset = Vector2.ZERO

func _draw() -> void:
	if style == null: return
	var viewport: Rect2 = get_viewport_rect().grow(70)
	for contact: Contact in _contacts:
		if not viewport.has_point(get_global_transform_with_canvas()*contact.at): continue
		var progress: float = contact.age/contact.lifetime
		var alpha: float = 1.0-progress
		var shade: Color = style.heavy_color if contact.heavy else style.trail_color
		var center: Vector2 = contact.at.round()
		if progress < 0.40:
			var radius: float = (14 if contact.heavy else 10)*(1-progress)
			var star: PackedVector2Array = PackedVector2Array()
			for index: int in range(8):
				var angle: float = index*PI/4+0.2*contact.facing
				star.append((center+Vector2.from_angle(angle)*(radius if index%2==0 else radius*0.24)).round())
			draw_colored_polygon(star,Color(style.core_color,alpha))
		for index: int in range(SPARK_COUNT):
			var angle: float = -1.25+index*2.5/(SPARK_COUNT-1)
			var ray: Vector2 = Vector2(cos(angle)*contact.facing,sin(angle))
			var distance: float = (10+index%3*7)*sqrt(progress)+(12 if contact.heavy else 4)*progress
			var at: Vector2 = (center+ray*distance+Vector2(0,12*progress*progress)).round()
			var tail: Vector2 = (at-ray*(5 if contact.heavy else 3)*(1-progress)).round()
			draw_line(tail,at,Color(shade,alpha),2 if index%3==0 else 1,false)
			draw_rect(Rect2(at,Vector2.ONE),Color(style.core_color,alpha))
