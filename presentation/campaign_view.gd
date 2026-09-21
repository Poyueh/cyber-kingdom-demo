extends "res://presentation/frontier_view.gd"
const HitFeedback=preload("res://presentation/campaign_hit_feedback.gd")
const Shrine=preload("res://presentation/spirit_shrine.gd")
var hit_feedback:=HitFeedback.new()
const Daylight=preload("res://presentation/daylight_view.gd")
@export var daylight_style: Resource=preload("res://data/daylight_style.gd").new()
var _daylight: Daylight
var _camp_ignition_age: float=-1.0

func _ready() -> void:
	super._ready()
	_daylight=Daylight.new()
	_daylight.style=daylight_style
	add_child(_daylight)

func _draw_sky(bounds: Rect2) -> void:
	if _daylight==null:
		super._draw_sky(bounds)
		return
	_daylight.present(_sim.clock,art.woodland,bounds)

var _reveal=preload("res://presentation/exploration_reveal.gd").new()
var _mist=preload("res://presentation/exploration_mist.gd").new()
const Details=preload("res://presentation/frontier_details.gd")
var _details: Array[Dictionary]=[]
const RiftVisual=preload("res://presentation/rift_visual.gd")
const ResidentMotion=preload("res://presentation/resident_motion.gd")
@export var resident_atlas: Texture2D=preload("res://art/characters/resident-motion-v002/residents.png")
var _resident_motion:=ResidentMotion.new()
const Ambient=preload("res://presentation/ambient_motion.gd")
@export var wanderer_idle: Texture2D=preload("res://art/ambient/v001/wanderer-idle.png")
@export var chest_open: Texture2D=preload("res://art/ambient/v001/chest-open.png")
var keyboard_hint:=true
var interactions_visible:=true
var _slot_key:=""
var _slot_paid:=0
var _slot_changed:=0.0
var crystal_radius: float = 9.0
## A pile is a small sprite plus its count label.
const CRYSTAL_MARGIN := 64.0
var focus_key := ""
var _view_player_x := 0.0
var investment_progress := 0.0
const Icons=preload("res://presentation/ui_icons.gd")
const SITE_ICONS={"shield_charge":"shield","rift":"rift","core_charge":"camp","hall":"camp","workshop":"hammer","armory":"bow","farm_tools":"hoe","hunt_tools":"bow","forge":"gear","beacon":"tower","tower":"tower","field":"hoe","wall":"wall","wall_left":"wall","farm":"food","drill":"sword","trade":"trade","heal":"heal","outpost":"outpost","recruit":"person","chest":"chest","mark":"hammer"}
const EXTRA_ART := {"tower-1":preload("res://art/structures/fortifications-v001/tower-1.png"),"tower-2":preload("res://art/structures/fortifications-v001/tower-2.png"),"tower-3":preload("res://art/structures/fortifications-v001/tower-3.png"),"drill":preload("res://art/structures/immersive-v001/drill.png"),"wall-1":preload("res://art/structures/immersive-v001/wall-1.png"),"wall-2":preload("res://art/structures/immersive-v001/wall-2.png"),"wall-3":preload("res://art/structures/immersive-v001/wall-3.png"),"campfire":preload("res://art/campaign/v001/campfire.png"),"stone":preload("res://art/campaign/v001/stone.png"),"herbs":preload("res://art/campaign/v001/herbs.png"),"plot":preload("res://art/campaign/v001/plot.png")}

func present(sim, player_x: float) -> void:
	if not is_same(_sim,sim):
		_resident_motion.clear()
		_reveal=preload("res://presentation/exploration_reveal.gd").new()
		_mist=preload("res://presentation/exploration_mist.gd").new()
		_details=Details.layout(sim.map_seed,sim.frontier.regions)
	_sim=sim
	_camp_ignition_age=-1.0
	for effect in sim.effects:
		if effect.kind=="camp_ignition":_camp_ignition_age=2.4-effect.life
	_reveal.observe(sim.frontier.regions+sim.mission.rifts,sim.workforce.elapsed)
	hit_feedback.present(sim)
	_view_player_x=player_x
	_context=sim.context(player_x) if focus_key.is_empty() else sim.context_for_key(player_x,focus_key)
	if _context.key!=_slot_key or _context.paid!=_slot_paid:
		_slot_changed=sim.workforce.elapsed
		_slot_key=_context.key
		_slot_paid=_context.paid
	queue_redraw()

func _region_reveal(index: int) -> float:
	return _reveal.amount(index)

func _outpost_visible(region: Dictionary) -> bool:
	return region.outpost_built or region.outpost_pending or (_sim.frontier.expansion_cleared(_sim.frontier.regions.find(region)) and absf(_view_player_x-region.outpost_x)<180)

