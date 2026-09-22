extends "res://bootstrap/settlement_root.gd"
const FrontierSession = preload("res://application/campaign_session.gd")
const InvestmentHold = preload("res://application/investment_hold.gd")
const CampaignProgress=preload("res://application/campaign_progress.gd")
const AudioPreferences=preload("res://infrastructure/audio_preferences.gd")
const CampaignStore=preload("res://infrastructure/json_campaign_store.gd")
@export var campaign_save_path: String="user://campaign_v1.json"
@export var audio_preferences_path: String="user://audio.cfg"
var preferences: RefCounted
var manual_progress: RefCounted
var _manual_available:=false
@export_range(1.0,60.0,1.0) var autosave_seconds: float=20.0
@onready var audio=$CampaignAudio
var progress: RefCounted
var _campaign_config: Dictionary={}
var _save_elapsed:=0.0
var investment: RefCounted
var _map_seed: int
var _seed_initialized := false
var _requested_new_map := false
var _terrain: Node2D
var _requested_throw := false
@export var ambience: Resource=preload("res://data/world_ambience.gd").new()
var _water: Node2D
var _lantern: Node2D
var _sunbeams: Node2D
var _requested_special: bool=false

func _ready() -> void:
	if get_tree().has_meta("campaign_launch"):
		var launch: Dictionary=get_tree().get_meta("campaign_launch")
		get_tree().remove_meta("campaign_launch")
		campaign_save_path=launch.path
		if launch.seed>=0:
			tuning=tuning.duplicate()
			tuning.map_seed=launch.seed
	super._ready()
	hud.audio_toggled.connect(func():
		audio.enabled=not audio.enabled
		hud.set_audio_enabled(audio.enabled))
	hud.set_audio_enabled(audio.enabled)
	_water=preload("res://presentation/water_reflection.gd").new();_water.style=ambience;add_child(_water)
	_lantern=preload("res://presentation/knight_lantern.gd").new();_lantern.style=ambience;add_child(_lantern)
	_sunbeams=preload("res://presentation/sunbeams.gd").new();_sunbeams.strength=ambience.sunbeam_strength;add_child(_sunbeams)
	view.crystal_radius=tuning.crystal_radius
	hud.throw_requested.connect(func(): _requested_throw = true)
	controls.mouse_exclusions=hud.drag_controls.exclusions
	controls.throw_requested.connect(func(): _requested_throw = true)
	controls.special_requested.connect(func():_requested_special=true)
	hud.special_requested.connect(func():_requested_special=true)
	controls.loadout_requested.connect(_open_loadout)
	hud.loadout_requested.connect(_open_loadout)
	hud.loadout_closed.connect(_close_loadout)
	hud.module_selected.connect(func(id: String):
		if sim.equip_module(id,knight.position.x):hud.module_menu.present(sim.modules,hud.uses_touch_controls()))
	$Knight/Camera2D.zoom=Vector2.ONE*tuning.camera_zoom
	# Browser canvas dimensions and pointer coordinates must remain browser-owned.
	if tuning.larger_desktop_window and DisplayServer.get_name()!= "headless" and not OS.has_feature("mobile") and not OS.has_feature("web"):
		var window:=get_window()
		var usable:=DisplayServer.screen_get_usable_rect()
		window.size=Vector2i(mini(1440,usable.size.x-60),mini(810,usable.size.y-60))
		window.position=usable.position+(usable.size-window.size)/2
	hud.new_map_requested.connect(func(): _requested_new_map = true)
	controls.new_map_requested.connect(func(): _requested_new_map = true)
	hud.save_requested.connect(save_campaign)
	if not campaign_save_path.is_empty() and ProjectSettings.get_setting("campaign/persistence_enabled",true) and (campaign_save_path!="user://campaign_v1.json" or "--no-campaign-save" not in OS.get_cmdline_user_args()):
		progress=CampaignProgress.new(CampaignStore.new(campaign_save_path))
		var restored: Dictionary=progress.open()
		if not restored.is_empty():
			_apply_restored(restored)
		elif progress.status=="protected":
			paused=true
		else:save_campaign()
		knight.refresh_visual(0.0)
		view.present(sim,knight.position.x)
		hud.present_world(sim,paused,knight.position.x,knight.is_on_floor())
	if progress!=null:
		manual_progress=CampaignProgress.new(CampaignStore.new(campaign_save_path+".manual"))
		_manual_available=not manual_progress.open().is_empty()
	var allow_preferences: bool=not audio_preferences_path.is_empty() and ProjectSettings.get_setting("campaign/persistence_enabled",true) and (audio_preferences_path!="user://audio.cfg" or "--no-campaign-save" not in OS.get_cmdline_user_args())
	if allow_preferences:
		preferences=AudioPreferences.new(audio_preferences_path)
		var levels: Dictionary=preferences.read()
		audio.music_volume=levels.music;audio.effects_volume=levels.effects
	hud.options_menu.set_levels(audio.music_volume,audio.effects_volume)
	hud.options_menu.volume_changed.connect(func(music: float,effects: float):
		audio.music_volume=music;audio.effects_volume=effects
		if preferences!=null:preferences.write(music,effects))
	hud.options_menu.save_checkpoint_requested.connect(save_manual_campaign)
	hud.options_menu.load_checkpoint_requested.connect(load_manual_campaign)
	hud.options_menu.title_requested.connect(return_to_title)
	view.interactions_visible=not paused and sim.is_running()
	view.keyboard_hint=not hud.uses_touch_controls()
	_present_save()
	_sync_knight_equipment()
	audio.observe(0,sim,knight.position.x,true)

