extends "res://presentation/frontier_hud.gd"
const Options=preload("res://presentation/campaign_options.gd")
@export_enum("Automatic","Touch","Desktop") var control_mode:int=0
var core_hud: Control
var options_menu: PanelContainer
var exploration_map: PanelContainer
const Guide=preload("res://application/campaign_guide.gd")
const ExpeditionGuide=preload("res://application/expedition_guide.gd")
@export var expedition_guidance:=true
const Fullscreen=preload("res://presentation/fullscreen_switch.gd")
const GuideView=preload("res://presentation/campaign_guide_view.gd")
@export var first_day_guidance:=true
var guide_view: Node2D
const Layout=preload("res://presentation/campaign_layout.gd")
@export var preview_safe_margins:=Vector4.ZERO
var _last_safe_rect:=Rect2()
var _attack_home: Vector2=Vector2.ZERO
const ATTACK_SIZE: int=104
const ATTACK_HIT_RADIUS: float=58.0
var _tap_fill: TouchScreenButton
var _tap_shape: RectangleShape2D
const Icons=preload("res://presentation/ui_icons.gd")
const Dashboard=preload("res://presentation/icon_dashboard.gd")
signal special_requested
signal loadout_requested
signal module_selected(id: String)
signal loadout_closed
var module_menu: PanelContainer
var module_button: Button
var module_hint: Label
var _near_modules: bool=false
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
var night_watch_view: Control
var settlement_growth: Control

func _ready() -> void:
	super._ready()
	core_hud=preload("res://presentation/core_loop_hud.gd").new();add_child(core_hud)
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
		shape.radius=ATTACK_HIT_RADIUS if key=="attack" else 32
		button.shape=shape
		button.texture_normal=_button_texture({"move_left":"left","move_right":"right","attack":"sword","pause":"menu"}.get(key,key))
		if key=="attack":button.texture_normal=_button_texture("sword",ATTACK_SIZE,60)
		button.texture_pressed=preload("res://presentation/refuge_theme.gd").touch_texture({"move_left":"left","move_right":"right","attack":"sword","pause":"menu"}.get(key,key),ATTACK_SIZE if key=="attack" else 64,60 if key=="attack" else 32,true)
		# The native texture origin is top-left, while the touch shape is centered.
		button.shape_centered=true
		button.modulate=Color(1,1,1,0.88)
	for pair in [[interact_button,"hand"],[new_map_button,"map"],[$Refuge,"sword"]]:
		_skin(pair[0],pair[1])
	fullscreen_button=Button.new()
	fullscreen_button.name="Fullscreen"
	add_child(fullscreen_button)
	_skin(fullscreen_button,"fullscreen")
	# Pressed, not released: the web page needs the press to arm its own gesture switch.
	fullscreen_button.button_down.connect(func():Fullscreen.request(get_window()))
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
	audio_button.hide();new_map_button.hide();$restart.hide()
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
	drag_controls.special_requested.connect(func():special_requested.emit())
	module_button=Button.new();_skin(module_button,"gear");module_button.pressed.connect(func():loadout_requested.emit());add_child(module_button)
	module_hint=Label.new();module_hint.add_theme_font_override("font",preload("res://presentation/localized_font.gd").current())
	module_hint.add_theme_color_override("font_shadow_color",Color("07131ff0"));module_hint.add_theme_constant_override("shadow_offset_x",2);module_hint.add_theme_constant_override("shadow_offset_y",2)
	module_hint.add_theme_font_size_override("font_size",16);module_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	module_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;module_hint.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(module_hint)
	module_menu=preload("res://presentation/module_menu.gd").new();add_child(module_menu)
	module_menu.module_selected.connect(func(id: String):module_selected.emit(id))
	module_menu.closed.connect(func():loadout_closed.emit())
	immersive_feedback=preload("res://presentation/immersive_feedback.gd").new()
	add_child(immersive_feedback)
	_tap_fill=TouchScreenButton.new()
	_tap_shape=RectangleShape2D.new();_tap_fill.shape=_tap_shape
	_tap_fill.visibility_mode=TouchScreenButton.VISIBILITY_ALWAYS
	_tap_fill.pressed.connect(func():interact_requested.emit())
	add_child(_tap_fill)
	exploration_map=preload("res://presentation/exploration_map.gd").new();add_child(exploration_map)
	exploration_map.closed.connect(func():exploration_map.hide())
	guide_view=GuideView.new()
	add_child(guide_view)
	night_watch_view=preload("res://presentation/night_watch_view.gd").new();add_child(night_watch_view)
	settlement_growth=preload("res://presentation/settlement_growth_view.gd").new()
	settlement_growth.name="SettlementGrowth"
	add_child(settlement_growth)
	move_child(dashboard,get_child_count()-1)
	move_child($pause,get_child_count()-1)
	move_child(core_hud,get_child_count()-1)