func _work_marker(resource, at: Vector2) -> void:
	# A small paid glow on the resource, never a pole in the landscape.
	for i in range(3):draw_rect(Rect2(at+Vector2(-9+i*7,-4),Vector2(3,2)),Color("dfc688"))
	if resource.worker>=0:
		draw_rect(Rect2(at+Vector2(-16,3),Vector2(32*clampf(1-resource.remaining_work/75.0,0,1),2)),Color("a8d5b3"))

func _prop(name: String, at: Vector2, scale: float = 1.0, tint := Color.WHITE) -> void:
	if not _on_screen(at.x,320):return
	tint.a*=_world_alpha
	if tint.a<=0:return
	if not _context.is_empty() and _context.enabled and (absf(_context.x-at.x)<3 or (name=="campfire" and _context.id in ["hall","core_charge"] and absf(at.x-_context.x-104)<3)):
		tint=Color(tint.r*1.8,tint.g*1.9,tint.b*1.65,tint.a)
	if name=="outpost":
		var regions=_sim.frontier.regions.filter(func(r):return is_equal_approx(r.outpost_x,at.x))
		if not regions.is_empty() and not regions[0].outpost_built:name="plot"
	if name=="plot":
		if absf(at.x-_view_player_x)<130:
			for side in [-1,1]:
				draw_rect(Rect2(at+Vector2(side*22-5,-3),Vector2(10,3)),Color("68736b")*tint)
				draw_rect(Rect2(at+Vector2(side*18-3,-5),Vector2(6,2)),Color("8b8c72")*tint)
		return
	var texture: Texture2D=Details.harvest_texture(name,at.x,_sim.map_seed)
	if texture==null:texture=EXTRA_ART.get(name,art.props.get(name))
	if _sim.life.enabled and name in ["workshop","armory"]:
		for effect in _sim.effects:
			if effect.kind=="camp_ignition":
				var assembled: float=smoothstep(1.0,2.1,2.4-effect.life)
				tint.a*=assembled
				at.y+=(1-assembled)*24
	Ambient.prop(self,texture,name,at,scale,tint,_sim.workforce.elapsed)
	var emission: Texture2D=art.emission_masks.get(name)
	if emission!=null:
		var size:=texture.get_size()*scale
		var pulse: float=0.20+0.16*sin(_sim.workforce.elapsed*2.4+at.x*0.013)
		draw_texture_rect(emission,Rect2(preload("res://presentation/grounded_art.gd").anchor(texture,at,scale)-Vector2(size.x*0.5,size.y),size),false,Color(1,1,1,pulse*tint.a))

func _draw_atmosphere(_left: float) -> void:
	Details.draw_background(self,_details,_sim.frontier.regions)
	# Water is rendered after world actors by WaterReflection.
	if art.show_power_grid: _draw_power_grid()

func _draw_power_grid() -> void:
	# Decorative circuitry follows actual constructed sites and the paused game clock.
	if _sim.frontier.city_level==0: return
	var points: Array[float]=[float(_sim.world.sites.hall)]
	for site in _sim.built:
		if _sim.built[site]: points.append(float(_sim.world.sites[site]))
	for id in _sim.world.walls:
		if _sim.world.walls[id].level>0: points.append(float(_sim.world.sites[id]))
	if _sim.frontier.farm_active: points.append(float(_sim.world.sites.farm))
	points.sort()
	if points.size()<2: return
	var length: float=points.back()-points.front()
	if length<=0: return
	draw_rect(Rect2(points.front(),443,length,5),Color("102934"))
	draw_line(Vector2(points.front(),445),Vector2(points.back(),445),Color("27717e"),1)
	var phase: float=fposmod(_sim.workforce.elapsed*48,length)
	for offset in range(0,ceili(length),96):
		var x: float=points.front()+fposmod(phase+offset,length)
		draw_rect(Rect2(x,444,minf(9,points.back()-x),2),Color("6ef2dc"))
	for x in points:
		draw_line(Vector2(x,430),Vector2(x,445),Color("306b78"),2)