func restart() -> void:
	if progress!=null:
		# Explicit restart archives the last run; failed storage cannot discard it.
		if progress.status!="protected" and not save_campaign():return
		if not progress.archive():
			_present_save()
			return
	if not _seed_initialized:
		_map_seed = tuning.map_seed
		_seed_initialized = true
	var config := {"seed":_map_seed,"economy":tuning.economy_rules(),"scrap":tuning.starting_scrap,"crystals":tuning.starting_crystals,
		"first_raid":tuning.first_raid_seconds,"raid_gap":tuning.raid_gap_seconds,
		"person_speed":tuning.resident_speed,"shield_value":tuning.shield_per_crystal}
	config.merge(tuning.campaign_rules(),true)
	_campaign_config=config
	sim = FrontierSession.new(config,Mapper.knight_stats(knight_tuning,combo_tuning))
	knight.configure(sim.hero,knight_tuning)
	knight.position = Vector2(sim.world.sites.hall-tuning.arrival_walk_distance,430)
	investment=InvestmentHold.new(tuning.investment_hold_delay,tuning.investment_interval,tuning.investment_refund_delay)
	investment.cancel()
	hud.interact_held=false
	_sync_investment_focus()
	paused = false
	_requested_interaction = false
	_requested_throw = false
	controls.release_all()
	_requested_special=false
	if is_instance_valid(hud.module_menu):hud.module_menu.hide()
	hud.cancel_touch_gestures()
	_build_terrain()
	if progress!=null:save_campaign()
	if is_instance_valid(knight.visual):_sync_knight_equipment()
	if is_instance_valid(audio):audio.observe(0,sim,knight.position.x,true)

