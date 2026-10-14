extends Control
## One transient ceremony for an observed claim; restoring a save never replays it.
const Progress = preload("res://application/voyage_progress.gd")
const Names = preload("res://presentation/star_map.gd").NAMES
const Icons = preload("res://presentation/ui_icons.gd")
@export var style: Resource = preload("res://data/planet_feedback.tres")
var caption: Label
var detail: Label
var _session: RefCounted
var _claimed: bool = false
var _celebrating: bool = false
var _planet: int = 0
var _cores: int = 0
var _routes: Array[int] = []
var _born: float = 0.0
var _age: float = 0.0
var _alpha: float = 0.0
var _safe: Rect2
var _bounds: Rect2
var _plate: StyleBoxFlat

func _ready() -> void:
	name = "Liberation"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate = StyleBoxFlat.new()
	_plate.bg_color = Color("091620")
	_plate.border_color = style.gold
	_plate.border_width_top = 2;_plate.border_width_bottom = 1
	caption = _label(23,style.gold)
	detail = _label(15,Color("cee1dd"))
	hide()

func _label(font_size: int, ink: Color) -> Label:
	var label: Label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font",preload("res://presentation/localized_font.gd").current())
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",ink)
	add_child(label)
	return label

func present(journey: RefCounted, sim: RefCounted, safe: Rect2, paused: bool, reserved: Rect2) -> void:
	_safe = safe
	if _session != sim:
		_session = sim;_claimed = sim.planet.core_claimed;_celebrating = false
	if sim.planet.core_claimed and not _claimed:
		_claimed = true;_celebrating = true;_born = sim.workforce.elapsed
		_planet = journey.current;_cores = 0
		for id: int in range(7):
			if journey.has_core(id,sim):_cores |= 1<<id
		_routes = Progress.newly_opened(journey,sim,_planet)
	_age = maxf(0,sim.workforce.elapsed-_born)
	visible = _celebrating and not paused and sim.is_running() and _age < style.duration
	if not visible:return
	_alpha = smoothstep(0,style.fade_seconds,_age)*(1-smoothstep(style.duration-style.fade_seconds,style.duration,_age))
	caption.modulate.a = _alpha;detail.modulate.a = _alpha
	caption.text = tr("planet.liberation %s")%tr(Names[_planet])
	var destinations: PackedStringArray = []
	for id: int in _routes:destinations.append(tr(Names[id]))
	detail.text = tr("planet.free_routes") if not destinations.is_empty() else tr("planet.keep_growing")
	var width: float = minf(580,safe.size.x-48)
	var top: float = maxf(safe.position.y+34,reserved.end.y+10 if reserved.has_area() else 0)
	_bounds = Rect2(Vector2(safe.get_center().x-width/2,top),Vector2(width,122))
	caption.position = _bounds.position+Vector2(18,10);caption.size = Vector2(width-36,32)
	detail.position = _bounds.position+Vector2(18,49);detail.size = Vector2(width-36,39)
	queue_redraw()

func _seal_at(id: int) -> Vector2:
	return Vector2(_bounds.get_center().x+(id-3)*26,_bounds.end.y-18)

func _draw() -> void:
	if not _celebrating:return
	_plate.bg_color.a = _alpha*0.87;_plate.border_color.a = _alpha*0.7
	draw_style_box(_plate,_bounds)
	for id: int in range(7):
		var at: Vector2 = _seal_at(id)
		var ink: Color = style.gold if _cores&(1<<id) else Color("334651")
		ink.a = _alpha
		if id == _planet and _age < style.flight_seconds:ink = Color("334651",_alpha)
		draw_colored_polygon(PackedVector2Array([at+Vector2(0,-7),at+Vector2(5,0),at+Vector2(0,7),at+Vector2(-5,0)]),ink)
	if _age >= style.flight_seconds:return
	var transform: Transform2D = get_viewport().get_canvas_transform()
	var origin: Vector2 = transform*Vector2(_session.world.sites.hall-215,389)
	var end: Vector2 = _seal_at(_planet)
	var progress: float = clampf(_age/style.flight_seconds,0,1)
	var at: Vector2 = origin.lerp(end,smoothstep(0,1,progress))-Vector2(0,sin(progress*PI)*40)
	if _safe.grow(24).has_point(at):
		for index: int in range(8):
			var angle: float = index*TAU/8+progress*2
			var spark: Vector2 = (at+Vector2(cos(angle),sin(angle))*16).round()
			draw_rect(Rect2(spark,Vector2(2,2)),Color(style.glow,_alpha*0.7))
		draw_texture_rect(Icons.get_icon("crystal"),Rect2(at-Vector2(12,12),Vector2(24,24)),false,Color(style.gold,_alpha))