func _draw_structures() -> void:
	var world = _sim.world
	var map = _sim.frontier
	var hall: float = world.sites.hall
	var core_tint:=Color.WHITE if _sim.mission.core_hp>0 else Color("566779")
	if _camp_ignition_age>=0:core_tint.a*=smoothstep(0.82,1.35,_camp_ignition_age)
	if map.city_level>0: _prop("hall-%d" % map.city_level,Vector2(hall,430),1.0,core_tint)
	if _camp_ignition_age>=0 and _camp_ignition_age<1.1:_prop("stone",Vector2(hall,430),0.45)
	if not _sim.life.enabled or map.city_level>0:
		_prop("campfire",Vector2(hall+(104 if map.city_level>0 else 0),430),0.7 if map.city_level>0 else 1.0,core_tint)
	else:
		_prop("stone",Vector2(hall,430),0.45)
		_icon("sword",Vector2(hall,398),35,Color("c7e1d7"))
	if art.props.has("relay"):
		_prop("relay",Vector2(hall-115,430),0.8)
		if map.city_level>0: _prop("relay",Vector2(_sim.world.sites.workshop-100,430),0.8)
	_text(tr("營火 · 王國由此開始") if map.city_level==0 else tr("聚落 %d/3 · 收貨點") % map.city_level,hall,282,Color("f3d299"),15)
	_draw_mission()
	_draw_recruitment_camps()
	preload("res://presentation/module_visual.gd").relics(self,_sim)
	# Before the first investment there is only a campfire and nearby wanderers.
	if map.city_level==0: return
	if _sim.life.enabled:
		var shrine_x: float=_sim.spirit.shrine_x(hall)
		if _on_screen(shrine_x,100):
			Shrine.draw_on(self,Vector2(shrine_x,430),_sim.workforce.elapsed,_context.id=="spirit",not _sim.spirit.active(int(_sim.workforce.elapsed*_sim.spirit.TICKS_PER_SECOND)))
	for site in world.sites:
		var x: float=world.sites[site]
		if not _sim.defenses.visible(site):continue
		if not _sim.site_visible(site):continue
		if _sim.life.enabled and not _sim._campaign_site(site).get("prerequisites",[]).is_empty() and not _sim.built.get(site,false):continue
		if site=="hall" or not interactions_visible or absf(x-_view_player_x)>130: continue
		if not _context.id.is_empty() and absf(_context.x-x)<1:continue
		_icon("wall" if world.walls.has(site) else SITE_ICONS.get(site,"hand"),Vector2(x,276 if _sim.built.get(site,false) else 343),23)
	for site in ["workshop","armory","farm_tools","hunt_tools","forge"]:
		if not _sim.site_visible(site):continue
		var at := Vector2(world.sites[site],430)
		var asset: String = {"farm_tools":"workshop","hunt_tools":"armory"}.get(site,site)
		if _sim.built.get(site,false):
			_prop(asset,at,0.7 if site in ["farm_tools","hunt_tools"] else 1.0)
		else: _prop("plot",at)
		_text(_sim.NAMES[site],at.x,286 if _sim.built.get(site,false) else 352,Color("cce0cc"),14)
		if _sim.TOOL_KINDS.has(site):
			var kind: String = _sim.TOOL_KINDS[site]
			for index in range(world.tools[kind]): _tool(at+Vector2(-20+index*20,-22),kind)
		elif site=="armory":
			if _sim.life.enabled:
				for i in range(world.tools.blade):_tool(at+Vector2(-20+i*20,-22),"blade")
			for tier in range(_sim.barracks_level):_icon("bow",at+Vector2(-22+tier*22,-90),16,Color("9cf5d8"))
		elif site=="beacon" and world.barrier>0: _text(tr("防護 ×%d") % world.barrier,at.x,310,Color("8ce2dc"),13)
	for id in world.walls:
		if not _sim.defenses.visible(id):continue
		var wall_x: float=world.sites[id]
		var defense: Dictionary=world.walls[id]
		if defense.level>0:
			_prop("wall-%d"%defense.level,Vector2(wall_x,430),1.0,Color.WHITE if defense.hp>0 else Color(0.4,0.35,0.38))
			if not _sim.life.enabled:
				draw_rect(Rect2(wall_x-28,316,56,4),Color("263940"))
				draw_rect(Rect2(wall_x-28,316,56.0*defense.hp/_sim.world.wall_max_hp(defense.level),4),Color("8fdbbe"))

		else: _prop("plot",Vector2(wall_x,430))
		if defense.pending:
			_icon("hammer",Vector2(wall_x,307),18)
			draw_rect(Rect2(wall_x-28,326,56.0*minf(1.0,defense.progress/3.0),3),Color("f4d49d"))
	for site in ["farm","drill","heal"]:
		if not _sim.site_visible(site):continue
		var at := Vector2(world.sites[site],430)
		if site=="farm":preload("res://presentation/farm_plot.gd").draw_on(self,at,_context.id=="farm" and _context.enabled,1.0)
		_prop("crops" if site=="farm" and map.farm_active else ("herbs" if site=="heal" else "drill" if site=="drill" and _sim.life.enabled else "plot"),at)
		_text(_sim.NAMES[site],at.x,345,Color("d0d9b8"),13)
		if site=="farm" and map.farm_active:
			draw_rect(Rect2(at.x-40,355,80*map.farm_progress/map.farm_cycle,3),Color("d8dd9f"))

	_draw_buildings()