func _button_texture(key: String, side: int=64, glyph_size: int=32) -> Texture2D:
	return preload("res://presentation/refuge_theme.gd").touch_texture(key,side,glyph_size)

func _skin(button: Button, key: String) -> void:
	button.theme=preload("res://presentation/refuge_theme.gd").make()
	button.text="";button.icon=Icons.get_icon(key)
	button.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER;button.expand_icon=true
	button.add_theme_constant_override("icon_max_width",28)
	button.focus_mode=Control.FOCUS_NONE

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
	if is_instance_valid(module_menu) and module_menu.visible:
		module_menu.arrange(_last_safe_rect)

func _layout() -> void:
	_last_safe_rect=safe_rect()
	var layout:=Layout.arrange(_last_safe_rect,dashboard.immersive)
	for key in ["move_left","move_right","dash","jump","attack","pause","restart"]:
		get_node(key).position=layout.buttons[key].position
	var buttons={"drop":drop_button,"interact":interact_button,"new_map":new_map_button,"refuge":$Refuge,"fullscreen":fullscreen_button,"save":save_button,"audio":audio_button}
	for key in buttons:
		buttons[key].position=layout.buttons[key].position
		buttons[key].size=layout.buttons[key].size
	layout.panels.damage=Rect2(_last_safe_rect.position+Vector2(16,86),Vector2(72,38))
	dashboard.panels=layout.panels
	dashboard.queue_redraw()
	$attack.position=_last_safe_rect.end-Vector2(ATTACK_SIZE+12,ATTACK_SIZE+12)
	_attack_home=$attack.position
	fullscreen_button.visible=_pause_icon_state and Fullscreen.available()
	if is_instance_valid(options_menu):
		options_menu.size=Vector2(minf(370,_last_safe_rect.size.x-24),244)
		options_menu.position=_last_safe_rect.position+Vector2(16,90) if dashboard.immersive else Vector2(_last_safe_rect.get_center().x-options_menu.size.x/2,minf(layout.buttons.new_map.end.y+8,_last_safe_rect.end.y-options_menu.size.y-12))

	_refresh_gesture_exclusions()

func _refresh_gesture_exclusions() -> void:
	if not is_instance_valid(drag_controls):return
	drag_controls.safe=_last_safe_rect
	drag_controls.exclusions.clear()
	if is_instance_valid(_tap_fill) and _tap_fill.visible:drag_controls.exclusions.append(Rect2(_tap_fill.position-_tap_shape.size/2,_tap_shape.size))
	for key in ["attack","jump","dash","pause"]:
		var button=get_node(key)
		if button.visible:
			var side: float=ATTACK_SIZE if key=="attack" else 64
			var margin: float=ATTACK_HIT_RADIUS-side/2 if key=="attack" else 0
			drag_controls.exclusions.append(Rect2(button.position-Vector2.ONE*margin,Vector2.ONE*(side+margin*2)))
	if is_instance_valid(module_button) and module_button.visible:
		drag_controls.exclusions.append(Rect2(module_button.position,module_button.size))
	if is_instance_valid(core_hud):drag_controls.exclusions.append_array(core_hud.exclusion_rects())
	drag_controls.queue_redraw()