func _physics_process(seconds: float) -> void:
	if _requested_new_map:
		_requested_new_map = false
		_map_seed += 1
		restart()
		_map_seed=sim.map_seed
	var was_paused:=paused
	var was_running:=sim.is_running()
	super._physics_process(seconds)
	if paused and not was_paused:hud.cancel_touch_gestures()
	if _requested_throw and not paused:
		sim.throw_crystal(knight.position.x,knight.position.y,sim.hero.facing)
		hud.present_world(sim,paused,knight.position.x,knight.is_on_floor())
	_requested_throw = false
	if _requested_special and not paused:sim.activate_module(knight.position.x)
	_requested_special=false
	if hud.module_menu.visible and not paused:hud.module_menu.hide()
	if paused or not sim.is_running():
		sim.cancel_all_investments(knight.position.x)
		investment.cancel()
		hud.interact_held=false
		_sync_investment_focus()
	if not paused and sim.is_running():_save_elapsed+=seconds
	if (paused and not was_paused) or (was_running and not sim.is_running()) or _save_elapsed>=autosave_seconds:
		save_campaign()
	_present_save()
	if not paused and not sim.is_running():
		view.hit_feedback.advance_terminal(seconds)
		view.queue_redraw()
	view.interactions_visible=not paused and sim.is_running()
	view.keyboard_hint=not hud.uses_touch_controls()
	_sync_knight_equipment()
	if is_instance_valid(_sunbeams):_sunbeams.present(sim)
	if is_instance_valid(_water):_water.present(sim)
	if is_instance_valid(_lantern):_lantern.present(sim,knight)
	audio.observe(seconds,sim,knight.position.x,paused)

func _travel_axis(direction: float, seconds: float) -> float:
	var pace: float=tuning.walking_speed/maxf(1,knight_tuning.move_speed) if sim.life.enabled else 1.0
	return sim.travel_axis(direction,seconds)*pace

func _apply_interaction(command: Dictionary, seconds: float) -> void:
	# Keep a completed swipe until physics consumes it; each new swipe releases the previous order.
	var pressed: bool=_requested_interaction or command.get("interaction_pressed",false)
	if pressed:investment.step(0.0,false,true,sim,knight.position.x)
	var held: bool=command.interaction_held or hud.interact_held or pressed
	investment.step(seconds,held,knight.is_on_floor() and not (command.jump or command.jump_held) and sim.is_running(),sim,knight.position.x)
	_sync_investment_focus()
	_sync_knight_equipment()

func _sync_investment_focus() -> void:
	view.focus_key=investment.target_key
	hud.focus_key=investment.target_key
	view.investment_progress=investment.progress()

func _notification(what: int) -> void:
	super._notification(what)
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_requested_throw = false
		_requested_special=false
		if is_instance_valid(audio):
			audio.suspended=true
			audio.stop()
		if investment!=null:
			sim.cancel_all_investments(knight.position.x)
			investment.cancel()
		if is_instance_valid(hud): hud.cancel_touch_gestures()
		if progress!=null:save_campaign()
	if what in [NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_APPLICATION_RESUMED] and is_instance_valid(audio):audio.suspended=false
	if what==NOTIFICATION_WM_CLOSE_REQUEST and progress!=null:save_campaign()

func save_campaign() -> bool:
	if progress==null:return true
	_save_elapsed=0.0
	var result: bool=progress.save(sim,_campaign_config,{"x":knight.position.x,"y":knight.position.y,"vx":knight.velocity.x,"vy":knight.velocity.y})
	_present_save()
	return result

func _apply_restored(restored: Dictionary) -> void:
	sim=restored.session
	_campaign_config=restored.config
	_map_seed=sim.map_seed
	knight.configure(sim.hero,knight_tuning)
	knight.position=Vector2(restored.body.x,restored.body.y)
	knight.velocity=Vector2(restored.body.vx,restored.body.vy)
	_sync_knight_equipment()
	# Saved input gestures cannot resume automatically after loading.
	sim.cancel_all_investments(knight.position.x)
	investment.cancel()
	controls.release_all()
	hud.cancel_touch_gestures()
	hud.interact_held=false
	_requested_interaction=false;_requested_throw=false;_requested_new_map=false
	_sync_investment_focus()
	_build_terrain()
	paused=true
	knight.refresh_visual(0.0)
	view.present(sim,knight.position.x)
	hud.present_world(sim,paused,knight.position.x,knight.is_on_floor())

func save_manual_campaign() -> bool:
	if manual_progress==null:return false
	var saved: bool=manual_progress.save(sim,_campaign_config,{"x":knight.position.x,"y":knight.position.y,"vx":knight.velocity.x,"vy":knight.velocity.y})
	if saved:_manual_available=true
	_present_save()
	return saved

