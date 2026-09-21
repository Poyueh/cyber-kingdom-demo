extends "res://presentation/frontier_hud.gd"
const Options=preload("res://presentation/campaign_options.gd")
@export_enum("Automatic","Touch","Desktop") var control_mode:int=0
var options_menu: PanelContainer
const Guide=preload("res://application/campaign_guide.gd")
const ExpeditionGuide=preload("res://application/expedition_guide.gd")
@export var expedition_guidance:=true
const GuideView=preload("res://presentation/campaign_guide_view.gd")
@export var first_day_guidance:=true
var guide_view: Node2D
const Layout=preload("res://presentation/campaign_layout.gd")
@export var preview_safe_margins:=Vector4.ZERO
var _last_safe_rect:=Rect2()
const Icons=preload("res://presentation/ui_icons.gd")
const Dashboard=preload("res://presentation/icon_dashboard.gd")
signal audio_toggled
var audio_button: Button
signal save_requested
var save_button: Button
var _pause_icon_state:=false
signal throw_requested
var drop_button: Button
var interact_held := false
var focus_key := ""
var dashboard: Node2D
var fullscreen_button: Button
var drag_controls: Node2D
var _gesture_can_invest:=false
var immersive_feedback: Node2D

func _ready() -> void:
	super._ready()
	interact_button.action_mode=BaseButton.ACTION_MODE_BUTTON_PRESS
	interact_button.button_down.connect(func(): interact_held=true)
	interact_button.button_up.connect(func(): interact_held=false)
	$Top.hide()
	$Keys.hide()
	dashboard=Dashboard.new()
	dashboard.pause_overlay=false
	add_child(dashboard)
	# Keep input actions on TouchScreenButton for simultaneous movement and attacks.
	for key in ["move_left","move_right","dash","jump","attack","pause","restart"]:
		var button: TouchScreenButton=get_node(key)
		button.get_node("Fill").hide()
		button.get_node("Label").hide()
		var shape:=CircleShape2D.new()
		shape.radius=32
		button.shape=shape
		button.texture_normal=_button_texture({"move_left":"left","move_right":"right","attack":"sword"}.get(key,key))
		button.texture_pressed=button.texture_normal
		# The native texture origin is top-left, while the touch shape is centered.
		button.shape_centered=true
		button.modulate=Color(1,1,1,0.88)
	for pair in [[interact_button,"hand"],[new_map_button,"map"],[$Refuge,"sword"]]:
		_skin(pair[0],pair[1])
	fullscreen_button=Button.new()
	fullscreen_button.name="Fullscreen"
	add_child(fullscreen_button)
	_skin(fullscreen_button,"fullscreen")
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	drop_button=Button.new()
	drop_button.name="DropCrystal"
	add_child(drop_button)
	_skin(drop_button,"drop")
	drop_button.pressed.connect(func(): throw_requested.emit())
	save_button=Button.new()
	save_button.name="SaveStatus"
	add_child(save_button)
	_skin(save_button,"save")
	save_button.add_theme_stylebox_override("disabled",save_button.get_theme_stylebox("normal"))
	save_button.add_theme_color_override("icon_disabled_color",Color.WHITE)
	save_button.pressed.connect(func(): save_requested.emit())
	audio_button=Button.new()
	audio_button.name="AudioToggle"
	add_child(audio_button)
	_skin(audio_button,"sound")
	audio_button.pressed.connect(func():audio_toggled.emit())
	options_menu=Options.new()
	options_menu.name="OptionsMenu"
	add_child(options_menu)
	options_menu.hide()
	get_viewport().size_changed.connect(_layout)
	_layout()
	drag_controls=preload("res://presentation/drag_controls.gd").new()
	add_child(drag_controls)
	drag_controls.offering_started.connect(func():
		if _gesture_can_invest:
			interact_held=true
			interact_requested.emit()
		else:throw_requested.emit())
	drag_controls.offering_ended.connect(func():interact_held=false)
	immersive_feedback=preload("res://presentation/immersive_feedback.gd").new()
	add_child(immersive_feedback)
	guide_view=GuideView.new()
	add_child(guide_view)

func _button_texture(key: String) -> Texture2D:
	# SVG drawing remains editable and matches the resource and interaction symbols.
	var image:=Image.create(64,64,false,Image.FORMAT_RGBA8)
	image.fill(Color(0.04,0.09,0.12,0.72))
	var glyph:=Icons.get_icon(key).get_image()
	glyph.resize(32,32,Image.INTERPOLATE_LANCZOS)
	image.blend_rect(glyph,Rect2i(0,0,32,32),Vector2i(16,16))
	return ImageTexture.create_from_image(image)