func present_world(sim, is_paused: bool, at: float, grounded: bool) -> void:
	if dashboard.immersive!=sim.life.enabled:
		dashboard.immersive=sim.life.enabled
		_layout()
	if _pause_icon_state!=is_paused:
		_pause_icon_state=is_paused
		$pause.texture_normal=_button_texture("menu")
		$pause.texture_pressed=$pause.texture_normal
	# No textual panel participates in the playable HUD.
	var choice: Dictionary=sim.context(at) if focus_key.is_empty() else sim.context_for_key(at,focus_key)
	interact_button.disabled=is_paused or not grounded or not choice.enabled or not sim.is_running()
	interact_button.icon=Icons.get_icon("chest" if choice.id in ["chest","trail_cache"] else "crystal" if choice.cost>0 else "hand")
	_tap_fill.visible=sim.life.enabled and not is_paused and grounded and choice.enabled and choice.paid>0 and choice.cost>choice.paid
	if _tap_fill.visible:
		var y: float=430-(184 if choice.id=="rift" else 141)
		if choice.id=="tower":y-=90
		elif choice.has("wall_id"):y-=50
		var canvas: Transform2D=get_viewport().get_canvas_transform()
		_tap_fill.position=canvas*Vector2(choice.x,y+22)
		_tap_shape.size=Vector2(maxf(96,choice.cost*23+48),90)*canvas.get_scale().abs()
	var touch:=uses_touch_controls()
	$attack.position=_attack_home
	for action in ["move_left","move_right","jump","dash","attack"]:
		get_node(action).visible=touch and action=="attack" and not is_paused and sim.is_running()
	interact_button.visible=false
	drop_button.visible=false
	_gesture_can_invest=not interact_button.disabled and not (sim.life.enabled and choice.id=="recruit")
	var finishing_steps: bool=sim.life.enabled and sim.mission.outcome=="defeat" and sim.mission.defeat_reason=="core" and dashboard.outcome_age<preload("res://data/outcome_direction.tres").message_start
	var gestures_enabled: bool=touch and not is_paused and (sim.is_running() or finishing_steps)
	if drag_controls.enabled and not gestures_enabled:drag_controls.cancel()
	drag_controls.enabled=gestures_enabled
	drag_controls.fast_available=not sim.travel.exhausted
	$attack.visible=$attack.visible and sim.can_wield_sword()
	for pair in [["attack",sim.hero.stats.attack_cost],["jump",sim.hero.stats.jump_cost],["dash",sim.hero.stats.dash_cost]]:
		get_node(pair[0]).modulate=Color(1,1,1,0.88 if sim.hero.stamina>=pair[1] else 0.3)
	fullscreen_button.visible=is_paused and Fullscreen.available()
	if not is_paused:exploration_map.hide()
	if exploration_map.visible:exploration_map.fit(_last_safe_rect)
	options_menu.visible=is_paused and not module_menu.visible and not exploration_map.visible
	$restart.visible=false
	new_map_button.visible=false
	$Refuge.visible=false # Standalone combat arena is no longer a player mode.
	audio_button.visible=false
	_present_modules(sim,at,is_paused,touch)
	_refresh_gesture_exclusions()
	drop_button.disabled=is_paused or not sim.is_running() or sim.pouch.amount<=0
	var map=sim.frontier
	dashboard.immersive=sim.life.enabled
	immersive_feedback.present(sim,get_viewport().get_canvas_transform()*Vector2(at,sim._player_y),_last_safe_rect,is_paused)
	night_watch_view.present(sim,_last_safe_rect,is_paused,immersive_feedback.day_caption_bounds())
	settlement_growth.present(sim,_last_safe_rect,is_paused,immersive_feedback.day_caption_bounds(),night_watch_view.visible)
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
	dashboard.rocket_finale=sim.planet.finale and sim.planet.completed
	dashboard.queue_redraw()
	$pause.visible=not (sim.life.enabled and dashboard.camp_transition())
	core_hud.present(sim,_last_safe_rect,is_paused,choice,not dashboard.camp_transition(),get_viewport().get_canvas_transform()*Vector2(at,sim._player_y),immersive_feedback.purse.bounds)
	var advice: Dictionary={}
	if not is_paused and (first_day_guidance or expedition_guidance):
		if sim.life.enabled:advice=sim.spirit.advice(sim,at,first_day_guidance,expedition_guidance)
		else:
			if first_day_guidance:advice=Guide.next(sim,at)
			if advice.is_empty() and expedition_guidance:advice=ExpeditionGuide.next(sim,at,sim._player_y)
	guide_view.modulate.a=1.0 if advice.get("core",false) else sim.spirit.opacity(int(sim.workforce.elapsed*sim.spirit.TICKS_PER_SECOND)) if sim.life.enabled else 1.0
	var ready: bool=not advice.is_empty() and advice.action in ["invest","open"] and advice.key==choice.key and not interact_button.disabled
	guide_view.target_cost=int(choice.cost) if ready else 0
	guide_view.reserved_regions=core_hud.exclusion_rects()
	for control: Control in [module_button,core_hud.interaction,core_hud.wallet,core_hud.wallet_icon,core_hud.stamina]:
		if control.is_visible_in_tree():guide_view.reserved_regions.append(control.get_global_rect())
	for button: TouchScreenButton in [$attack,$pause]:
		if button.is_visible_in_tree():guide_view.reserved_regions.append(Rect2(button.position,button.texture_normal.get_size()))
	guide_view.touch_hint=touch
	guide_view.reserved_caption=immersive_feedback.day_caption_bounds()
	var growth_bounds: Rect2=settlement_growth.caption_bounds()
	if growth_bounds.has_area():
		guide_view.reserved_caption=guide_view.reserved_caption.merge(growth_bounds) if guide_view.reserved_caption.has_area() else growth_bounds
	guide_view.present(advice,_last_safe_rect,at,Rect2(interact_button.position,interact_button.size),ready)
	guide_view.track(get_viewport().get_canvas_transform()*Vector2(at,sim._player_y),sim.workforce.elapsed)
	if sim.core_loop.enabled:
		if sim.core_loop.trial or sim.core_loop.stage<3:
			night_watch_view.hide();settlement_growth.hide();module_hint.hide()
		if core_hud.panel.visible:options_menu.hide()
	options_menu.set_core_trial(sim.core_loop.trial)
	if not sim.is_running():
		for overlay: CanvasItem in [immersive_feedback,night_watch_view,settlement_growth,module_hint,guide_view]:overlay.hide()

