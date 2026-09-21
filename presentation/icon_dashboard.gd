extends Node2D
const Icons=preload("res://presentation/ui_icons.gd")
const Layout=preload("res://presentation/campaign_layout.gd")
var panels: Dictionary={}
var values: Dictionary={}
var immersive: bool=false
var health_ratio:=1.0
var phase_ratio:=1.0
var is_night:=false
var is_paused:=false
var pause_overlay:=true
var dead:=false
var victory:=false
var outcome_age:=0.0
var _previous_outcome:=""
var _font:=ThemeDB.fallback_font
var _panel_cache: StyleBoxFlat
func icon(key: String, at: Vector2, size: float=24, color:=Color.WHITE) -> void:
	draw_texture_rect(Icons.get_icon(key),Rect2(at-Vector2.ONE*size*0.5,Vector2.ONE*size),false,color)
func number(value: String, at: Vector2, color:=Color("e6e7d2"), size: int=15) -> void:
	draw_string(_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func _draw() -> void:
	if panels.is_empty():panels=Layout.arrange(get_viewport_rect()).panels
	if immersive:
		if (dead or victory) and not is_paused:_draw_outcome()
		return
	var at: Vector2=panels.health.position
	draw_style_box(_panel(),panels.health)
	icon("heart",at+Vector2(20,19),24)
	draw_rect(Rect2(at+Vector2(39,9),Vector2(80,6)),Color("303f48"))
	draw_rect(Rect2(at+Vector2(39,9),Vector2(80*health_ratio,6)),Color("dd8899"))
	number(str(values.get("hp",0)),at+Vector2(40,32),Color("e9cdcf"),13)
	icon("shield",at+Vector2(137,19),20)
	number("%d/%d" % [values.get("shield",0),values.get("shield_capacity",0)],at+Vector2(151,25),Color("a7e6dc"),13)
	if values.has("stamina"):
		var stamina_ratio:=clampf(float(values.stamina)/maxf(1,values.max_stamina),0,1)
		icon("dash",at+Vector2(12,49),15,Color("b8d89b"))
		draw_rect(Rect2(at+Vector2(26,44),Vector2(180,8)),Color("25363b"))
		draw_rect(Rect2(at+Vector2(26,44),Vector2(180*stamina_ratio,8)),Color("afd58b") if stamina_ratio>0.18 else Color("d7826d"))
	for key in ["crystal","wood","food","stone","herbs","scrap","damage"]:
		if not values.has(key):continue
		var rect: Rect2=panels[key]
		draw_style_box(_panel(),rect)
		var tint:=Color("f5b87c") if key=="crystal" and values.get("full",false) else Color("e3dfcc")
		icon("sword" if key=="damage" else key,rect.position+Vector2(15,18),23,tint)
		number(str(values[key]),rect.position+Vector2(31,24),tint,13)
	at=panels.day.position
	draw_style_box(_panel(),panels.day)
	icon("moon" if is_night else "sun",at+Vector2(24,17),22)
	draw_arc(at+Vector2(24,17),14,-PI/2,-PI/2+TAU*phase_ratio,40,Color("c5daab"),1.5)
	number(str(values.get("day",1)),at+Vector2(44,23))
	icon("survived",at+Vector2(101,17),21)
	number(str(values.get("survived",0)),at+Vector2(120,23))
	for side in ["left","right"]:
		var count: int=values.get("raid_"+side,0)
		if count<=0:continue
		var rect: Rect2=panels["raid_"+side]
		draw_style_box(_panel(),rect)
		icon(side,rect.position+Vector2(12,17),18,Color("ffbe89"))
		icon("sword",rect.position+Vector2(30,17),18,Color("ffbe89"))
		number(str(count),rect.position+Vector2(44,23),Color("ffd5a0"))
	_draw_mission()
	if values.has("dragon_hp"):
		var bar:=Rect2(panels.day.position+Vector2(-30,43),Vector2(260,34))
		draw_style_box(_panel(),bar)
		icon("dragon",bar.position+Vector2(18,17),26,Color("f0bdaf"))
		draw_rect(Rect2(bar.position+Vector2(40,12),Vector2(202,9)),Color("392a43"))
		draw_rect(Rect2(bar.position+Vector2(40,12),Vector2(202*float(values.dragon_hp)/values.dragon_max_hp,9)),Color("dd8c9c"))
	elif values.has("dragon_day") and not victory and not dead:
		var dragon_at: Vector2=panels.day.position+Vector2(24,54)
		icon("dragon",dragon_at,22,Color("c995b9"))
		number(str(values.dragon_day)+"+",dragon_at+Vector2(18,5),Color("decbb8"),13)
	if (dead or victory) and not is_paused:
		_draw_outcome()
	elif is_paused and pause_overlay:
		draw_style_box(_panel(),panels.overlay)
		icon("pause",panels.overlay.get_center(),44)
func _process(seconds: float) -> void:
	var outcome: String="victory" if victory else "defeat" if dead else ""
	if outcome!=_previous_outcome:
		outcome_age=0;_previous_outcome=outcome
	if not outcome.is_empty() and not is_paused:
		outcome_age=minf(4,outcome_age+seconds)
		queue_redraw()
func _draw_outcome() -> void:
	var viewport:=get_viewport_rect()
	var center: Vector2=panels.overlay.get_center()+Vector2(0,18)
	var reveal:=smoothstep(0.15,0.95,outcome_age)
	var ink:=Color("bdebbc") if victory else Color("f6aa9b")
	# Keep the last blow visible, then establish an unmistakable persistent result.
	draw_rect(viewport,Color(0.015,0.035,0.06,0.20*reveal))
	var card:=Rect2(center-Vector2(172,110),Vector2(344,220))
	var style:=StyleBoxFlat.new();style.bg_color=Color(0.025,0.055,0.075,0.9*reveal)
	style.border_color=Color(ink,0.8*reveal);style.set_border_width_all(2);style.set_corner_radius_all(10)
	draw_style_box(style,card)
	ink.a=reveal
	var emblem:=center+Vector2(0,-24)
	for i in range(12):
		var angle:=i*TAU/12.0
		var direction:=Vector2(cos(angle),sin(angle))
		draw_line(emblem+direction*57,emblem+direction*(65+6*sin(outcome_age*2+i)),Color(ink,0.55*reveal),3)
	icon("crown" if victory else "skull",emblem,94,ink)
	var reason: String="dragon" if victory else "camp" if values.get("defeat_reason","")=="core" else "heart"
	icon(reason,center+Vector2(-38,63),34,ink)
	icon("check" if victory else "skull",center+Vector2(0,63),28,ink)
	icon("survived",center+Vector2(49,63),25,ink)
	number(str(values.get("survived",0)),center+Vector2(67,70),ink,22)
	# Action controls stay at their existing safe-area positions above this panel.

func _draw_mission() -> void:
	if not values.has("core_hp"):return
	var at: Vector2=panels.core.position
	draw_style_box(_panel(),panels.core)
	icon("camp",at+Vector2(24,17),22)
	var ratio:=clampf(float(values.core_hp)/values.core_max_hp,0,1)
	var tint:=Color("f29594") if ratio<0.35 else Color("9fe1d7")
	draw_rect(Rect2(at+Vector2(43,9),Vector2(64,5)),Color("303f48"))
	draw_rect(Rect2(at+Vector2(43,9),Vector2(64*ratio,5)),tint)
	number(str(values.core_hp),at+Vector2(44,29),tint,12)
	var index:=0
	for rift in values.get("rifts",[]):
		var color:=Color("52626b")
		if rift.discovered:color=Color("bc98d4")
		if rift.ordered:color=Color("efc98b")
		if rift.sealed:color=Color("8ee2bb")
		icon("check" if rift.sealed else "rift",at+Vector2(123+index*30,17),20,color)
		index+=1
func _panel() -> StyleBoxFlat:
	if _panel_cache==null:
		_panel_cache=StyleBoxFlat.new()
		_panel_cache.bg_color=Color(0.035,0.075,0.10,0.78)
		_panel_cache.set_corner_radius_all(8)
	return _panel_cache
