extends Control
## Short, non-blocking warnings. Presentation history is discarded with the scene.
const Icons = preload("res://presentation/ui_icons.gd")
@export_range(4,12,1) var visible_seconds: float = 8.0
@export_range(0.05,0.5,0.05) var refresh_seconds: float = 0.15
var _sample_at: float = -1.0
var caption: Label
var _background: StyleBoxFlat
var _session: RefCounted
var _identity: String = ""
var _shown_at: float = 0.0
var _safe: Rect2
var _info: Dictionary = {}
var _age: float = 0.0

func _ready() -> void:
	_background=_plate()
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	caption=Label.new()
	caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
	caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_override("font",preload("res://presentation/localized_font.gd").current())
	caption.add_theme_font_size_override("font_size",19)
	caption.add_theme_color_override("font_color",Color("f6d6a5"))
	caption.add_theme_color_override("font_shadow_color",Color("121d29"))
	caption.add_theme_constant_override("shadow_offset_x",2)
	caption.add_theme_constant_override("shadow_offset_y",2)
	add_child(caption)

func present(sim: RefCounted, safe: Rect2, paused: bool, reserved: Rect2 = Rect2()) -> void:
	if _session!=sim:
		_session=sim;_identity="";_sample_at=-1.0
	_safe=safe
	if paused:
		visible=false
		return
	if _sample_at<0 or sim.workforce.elapsed-_sample_at>=refresh_seconds:
		_info=sim.night_watch();_sample_at=sim.workforce.elapsed
	visible=not _info.is_empty()
	if not visible:return
	var identity: String="%d:%s:%s"%[_info.day,_info.phase,_info.key]
	if identity!=_identity:
		_identity=identity;_shown_at=sim.workforce.elapsed
	_age=maxf(0,sim.workforce.elapsed-_shown_at)
	modulate.a=smoothstep(0,0.4,_age)*(1-smoothstep(visible_seconds-1,visible_seconds,_age))
	visible=_age<visible_seconds
	var top: float=safe.position.y+safe.size.y*0.17
	if reserved.has_area():top=maxf(top,reserved.end.y+12)
	caption.position=Vector2(safe.position.x+80,top)
	caption.size=Vector2(maxf(100,safe.size.x-160),64)
	caption.text=tr(_info.key)
	queue_redraw()

func _draw() -> void:
	if _info.is_empty():return
	var y: float=_safe.position.y+_safe.size.y*0.37
	for side: int in [-1,1]:
		if not _info.left and side<0 or not _info.right and side>0:continue
		var x: float=_safe.position.x+28 if side<0 else _safe.end.x-72
		var heavy: bool=_info.style==&"pressure" and _info.lead==side
		var color: Color=Color("ffc875") if heavy else Color("b9ced6")
		var pulse: float=0.82+sin(_age*3.5)*0.18
		draw_style_box(_background,Rect2(x-8,y-8,60,72))
		var homeward: bool=_info.style==&"home"
		draw_texture_rect(Icons.get_icon("camp" if homeward else "rift"),Rect2(x,y,44,44),false,Color(color, pulse))
		if homeward:
			var tip: Vector2=Vector2(x+22+side*26,y+22)
			draw_line(tip-Vector2(side*6,6),tip,color,2)
			draw_line(tip,tip-Vector2(side*6,-6),color,2)
		for mark: int in range(3 if heavy else 1):
			draw_rect(Rect2(x+10+mark*9,y+48,6,3),color)

func _plate() -> StyleBoxFlat:
	var plate:=StyleBoxFlat.new()
	plate.bg_color=Color(0.04,0.08,0.12,0.78)
	plate.border_color=Color(0.58,0.49,0.31,0.55)
	plate.set_border_width_all(1);plate.set_corner_radius_all(9)
	return plate