func _draw_buildings() -> void:
	for id in _sim.buildings:
		var site: Dictionary=_sim.buildings[id]
		if site.kind=="wall" or not _sim.building_visible(id):continue
		_world_alpha=1.0 if site.region<0 else _region_reveal(site.region)
		var at:=Vector2(site.x,430)
		if site.kind=="farm":preload("res://presentation/farm_plot.gd").draw_on(self,at,_context.get("building_id","")==id and _context.enabled,_world_alpha)
		if site.level>0:_prop("tower-%d"%site.level if site.kind=="tower" else "crops",at)
		else:_prop("plot",at)
		if absf(site.x-_view_player_x)<130 and _context.get("building_id","")!=id:
			_icon("tower" if site.kind=="tower" else "hoe",at+Vector2(0,-195 if site.level>0 and site.kind=="tower" else -60),24)
		if site.pending:
			for side in [-1,1]:draw_line(at+Vector2(side*35,0),at+Vector2(side*35,-72),Color("977e58"),3)
			draw_line(at+Vector2(-35,-56),at+Vector2(35,-56),Color("977e58"),3)
			_icon("hammer",at+Vector2(0,-83),20)
			draw_rect(Rect2(at+Vector2(-28,-68),Vector2(56*site.progress/_sim.build_seconds,4)),Color("94dfc7"))
	_world_alpha=1.0

func _draw_recruitment_camps() -> void:
	for i in range(_sim.frontier.regions.size()):
		if not _sim.frontier.regions[i].discovered:continue
		_world_alpha=_region_reveal(i)
		var x: float=_sim.ecology.camp_x(i)
		var active: bool=_sim.ecology.habitat(i)
		_prop("campfire" if active else "stone",Vector2(x,430),0.35,Color.WHITE if active else Color("5b6876"))
		if _sim.life.enabled or absf(_view_player_x-x)>180:continue
		var count: int=_sim.ecology.waiting(i,_sim.world.people)
		var full: bool=_sim.world.people.size()>=_sim.ecology.population_limit
		draw_style_box(_bubble_style(),Rect2(x-46,326,92,34))
		_icon("person",Vector2(x-29,343),18)
		_number("%d/%d" % [_sim.world.people.size() if full else count,_sim.ecology.population_limit if full else _sim.ecology.waiting_limit],Vector2(x-15,348))
		_icon("lock" if full else "sun",Vector2(x+31,343),17,Color("dd9c91") if full else Color("d9d7ac"))
		if not active:
			draw_line(Vector2(x-38,354),Vector2(x+38,330),Color(Color("c99187"),_world_alpha),2)

	_world_alpha=1.0

func _draw_mission() -> void:
	var mission=_sim.mission
	var x: float=_sim.world.sites.hall
	var y:=314.0 if _sim.frontier.city_level==0 else 267.0
	var ratio: float=float(mission.core_hp)/mission.core_max_hp
	if not _sim.life.enabled:
		_icon("camp",Vector2(x-42,y),18,Color("9edbd3"))
		draw_rect(Rect2(x-28,y-3,56,5),Color("25373e"))
		draw_rect(Rect2(x-28,y-3,56*ratio,5),Color("eea097") if ratio<0.35 else Color("9edbd3"))
	for index in range(mission.rifts.size()):
		var rift: Dictionary=mission.rifts[index]
		if rift.discovered:RiftVisual.draw_gate(self,rift,_sim.workforce.elapsed,mission.seal_seconds,_reveal.amount(_sim.frontier.regions.size()+index))

func _person(person: Dictionary, protected: bool) -> void:
	if not _sim.person_visible(person): return
	_world_alpha=_region_reveal(person.get("region",-1)) if person.role=="wanderer" else 1.0
	var state: String=person.get("work_state","idle")
	var hit:=hit_feedback.resident_pose(_sim.world.people.find(person))
	if person.role=="engineer" and state in ["work","haul","climb"] and not hit.active:
		# Preserve authored hammer, cargo and ladder silhouettes for real work.
		super._person(person,protected)
	else:
		var index: int=_sim.world.people.find(person)
		var pose:=_resident_motion.sample(person,index,_sim.workforce.elapsed)
		var role: int={"wanderer":0,"citizen":1,"farmer":2,"hunter":3,"guard":4,"engineer":5}[hit.role if hit.active else person.role]
		var row:=role*2+(1 if pose.mode=="idle" or hit.active else 0)
		if hit.active:pose.frame=0
		var at:=Vector2(person.x,person.get("y",430))
		draw_set_transform(at+hit.offset,hit.rotation,hit.scale*Vector2(person.get("direction",1.0),1))
		_draw_person_texture(resident_atlas,Rect2(pose.frame*64,row*64,64,64),Color(1.8,1.15,1.1).lerp(Color.WHITE,1-hit.flash) if hit.active else Color(1.8,1.9,1.65) if _context.get("person_index",-2)==index and _context.enabled else Color.WHITE)
		draw_set_transform(Vector2.ZERO)
		if protected and person.role!="wanderer": draw_arc(at+Vector2(0,-24),29,PI,TAU,16,Color("81ddda"),1)

	var key: String={"wanderer":"person","citizen":"person","engineer":"hammer","farmer":"hoe","hunter":"bow","guard":"sword"}[person.role]
	_icon(key,Vector2(person.x,person.get("y",430)-50),17,Color("b4e7df") if person.role!="wanderer" else Color("d4c3a7"))

	if _sim.life.enabled and person.role=="guard":
		var dir: float=person.get("direction",1.0)
		var at: Vector2=Vector2(person.x,person.get("y",430)-28)
		var thrust: float=maxf(0,person.cooldown-0.85)*36
		draw_line(at+Vector2(dir*5,-5),at+Vector2(dir*(49+thrust),-5),Color("b8aa85"),2)
		draw_colored_polygon(PackedVector2Array([at+Vector2(dir*(60+thrust),-5),at+Vector2(dir*(47+thrust),-9),at+Vector2(dir*(47+thrust),-1)]),Color("bfebdd"))
		draw_rect(Rect2(at+Vector2(dir*9-6,-3),Vector2(12,21)),Color("53657a"))
		draw_line(at+Vector2(dir*9,-1),at+Vector2(dir*9,17),Color("c5b17d"),2)
	if hit.demoted:_draw_demotion(person,hit)
	_world_alpha=1.0