func _skin(button: Button, key: String) -> void:
	button.text=""
	button.icon=Icons.get_icon(key)
	button.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER
	button.expand_icon=true
	button.add_theme_constant_override("icon_max_width",30)
	button.focus_mode=Control.FOCUS_NONE
	var style:=StyleBoxFlat.new()
	style.bg_color=Color(0.04,0.09,0.12,0.82)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	button.add_theme_stylebox_override("normal",style)
	var pressed:=style.duplicate()
	pressed.bg_color=Color(0.18,0.36,0.36,0.94)
	button.add_theme_stylebox_override("pressed",pressed)
	button.add_theme_stylebox_override("hover",pressed)

func safe_rect() -> Rect2:
	var viewport:=get_viewport().get_visible_rect()
	if preview_safe_margins!=Vector4.ZERO:
		var margins:=preview_safe_margins
		var result:=Rect2(viewport.position+Vector2(margins.x,margins.y),viewport.size-Vector2(margins.x+margins.z,margins.y+margins.w))
		return result.intersection(viewport) if result.has_area() else viewport
	if OS.has_feature("mobile"):
		return Layout.screen_to_canvas(viewport,get_viewport().get_screen_transform(),Rect2(DisplayServer.get_display_safe_area()))
	return viewport

func _process(_seconds: float) -> void:
	if safe_rect()!=_last_safe_rect:_layout()

func _layout() -> void:
	_last_safe_rect=safe_rect()
	var layout:=Layout.arrange(_last_safe_rect)
	for key in ["move_left","move_right","dash","jump","attack","pause","restart"]:
		get_node(key).position=layout.buttons[key].position
	var buttons={"drop":drop_button,"interact":interact_button,"new_map":new_map_button,"refuge":$Refuge,"fullscreen":fullscreen_button,"save":save_button,"audio":audio_button}
	for key in buttons:
		buttons[key].position=layout.buttons[key].position
		buttons[key].size=layout.buttons[key].size
	layout.panels.damage=Rect2(_last_safe_rect.position+Vector2(16,86),Vector2(72,38))
	dashboard.panels=layout.panels
	dashboard.queue_redraw()
	fullscreen_button.visible=not uses_touch_controls()
	if is_instance_valid(options_menu):
		options_menu.size=Vector2(minf(370,_last_safe_rect.size.x-24),244)
		options_menu.position=Vector2(_last_safe_rect.get_center().x-options_menu.size.x/2,minf(layout.buttons.new_map.end.y+8,_last_safe_rect.end.y-options_menu.size.y-12))

