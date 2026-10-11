extends Control
## Observes real upgrades; never persists celebrations or changes the simulation.
const Progress = preload("res://application/settlement_progress.gd")
const Icons = preload("res://presentation/ui_icons.gd")
@export var style: Resource = preload("res://data/settlement_feedback.tres")
var caption: Label
var detail: Label
var _session: RefCounted
var _highest: int = 0
var _stage: Dictionary = {}
var _born: float = 0.0
var _age: float = 0.0
var _safe: Rect2
var _bounds: Rect2
var _plate: StyleBoxFlat
var _alpha: float = 0.0
var _sample_at: float = -1.0
var _danger: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate = StyleBoxFlat.new()
	_plate.bg_color = Color(0.035,0.08,0.10,0.9)
	_plate.border_color = Color(style.gold,0.7)
	_plate.border_width_top = 2
	_plate.border_width_bottom = 1
	caption = _label(22,style.gold)
	detail = _label(16,Color("d0e0d6"))
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

func current_level() -> int:
	return int(_stage.get("level",0))

func caption_bounds() -> Rect2:
	return _bounds if visible and caption.visible else Rect2()

func present(sim: RefCounted, safe: Rect2, paused: bool, reserved: Rect2, priority_warning: bool) -> void:
	_safe = safe
	if _session != sim:
		_session = sim
		_highest = sim.frontier.city_level
		_stage = {}
		_sample_at = -1.0
	var now: float = sim.workforce.elapsed
	if sim.frontier.city_level > _highest:
		_highest = sim.frontier.city_level
		# Lighting the first fire already has its own sword-drawing ceremony.
		if sim.life.enabled and _highest > 1:
			_stage = Progress.read(sim).stages[_highest-1]
			_born = now
	_age = maxf(0,now-_born)
	visible = not paused and sim.life.enabled and sim.is_running() and not _stage.is_empty() and _age < style.duration
	if not visible:return
	if _sample_at < 0 or now-_sample_at >= style.refresh_seconds:
		_sample_at = now
		_danger = sim.raiders.any(func(enemy: Dictionary) -> bool:
			return enemy.fighter.is_alive() and absf(enemy.x-sim._hero_x)<style.danger_distance)
	caption.visible = not priority_warning and not _danger
	detail.visible = caption.visible
	_alpha = smoothstep(0,style.fade_seconds,_age)*(1-smoothstep(style.duration-style.fade_seconds,style.duration,_age))
	caption.modulate.a = _alpha
	detail.modulate.a = _alpha
	caption.text = tr(_stage.title)
	detail.text = tr(_stage.detail)
	var width: float = minf(530,safe.size.x-44)
	var top: float = safe.position.y+38
	if reserved.has_area():top=maxf(top,reserved.end.y+10)
	_bounds = Rect2(Vector2(safe.get_center().x-width/2,top),Vector2(width,108))
	caption.position = _bounds.position+Vector2(42,12)
	caption.size = Vector2(width-84,30)
	detail.position = _bounds.position+Vector2(18,50)
	detail.size = Vector2(width-36,48)
	queue_redraw()

func _draw() -> void:
	if _stage.is_empty():return
	if caption.visible:
		_plate.bg_color.a = _alpha*0.88
		_plate.border_color.a = _alpha*0.65
		draw_style_box(_plate,_bounds)
		for rank: int in range(3):
			var color: Color = style.gold if rank < current_level() else Color("385457")
			color.a = _alpha
			draw_rect(Rect2(_bounds.position+Vector2(12+rank*8,16),Vector2(4,20)),color)
		draw_texture_rect(Icons.get_icon(_stage.icon),Rect2(_bounds.end-Vector2(38,96),Vector2(24,24)),false,Color(style.glow,_alpha))
	_draw_conduits()

func _draw_conduits() -> void:
	if _age > style.pulse_seconds:return
	var transform: Transform2D = get_viewport().get_canvas_transform()
	var origin: Vector2 = transform*Vector2(_session.world.sites.hall,433)
	var progress: float = clampf(_age/style.pulse_seconds,0,1)
	var fade: float = 1-smoothstep(0.7,1,progress)
	for target: float in _stage.locations:
		var end: Vector2 = transform*Vector2(target,433)
		var head: Vector2 = origin.lerp(end,smoothstep(0.0,0.68,progress))
		var direction: float = signf(end.x-origin.x)
		for dot: int in range(18):
			var at: Vector2 = (head-Vector2(direction*dot*5,0)).round()
			if _safe.has_point(at):
				draw_rect(Rect2(at,Vector2(4,2)),Color(style.glow,fade*(1-dot/18.0)))
		var arrival: float = smoothstep(0.55,0.72,progress)*fade
		if _safe.grow(36).has_point(end) and arrival>0:
			for ray: int in range(8):
				var at: Vector2=(end+Vector2(cos(ray*TAU/8)*18,sin(ray*TAU/8)*12-26)).round()
				draw_rect(Rect2(at,Vector2(3,3)),Color(style.gold,arrival))