func _draw_demotion(person: Dictionary, hit: Dictionary) -> void:
	var progress: float=hit.demotion_progress
	var at:=Vector2(person.x,person.get("y",430))
	var alpha:=1.0-smoothstep(0.65,1.0,progress)
	var ink:=Color(1.0,0.65,0.39,alpha)
	var key: String={"engineer":"hammer","guard":"sword","farmer":"hoe","hunter":"bow"}.get(hit.lost_role,"shield")
	var tool_at:=at+Vector2(hit.direction*(12+progress*38),-42-sin(progress*PI)*40)
	draw_set_transform(tool_at,hit.direction*progress*2.5)
	_icon(key,Vector2.ZERO,25,ink)
	draw_set_transform(Vector2.ZERO)
	# Split occupation marker and hollow person badge describe the lost identity.
	var badge:=at+Vector2(0,-83-progress*9)
	draw_circle(badge,21,Color(0.09,0.08,0.12,alpha*0.9))
	_icon("person",badge,27,ink)
	for side in [-1,1]:
		draw_line(badge+Vector2(side*24,-10),badge+Vector2(side*31,-17),ink,3)
	for i in range(5):
		var mote:=at+Vector2((i-2)*10*progress,-20-sin(progress*PI)*25+i*3)
		draw_rect(Rect2(mote,Vector2(3,3)),ink)

func _draw_person_texture(texture: Texture2D, source: Rect2, tint: Color) -> void:
	tint.a*=_world_alpha
	preload("res://presentation/compact_people.gd").draw(self,texture,source,tint)