func present_world(sim, is_paused: bool, at: float, grounded: bool) -> void:
	if _pause_icon_state!=is_paused:
		_pause_icon_state=is_paused
		$pause.texture_normal=_button_texture("play" if is_paused else "pause")
		$pause.texture_pressed=$pause.texture_normal
	# No textual panel participates in the playable HUD.
	var choice: Dictionary=sim.context(at) if focus_key.is_empty() else sim.context_for_key(at,focus_key)
	interact_button.disabled=is_paused or not grounded or not choice.enabled or not sim.is_running()
	interact_button.icon=Icons.get_icon("chest" if choice.id=="chest" else "crystal" if choice.cost>0 else "hand")
	var touch:=uses_touch_controls()
	for action in ["move_left","move_right","jump","dash","attack"]:
		get_node(action).visible=touch and action=="attack" and not is_paused and sim.is_running()
	interact_button.visible=false
	drop_button.visible=false
	_gesture_can_invest=not interact_button.disabled and not (sim.life.enabled and choice.id=="recruit")
	var gestures_enabled: bool=touch and not is_paused and sim.is_running()
	if drag_controls.enabled and not gestures_enabled:drag_controls.cancel()
	drag_controls.enabled=gestures_enabled
	drag_controls.safe=_last_safe_rect
	drag_controls.exclusions.clear()
	for key in ["attack","jump","dash","pause"]:
		var button=get_node(key)
		if button.visible:drag_controls.exclusions.append(Rect2(button.position,Vector2(64,64)))
	drag_controls.queue_redraw()
	$attack.visible=$attack.visible and sim.can_wield_sword()
	for pair in [["attack",sim.hero.stats.attack_cost],["jump",sim.hero.stats.jump_cost],["dash",sim.hero.stats.dash_cost]]:
		get_node(pair[0]).modulate=Color(1,1,1,0.88 if sim.hero.stamina>=pair[1] else 0.3)
	options_menu.visible=is_paused
	$restart.visible=is_paused or not sim.is_running()
	new_map_button.visible=is_paused or not sim.is_running()
	$Refuge.visible=is_paused
	audio_button.visible=is_paused
	drop_button.disabled=is_paused or not sim.is_running() or sim.pouch.amount<=0
	var map=sim.frontier
	dashboard.immersive=sim.life.enabled
	immersive_feedback.present(sim,get_viewport().get_canvas_transform()*Vector2(at,sim._player_y),_last_safe_rect,is_paused)
	dashboard.values={"hp":sim.hero.hp,"shield":sim.hero.shield,"crystal":"%d/%d" % [sim.pouch.amount,sim.pouch.capacity],"day":sim.clock.day,"survived":sim.clock.survived,"full":sim.pouch.amount>=sim.pouch.capacity}
	var pressure: Dictionary=sim.raid_pressure()
	dashboard.values["damage"]=sim.hero.stats.damage
	dashboard.values["shield_capacity"]=sim.growth.capacity()
	dashboard.values["core_hp"]=sim.mission.core_hp
	dashboard.values["core_max_hp"]=sim.mission.core_max_hp
	dashboard.values["defeat_reason"]=sim.mission.defeat_reason
	dashboard.values["rifts"]=sim.mission.rifts
	dashboard.values["dragon_day"]=sim.mission.dragon_rules.baseline_day
	for enemy in sim.raiders:
		if enemy.get("kind","")=="dragon":
			dashboard.values["dragon_hp"]=enemy.fighter.hp
			dashboard.values["dragon_max_hp"]=enemy.fighter.stats.max_hp
	dashboard.values["raid_left"]=pressure.left
	dashboard.values["raid_right"]=pressure.right
	dashboard.values["stamina"]=sim.hero.stamina
	dashboard.values["max_stamina"]=sim.hero.stats.max_stamina
	dashboard.health_ratio=clampf(float(sim.hero.hp)/sim.hero.stats.max_hp,0,1)
	dashboard.phase_ratio=clampf(sim.clock.remaining/(sim.clock.night_seconds if sim.clock.is_night else sim.clock.day_seconds),0,1)
	dashboard.is_night=sim.clock.is_night
	dashboard.is_paused=is_paused
	dashboard.dead=sim.mission.outcome=="defeat"
	dashboard.victory=sim.mission.outcome=="victory"
	dashboard.queue_redraw()
	var advice: Dictionary=Guide.next(sim,at) if first_day_guidance and not is_paused else {}
	if advice.is_empty() and expedition_guidance and not is_paused:advice=ExpeditionGuide.next(sim,at,sim._player_y)
	if sim.life.enabled and sim.workforce.elapsed>150:advice={}
	var ready: bool=not advice.is_empty() and advice.action in ["invest","open"] and advice.key==choice.key and not interact_button.disabled
	guide_view.touch_hint=touch
	guide_view.present(advice,_last_safe_rect,at,Rect2(interact_button.position,interact_button.size),ready)
	guide_view.track(get_viewport().get_canvas_transform()*Vector2(at,sim._player_y),sim.workforce.elapsed)

func _toggle_fullscreen() -> void:
	var window:=get_window()
	window.mode=Window.MODE_WINDOWED if window.mode==Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN

func present_save(status: String, is_paused: bool) -> void:
	if not is_instance_valid(save_button):return
	save_button.visible=status!="disabled" and (is_paused or status in ["error","protected"])
	save_button.disabled=status=="protected"
	save_button.icon=Icons.get_icon("lock" if status=="protected" else "save_retry" if status=="error" else "save")
	save_button.modulate=Color("ffba78") if status in ["error","protected"] else Color("86d9cc")

func cancel_touch_gestures() -> void:
	# Release both action buttons' finger ownership and GUI buttons' press capture.
	if is_instance_valid(drag_controls):drag_controls.cancel()
	var buttons: Array=[interact_button,drop_button,new_map_button,$Refuge,fullscreen_button,save_button,audio_button]
	for key in ["move_left","move_right","dash","jump","attack","pause","restart"]:
		buttons.append(get_node(key))
	for button in buttons:
		if button.visible:
			button.hide()
			button.show()
	interact_held=false

func set_audio_enabled(value: bool) -> void:
	audio_button.icon=Icons.get_icon("sound" if value else "muted")

var _detected_touch: Variant=null
func uses_touch_controls() -> bool:
	var mode:=control_mode if control_mode!=0 else int(ProjectSettings.get_setting("campaign/control_preview",0))
	if mode!=0:return mode==1
	if _detected_touch==null:
		_detected_touch=OS.has_feature("mobile")
		if OS.has_feature("web"):
			# Engine touch emulation is also enabled on desktop; ask for real hardware.
			_detected_touch=bool(JavaScriptBridge.eval("navigator.maxTouchPoints > 0 && window.matchMedia('(pointer: coarse)').matches",true))
	return _detected_touch

func movement_axis() -> float:
	return drag_controls.state.axis if is_instance_valid(drag_controls) and drag_controls.enabled else 0.0