func _present_modules(sim: RefCounted, at: float, is_paused: bool, touch: bool) -> void:
	_near_modules=sim.can_use_module_station(at)
	module_button.visible=_near_modules and not is_paused
	module_button.position=Vector2(_last_safe_rect.get_center().x-30,_last_safe_rect.end.y-82);module_button.size=Vector2(60,60)
	module_menu.arrange(_last_safe_rect)
	if module_menu.visible:module_menu.present(sim.modules,touch,sim.pouch.amount)
	var message: String=preload("res://presentation/ruin_reward_hint.gd").nearby(self,sim,at,touch)
	if _near_modules and not is_paused:message=tr("點齒輪選配特殊部件") if touch else tr("按 F 選配特殊部件")
	for effect in sim.effects:
		if effect.kind=="module_pickup":continue # Presented last: a milestone must not cover the ability.
		elif effect.kind=="module_milestone":message=tr("module.milestone %s")%tr("module.rank.%d"%effect.count)
		elif effect.kind=="mount_recovered":message=tr("reward.horse.recovered")+"\n"+tr("reward.horse.cost %d")%sim.mount_quest.cost
		elif effect.kind=="mount_warning":message=tr("遺跡甦醒驚動了雙門。準備城防，襲擊將在夜裡到來。")
		elif effect.kind=="mount_assault":message=tr("雙門湧動！騎上戰馬支援兩側防線。")
		elif effect.kind=="mount_recovery":message=tr("攻勢暫緩。修復城牆，再深入荒野。")
		elif effect.kind=="module_stored":message=tr("部件已入庫，可以選配安裝。")
		elif effect.kind=="module_equipped":message=tr("雙指向上滑使用已裝部件") if touch else tr("按 K 使用已裝部件；F 開啟選配")
	for effect: Dictionary in sim.effects:
		if effect.kind=="module_pickup":message=preload("res://presentation/ruin_reward_hint.gd").pickup(self,effect.module,touch)
	module_hint.text=message;module_hint.visible=not message.is_empty() and not is_paused
	var hint_width: float=minf(680,_last_safe_rect.size.x-48)
	module_hint.size=Vector2(hint_width,90)
	module_hint.position=Vector2(_last_safe_rect.get_center().x-hint_width/2,_last_safe_rect.end.y-184)
	if module_menu.visible:
		for button in [fullscreen_button,save_button,audio_button,new_map_button,$restart]:button.hide()

func present_save(status: String, is_paused: bool) -> void:
	if not is_instance_valid(save_button):return
	save_button.visible=status!="disabled" and (is_paused or status in ["error","protected"]) and not module_menu.visible
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