func _draw_activity() -> void:
	# Render rewards after actors so the collection journey stays legible.
	super._draw_activity()
	_draw_fallen()
	preload("res://presentation/module_visual.gd").effects(self,_sim)
	for pile in _sim.pouch.drops:
		if not _on_screen(pile.x,CRYSTAL_MARGIN):continue
		for index in range(mini(3,pile.amount)):
			var visible: Dictionary=pile.duplicate()
			visible.x+=index*11-(mini(3,pile.amount)-1)*5.5
			visible.id+=index
			Ambient.crystal(self,visible,crystal_radius*1.35,_sim.workforce.elapsed)
		if pile.amount>1 and not _sim.life.enabled: _number(str(pile.amount),Vector2(pile.x+12,pile.y-29))
	for effect in _sim.effects:
		if not _on_screen(effect.x,500):continue
		if effect.kind=="crystal_sink":
			var progress: float=1-effect.life/0.85
			_crystal(Vector2(effect.x+sin(progress*PI)*25,effect.y-24+progress*98),true,8)
			if progress>0.65:draw_arc(Vector2(effect.x+20,484),8+progress*18,0,PI,14,Color(0.5,0.88,0.92,1-progress),2)
			continue
		if effect.kind in ["core_hit","camp_ignition"]:
			var ink: Color=Color(1,0.3,0.12,clampf(effect.life,0,1)*0.4) if effect.kind=="core_hit" else Color(0.5,1,0.8,clampf(effect.life/2.4,0,1)*0.3)
			if effect.kind=="core_hit":draw_circle(Vector2(effect.x,408),55+sin(effect.life*14)*8,ink)
			if effect.kind=="camp_ignition":
				var age: float=2.4-effect.life
				var burst: float=maxf(0,age-0.82)
				if burst>0:
					var fade: float=1.0-smoothstep(0.25,1.25,burst)
					draw_arc(Vector2(effect.x,425),18+burst*110,PI,TAU,24,Color(0.55,1,0.82,fade*0.6),2)
					for i in range(12):
						var spark:=Vector2(effect.x+sin(i*2.7)*burst*55,416-burst*(42+i*7)+burst*burst*35)
						draw_rect(Rect2(spark.round(),Vector2(2,4)),Color(1,0.7,0.25,fade))
			continue
		if effect.kind in ["tower_arrow","tower_laser"]:
			var origin:=Vector2(effect.x,430-[0,118,134,132][effect.tier])
			var target:=Vector2(effect.to,403)
			var alpha: float=clampf(effect.life/0.28,0,1)
			if effect.kind=="tower_laser":
				draw_line(origin,target,Color(0.1,0.9,1,alpha*0.25),10)
				draw_line(origin,target,Color(0.55,1,1,alpha),4)
				draw_line(origin,target,Color(1,1,1,alpha),1)
				draw_circle(target,6*alpha,Color(0.6,1,1,alpha))
			else:
				var tip:=origin.lerp(target,1-alpha)
				var direction: Vector2=(target-origin).normalized()
				draw_line(tip-direction*20,tip,Color("eee1a3"),2)
				draw_line(tip-direction*5+Vector2(0,-3),tip,Color("a9e8ce"),2)
			continue
		if effect.kind=="dragon_fire":
			for i in range(28):
				var progress: float=i/27.0
				var point:=Vector2(lerpf(effect.x,effect.to,progress),lerpf(325,416,progress)+sin(i*2.3+effect.life*22)*18)
				draw_rect(Rect2(point.round(),Vector2(12,7)),Color(1,0.5+progress*0.25,0.27,effect.life/0.7))
			continue
		if effect.kind=="portal_spawn":
			var radius: float=28*(1-effect.life/0.6)
			draw_arc(Vector2(effect.x,400),radius,0,TAU,16,Color(0.77,0.43,0.93,effect.life/0.6),3)
			continue
		if effect.kind not in ["crystal_pickup","chest_burst","recruited"]: continue
		var duration: float=0.25 if effect.kind=="crystal_pickup" else 0.7
		var progress:=1.0-float(effect.life)/duration
		var at:=Vector2(effect.x,effect.y-24)
		for index in range(8):
			var angle:=index*TAU/8
			var point:=at+Vector2(cos(angle),sin(angle))*(8+progress*28)
			draw_rect(Rect2(point.round(),Vector2.ONE*2),Color(0.65,1,0.83,1-progress))

func _crystal(at: Vector2, filled: bool, radius: float = 8.0) -> void:
	var points := PackedVector2Array([at+Vector2(0,-radius),at+Vector2(radius*0.7,0),at+Vector2(0,radius),at+Vector2(-radius*0.7,0)])
	draw_colored_polygon(points,Color("9ef1dd") if filled else Color("16313b"))
	points.append(points[0])
	draw_polyline(points,Color("b6f6df") if filled else Color("76989e"),1.0)

