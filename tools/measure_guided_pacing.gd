extends SceneTree
## Times the guided opening with an efficient player who walks between targets at
## the real walking speed and acts the moment a step is possible. A pacing probe,
## not a substitute for watching a first-time player.
##   godot --headless --path . --script res://tools/measure_guided_pacing.gd
const Campaign=preload("res://application/campaign_session.gd")
const STEP:=1.0/30.0
const WALK:=165.0
const LIMIT:=1200.0
var sim: RefCounted
var hero_x: float=0.0
var clock: float=0.0
var marks: Array=[]
var config: Dictionary={}
var codec: RefCounted=preload("res://application/campaign_snapshot.gd").new()
const Points=preload("res://application/core_checkpoints.gd")

func _initialize() -> void:
	for mode in ["demo","main"]:
		marks.clear();clock=0.0
		config=_config(mode)
		sim=Campaign.new(config)
		hero_x=sim.world.sites.hall-float(load("res://data/campaign.tres").arrival_walk_distance)
		_play()
		_report(mode)
	quit()

func _config(mode: String) -> Dictionary:
	var tuning: Resource=load("res://data/campaign.tres")
	var base: Dictionary=tuning.campaign_rules()
	base.merge({"seed":1054,"economy":tuning.economy_rules()},true)
	var profile: Resource=load("res://data/core_loop.tres")
	base.level_design=load("res://data/planet_levels.tres").rules()
	base.trail_design=load("res://data/trail_encounters.tres").rules()
	base.ruin_variation=load("res://data/ruin_variation.tres").rules()
	var profiles: Array[Dictionary]=[]
	for name: String in ["forest","desert","frost","swamp","volcanic","storm","void"]:profiles.append(load("res://data/planets/"+name+".tres").rules())
	var setup: Script=load("res://application/journey_setup.gd")
	var pace: Dictionary=load("res://data/journey_paces.tres").find(0).rules()
	if mode=="demo":
		var forest: Dictionary=setup.create_forest(base,profiles[0],pace)
		forest.merge(setup.gate_rules(load("res://data/planets/forest.tres")),true)
		return profile.resolve_demo(forest)
	var journey: RefCounted=setup.create(base,profiles,pace)
	return profile.resolve_campaign(journey.configs[0])

## The scene controller stores preparation points as soon as they are due.
func _tick(at: float) -> void:
	sim.advance(STEP,at);clock+=STEP
	if sim.core_loop.checkpoint_pending>0:Points.capture_pending(sim,config,{"x":at,"y":430.0,"vx":0.0,"vy":0.0},codec)

func _walk(to: float) -> void:
	while absf(to-hero_x)>1.0:
		hero_x=move_toward(hero_x,to,WALK*STEP);_tick(hero_x)

func _wait(done: Callable, label: String) -> bool:
	var start:=clock
	while not done.call():
		if clock-start>LIMIT:
			marks.append([label+"（逾時）",clock]);return false
		_tick(hero_x)
	return true

func _act(key: String, at: float) -> bool:
	_walk(at)
	var ok: bool=sim.interact(at,key)
	if not ok:marks.append(["無法執行 "+key,clock])
	return ok

func _mark(label: String) -> void:
	marks.append([label,clock])

func _wanderer() -> int:
	var best:=-1
	for i in range(sim.world.people.size()):
		var p: Dictionary=sim.world.people[i]
		if p.role=="wanderer" and (best<0 or absf(p.x-hero_x)<absf(sim.world.people[best].x-hero_x)):best=i
	return best

func _tree() -> int:
	var best:=-1
	for i in range(sim.frontier.nodes.size()):
		var n: RefCounted=sim.frontier.nodes[i]
		var choice: Dictionary=sim.context_for_key(n.x,"node:%d"%i)
		if choice.get("id","")!="mark" or not choice.get("enabled",false):continue
		if best<0 or absf(n.x-sim.world.sites.hall)<absf(sim.frontier.nodes[best].x-sim.world.sites.hall):best=i
	return best

## Mark the nearest tree, then stand by the worker until the crystals reach the bag.
func _harvest() -> void:
	var tree:=_tree()
	if tree<0:_mark("找不到可委託的採集點");return
	var before: int=sim.pouch.amount
	_act("node:%d"%tree,sim.frontier.nodes[tree].x)
	_wait(func()->bool:return sim.pouch.amount>before+1,"採集入袋")

func _play() -> void:
	_act("hall",sim.world.sites.hall)
	_wait(func()->bool:return sim.frontier.city_level>0 and not sim.effects.any(func(e)->bool:return e.kind=="camp_ignition"),"點火")
	_mark("點火完成")
	var w:=_wanderer();_act("recruit:%d"%w,sim.world.people[w].x)
	_act("workshop",sim.world.sites.workshop);_act("workshop",sim.world.sites.workshop)
	_wait(func()->bool:return sim.world.people.any(func(p)->bool:return p.role=="engineer"),"工匠取錘")
	_mark("工匠就位")
	_harvest()
	_mark("首筆採集入袋（解鎖防線）")
	while sim.pouch.amount<7:_harvest()
	w=_wanderer();_act("recruit:%d"%w,sim.world.people[w].x)
	for i in range(3):_act("hunt_tools",sim.world.sites.hunt_tools)
	_wait(func()->bool:return sim.world.people.any(func(p)->bool:return p.role=="hunter"),"獵人取弓")
	_mark("弓兵就位")
	while sim.pouch.amount<3:_harvest()
	var wall_key: String=sim.context_for_key(sim.world.sites.wall,"wall:0:false").key
	for i in range(3):_act(wall_key,sim.world.sites.wall)
	_wait(func()->bool:return sim.world.walls.wall.hp>0 and not sim.world.walls.wall.pending,"城牆完工")
	_mark("右牆完工")
	if not sim.core_loop.orders.assign(sim,"wall",1):_mark("指派弓兵失敗")
	_wait(func()->bool:return sim.core_loop.stage>=2,"弓兵到位")
	_mark("首夜預告開始")
	_wait(func()->bool:return sim.clock.is_night,"入夜")
	_mark("第一夜開始")
	_wait(func()->bool:return sim.core_loop.stage>=3,"撐過第一夜")
	_mark("第一夜結束（自主白天）")
	_wait(func()->bool:return sim.clock.is_night,"第二夜")
	_mark("第二夜開始")
	_wait(func()->bool:return sim.core_loop.stage>=5,"撐過第二夜")
	_mark("引導完成")

func _report(mode: String) -> void:
	print("\n=== %s  (day %.0fs / night %.0fs)" % [mode,float(sim.clock.day_seconds),float(sim.clock.night_seconds)])
	var last:=0.0
	for m in marks:
		print("  %7.1fs  (+%6.1fs)  %s" % [m[1],m[1]-last,m[0]])
		last=m[1]
	print("  mission=%s alive=%s pouch=%d" % [sim.mission.outcome,str(sim.hero.is_alive()),sim.pouch.amount])