func load_manual_campaign() -> bool:
	if manual_progress==null:return false
	var restored: Dictionary=manual_progress.open()
	_manual_available=not restored.is_empty()
	if _manual_available:_apply_restored(restored)
	_present_save()
	return _manual_available

func _present_save() -> void:
	if is_instance_valid(hud):
		hud.present_save(progress.status if progress!=null else "disabled",paused)
		if is_instance_valid(hud.options_menu):
			hud.options_menu.record_status(_manual_available,manual_progress!=null and manual_progress.status=="saved",manual_progress!=null and manual_progress.status in ["error","protected"])
			hud.options_menu.save_button.disabled=manual_progress==null or manual_progress.status=="protected"

func _exit_tree() -> void:
	if progress!=null and is_instance_valid(knight):save_campaign()

func _open_loadout() -> void:
	if paused or not sim.is_running() or sim.frontier.city_level<=0 or absf(knight.position.x-sim.world.sites.drill)>=73:return
	paused=true;controls.release_all();hud.cancel_touch_gestures()
	hud.module_menu.show();hud.module_menu.present(sim.modules,hud.uses_touch_controls())
	hud.present_world(sim,true,knight.position.x,knight.is_on_floor())

func _close_loadout() -> void:
	hud.module_menu.hide();paused=false;controls.release_all();hud.cancel_touch_gestures()

func _leave() -> void:
	return_to_title()

func return_to_title() -> void:
	if not save_campaign():return
	controls.release_all()
	hud.cancel_touch_gestures()
	get_tree().call_deferred("change_scene_to_file","res://scenes/start_menu.tscn")


func _build_terrain() -> void:
	var map = sim.frontier
	var shape := RectangleShape2D.new()
	shape.size = Vector2(map.right_boundary-map.left_boundary,110)
	$Floor/Shape.shape = shape
	$Floor.position.x = (map.left_boundary+map.right_boundary)*0.5
	$LeftWall.position.x = map.left_boundary-10
	$RightWall.position.x = map.right_boundary+10
	$Knight/Camera2D.limit_left = int(map.left_boundary)-160
	$Knight/Camera2D.limit_right = int(map.right_boundary)+160
	$Knight/Camera2D.position.y=ambience.camera_offset_y
	$Knight/Camera2D.limit_bottom=740
	$Knight/Camera2D.reset_smoothing()
	if is_instance_valid(_terrain):
		remove_child(_terrain)
		_terrain.queue_free()
	_terrain = Node2D.new()
	_terrain.name = "GeneratedTerrain"
	add_child(_terrain)

func _sync_knight_equipment() -> void:
	knight.visual.set_equipment(sim.frontier.drill_level,0 if sim.life.enabled else sim.growth.capacitor_level)
	knight.visual.unarmed=not sim.can_wield_sword()
	knight.visual.damage_serial=sim.survival.hits
	knight.visual.ceremony_age=-1.0
	for effect in sim.effects:
		if effect.kind=="camp_ignition" and absf(knight.position.x-effect.x)<96:
			knight.visual.ceremony_age=2.4-effect.life
	var tired_idle: bool=sim.hero.stamina<sim.hero.stats.attack_cost and sim.hero.attack_remaining<=0 and absf(knight.velocity.x)<1
	knight.visual.breathing=sim.life.enabled and (sim.travel.breath_ticks>0 or tired_idle)
	knight.visual.breath_stop_remaining=float(sim.travel.breath_ticks)/preload("res://domain/time/tick_clock.gd").TICKS_PER_SECOND
	knight.visual.tired_walk=sim.life.enabled and sim.travel.winded
	knight.visual.exertion=sim.travel.breath_load(sim.hero)
	knight.set_mounted(sim.frontier.drill_level>=3 if sim.life.enabled else sim.growth.can_ride(sim.frontier.drill_level,sim.frontier.training_limit))

func _can_attack() -> bool:return sim.can_wield_sword() and not (sim.life.enabled and sim.travel.winded)