func _draw_interaction() -> void:
	if not interactions_visible:return
	if _context.id.is_empty(): return
	if _sim.life.enabled and not _context.enabled:
		if _context.get("prerequisites",[]).size()>0 and not _sim.world.walls.has(_context.id):
			if _context.has("building_id") and _sim.buildings[_context.building_id].level==0:return
		if _context.has("wall_id") and _sim.world.walls[_context.wall_id].level==0 and not _context.get("prerequisites",[]).is_empty():return
	var requirements: Dictionary=_context.get("requirements",{})
	var prerequisites: Array=_context.get("prerequisites",[])
	var upgrade: Dictionary={} if _sim.life.enabled else _context.get("upgrade",{})
	var consequences: Array=_context.get("consequences",[])
	var width:=maxf(96,_context.cost*23+48)
	width=maxf(width,maxi(requirements.size(),prerequisites.size())*52+28)
	if not upgrade.is_empty():width=maxf(width,136)
	var inverse:=get_viewport().get_canvas_transform().affine_inverse()
	var left: float=(inverse*Vector2.ZERO).x
	var right: float=(inverse*get_viewport_rect().size).x
	var x:=clampf(_context.x,left+width*0.5+8,right-width*0.5-8)
	var ground:=430.0
	if _context.has("node_index"): ground=_sim.frontier.nodes[_context.node_index].y
	var marker_color:=Color("a3efcd") if _context.enabled else Color("769394")
	draw_line(Vector2(_context.x-15,ground+2),Vector2(_context.x+15,ground+2),marker_color,2)
	for side in [-1,1]:
		draw_line(Vector2(_context.x+side*15,ground-3),Vector2(_context.x+side*15,ground+3),marker_color,2)
	var height:=62.0+(20 if not requirements.is_empty() else 0)+(20 if not prerequisites.is_empty() else 0)+(40 if not upgrade.is_empty() else 0)+(22 if not consequences.is_empty() else 0)
	var y:=ground-(184 if _context.id=="rift" else 141)-(height-62)
	if _context.id=="tower":y-=90
	elif _context.has("wall_id"):y-=50
	# Floating cost sockets stay in the world; no rectangular signboard.
	var key: String="sword" if _sim.life.enabled and _context.id=="armory" else SITE_ICONS.get(_context.id,"hand")
	if _context.id=="spirit":key="spirit"
	if _context.id=="mark":
		key={"tree":"tree","crystal":"pickaxe","berries":"food","stone":"stone","herbs":"herbs"}.get(_sim.frontier.nodes[_context.node_index].kind,"hammer")
	_icon(key,Vector2(x,y),28)
	if keyboard_hint:_number("E",Vector2(x+28,y+5))
	if _sim.life.enabled and not _context.enabled and prerequisites.is_empty():
		var cause: String="check"
		if _context.cost>0 and _sim.pouch.amount==0:cause="crystal"
		elif _context.id in ["workshop","hunt_tools","farm_tools","armory"]:cause="person"
		elif _context.has("wall_id") and _sim.world.walls[_context.wall_id].pending:cause="hammer"
		elif _context.has("building_id") and _sim.buildings[_context.building_id].pending:cause="hammer"
		_icon(cause,Vector2(x-42,y),21,Color("ddb98e"))
	if not _context.enabled and not (_context.id=="rift" and _sim.mission.rifts[_context.rift_index].ordered): _icon("lock",Vector2(x+width*0.5-15,y-3),17,Color("d4a994"))
	for index in range(_context.cost):
		var slot:=Vector2(x+(index-(_context.cost-1)*0.5)*23,y+34)
		if index==_context.paid-1:
			var age: float=clampf((_sim.workforce.elapsed-_slot_changed)/0.18,0,1)
			slot.y+=60*(1-age)*(1-age) if _sim.life.enabled else -14*(1-age)*(1-age)
		_crystal(slot,index<_context.paid)
		if index==_context.paid and investment_progress>0:
			draw_arc(slot,11,-PI*0.5,-PI*0.5+TAU*investment_progress,24,Color("e6f6b4"),2)
	if _context.cost==0:
		var status: String="hand" if _context.enabled else "check"
		if _context.id=="rift" and not _sim.mission.rifts[_context.rift_index].sealed:status="hammer"
		_icon(status,Vector2(x,y+27),18)
	var row_y:=y+48
	var index:=0
	for resource in requirements:
		var at:=Vector2(x+(index-(requirements.size()-1)*0.5)*52,row_y)
		_icon(resource,at-Vector2(10,0),17)
		_number(str(requirements[resource]),at+Vector2(3,5))
		index+=1

	if not requirements.is_empty():row_y+=20
	for i in range(prerequisites.size()):
		var item: Dictionary=prerequisites[i]
		var at:=Vector2(x+(i-(prerequisites.size()-1)*0.5)*52,row_y)
		_icon(item.icon,at-Vector2(10,0),17,Color("dbb397"))
		_number(str(item.value),at+Vector2(3,5))

	if not prerequisites.is_empty():row_y+=20
	if not upgrade.is_empty():
		_icon(upgrade.icon,Vector2(x-46,row_y),20,Color("a6e6d3"))
		_number(str(upgrade.value)+upgrade.get("suffix",""),Vector2(x-27,row_y+5))
		_icon("right",Vector2(x+4,row_y),16,Color("b9c8b4"))
		_number(str(upgrade.next)+upgrade.get("suffix",""),Vector2(x+20,row_y+5))
		for i in range(upgrade.limit):
			draw_rect(Rect2(x+(i-(upgrade.limit-1)*0.5)*14-4,row_y+15,8,5),Color("9fdbbf") if i<upgrade.level else Color("435660"))

	if not consequences.is_empty():
		if not upgrade.is_empty():row_y+=40
		for i in range(consequences.size()):
			var at:=Vector2(x+(i-(consequences.size()-1)*0.5)*32,row_y)
			_icon(consequences[i],at,18,Color("dfa092"))
			draw_line(at+Vector2(-8,8),at+Vector2(8,-8),Color("ee857f"),2)

func _bubble_style() -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=Color(0.035,0.09,0.13,0.88*_world_alpha)
	style.border_color=Color(Color("668f88"),_world_alpha)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style

func _icon(key: String, at: Vector2, size: float=24, tint:=Color.WHITE) -> void:
	size*=1.3
	tint.a*=_world_alpha
	draw_texture_rect(Icons.get_icon(key),Rect2(at-Vector2.ONE*size*0.5,Vector2.ONE*size),false,tint)

func _number(value: String, at: Vector2) -> void:
	draw_string(_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(Color("e1e4d0"),_world_alpha))

func _text(value: String, x: float, y: float, _color:=Color.WHITE, _size: int=15) -> void:
	# The campaign's world language is symbols; legacy scenes retain their labels.
	if value=="!": _icon("sword",Vector2(x,y-8),18,Color("ffbd7f"))

func _resource(resource) -> void:
	var building_id: String="cleared:%d"%_sim.frontier.nodes.find(resource)
	if _sim.buildings.has(building_id):
		var site: Dictionary=_sim.buildings[building_id]
		if site.level>0 or (site.kind=="wall" and _sim.world.walls[building_id].level>0):return
	if resource.kind=="cache" and resource.delivered:
		var index: int=_sim.frontier.nodes.find(resource)
		var elapsed: float=_sim.workforce.elapsed-_sim.opened_chests.get(index,0.0)
		var texture: Texture2D=art.props.get("chest-open",chest_open)
		var size:=texture.get_size()
		size.y*=lerpf(0.72,1.0,clampf(elapsed/0.18,0,1))
		draw_texture_rect(texture,Rect2(Vector2(resource.x-size.x*0.5,resource.y-size.y),size),false,Color(0.8,0.9,0.9,_world_alpha))
		return
	super._resource(resource)

func _raider(enemy: Dictionary) -> void:
	if enemy.get("kind","")=="dragon":
		preload("res://presentation/dragon_visual.gd").draw(self,enemy,_sim.workforce.elapsed)
		return
	if not enemy.fighter.is_alive():return
	var hit:=hit_feedback.enemy_pose(enemy)
	var clip: String="idle" if hit.active else "windup" if enemy.windup>0 else "run"
	var frame: int=posmod(int(enemy.x/12),2) if clip=="run" else 0
	var texture: Texture2D=EnemyFrames.get_frame_texture(clip,frame)
	var at:=Vector2(enemy.x,430)
	draw_set_transform(at+hit.offset,hit.rotation,hit.scale*Vector2(enemy.get("direction",-1.0),1))
	preload("res://presentation/compact_people.gd").draw(self,texture,Rect2(Vector2.ZERO,texture.get_size()),Color(1.8,1.1,1.05).lerp(Color.WHITE,1-hit.flash),41,80)
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(enemy.x-22,380,44,4),Color("482a3a"))
	draw_rect(Rect2(enemy.x-22,380,44.0*enemy.fighter.hp/enemy.fighter.stats.max_hp,4),Color("df8491"))
	if enemy.windup>0:_icon("sword",Vector2(enemy.x,368),20,Color("ffd087"))
	if enemy.get("carried_crystals",0)>0:_icon("crystal",Vector2(enemy.x+enemy.direction*15,395+sin(_sim.workforce.elapsed*9)*2),19,Color("c1ffe4"))
func _draw_fallen() -> void:
	var texture: Texture2D=EnemyFrames.get_frame_texture("idle",0)
	for body in hit_feedback.fallen:
		var progress: float=clampf(body.age/HitFeedback.FALL_SECONDS,0,1)
		if body.get("kind","")=="dragon":
			preload("res://presentation/dragon_visual.gd").draw_fallen(self,body,progress)
			continue
		draw_set_transform(Vector2(body.x-body.direction*progress*12,430),-body.direction*smoothstep(0.0,0.55,progress)*1.5,Vector2(body.direction,1-progress*0.5))
		preload("res://presentation/compact_people.gd").draw(self,texture,Rect2(Vector2.ZERO,texture.get_size()),Color(1.3,0.9,0.85,1-smoothstep(0.45,1.0,progress)),41,80)
		draw_set_transform(Vector2.ZERO)
		for i in range(6):
			var mote:=Vector2(body.x+(i-2.5)*22*progress,423-sin(progress*PI)*(18+i*5))
			draw_rect(Rect2(mote,Vector2(4,4)),Color(0.9,0.53,0.65,1-progress))

func _draw() -> void:
	super._draw()
	if _sim==null:return
	if _sim.survival.enabled and _sim.survival.sword_on_ground and _on_screen(_sim.survival.sword_x):
		var grace: float=_sim.survival.sword_grace
		var progress: float=1.0-clampf(grace/1.2,0,1)
		var at: Vector2=Vector2(_sim.survival.sword_x,411-sin(progress*PI)*52)
		draw_set_transform(at,progress*TAU if grace>0 else -0.35)
		draw_texture_rect(Icons.get_icon("sword"),Rect2(-20,-20,40,40),false,Color("cef8eb"))
		draw_set_transform(Vector2.ZERO)
	_mist.draw(self,_sim.frontier.regions,_sim.workforce.elapsed,_view_player_x,_background_rect())
