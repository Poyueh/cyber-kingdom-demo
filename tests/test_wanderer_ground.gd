extends RefCounted
## Players saw wanderers waiting under trees, half hidden by the canopy. Wanderers wait,
## arrive and stroll on open ground: their body never overlaps a standing tree's sprite.
const Campaign=preload("res://application/campaign_session.gd")
const Setup=preload("res://application/journey_setup.gd")
const Details=preload("res://presentation/frontier_details.gd")
const Scenery=preload("res://presentation/planet_scenery.gd")
const Layout=preload("res://application/core_loop_layout.gd")
const STEP: float=1.0/30.0
## About 28 px of a resident's 64 px frame is body.
const BODY_HALF: float=14.0
## Leaves sway up to 3 px in the wind.
const SWAY: float=3.0
## A body touching the canopy's edge is beside the tree, not under it.
const TOUCH: float=0.01
const SEEDS: Array[int]=[1054,7,4242,99]
const WORLDS: Array[String]=["forest","desert","frost","swamp","volcanic","storm","void"]

func base(seed: int) -> Dictionary:
	var tuning: Resource=load("res://data/campaign.tres")
	var config: Dictionary=tuning.campaign_rules()
	config.merge({"seed":seed,"economy":tuning.economy_rules()},true)
	config.level_design=load("res://data/planet_levels.tres").rules()
	config.trail_design=load("res://data/trail_encounters.tres").rules()
	config.ruin_variation=load("res://data/ruin_variation.tres").rules()
	return config

func demo(seed: int) -> RefCounted:
	var forest: Resource=load("res://data/planets/forest.tres")
	var config: Dictionary=Setup.create_forest(base(seed),forest.rules(),load("res://data/journey_paces.tres").find(0).rules())
	config.merge(Setup.gate_rules(forest),true)
	return Campaign.new(load("res://data/core_loop.tres").resolve_demo(config))

## Every world of a guided main journey, as the main game creates them.
func journey(seed: int) -> Array[RefCounted]:
	var profiles: Array[Dictionary]=[]
	for name: String in WORLDS:profiles.append(load("res://data/planets/"+name+".tres").rules())
	var trip: RefCounted=Setup.create(base(seed),profiles,load("res://data/journey_paces.tres").find(0).rules())
	var worlds: Array[RefCounted]=[]
	for id: int in range(trip.configs.size()):
		var config: Dictionary=trip.configs[id].duplicate(true)
		config.merge(Setup.gate_rules(load("res://data/planets/"+WORLDS[id]+".tres")),true)
		worlds.append(Campaign.new(load("res://data/core_loop.tres").resolve_campaign(config)))
	return worlds

func canopy(sim: RefCounted, node: RefCounted) -> float:
	var texture: Texture2D=Scenery.TREE[sim.planet.id-1] if sim.planet.enabled and sim.planet.id>0 else Details.harvest_texture("tree",node.x,sim.map_seed)
	return texture.get_width()*0.5+SWAY

## Trees whose sprite a wanderer standing at x would overlap, as "x@tree".
func under_trees(sim: RefCounted, x: float) -> Array[String]:
	var hits: Array[String]=[]
	for node: RefCounted in sim.frontier.nodes:
		if node.kind!="tree" or node.collected:continue
		if absf(node.x-x)<canopy(sim,node)+BODY_HALF-TOUCH:hits.append("%.0f@%.0f"%[x,node.x])
	return hits

func wanderers_under_trees(sim: RefCounted) -> Array[String]:
	var hits: Array[String]=[]
	for person: Dictionary in sim.world.people:
		if person.role=="wanderer":hits.append_array(under_trees(sim,person.x))
	return hits

## Squeezed between two canopies with less than one more body width of room.
func wedged(sim: RefCounted) -> Array[String]:
	var hits: Array[String]=[]
	for person: Dictionary in sim.world.people:
		if person.role!="wanderer":continue
		var left: bool=false
		var right: bool=false
		for node: RefCounted in sim.frontier.nodes:
			if node.kind!="tree" or node.collected:continue
			var room: float=canopy(sim,node)+BODY_HALF*3.0
			if node.x<person.x and person.x-node.x<room:left=true
			if node.x>person.x and node.x-person.x<room:right=true
		if left and right:hits.append("%.0f"%person.x)
	return hits

func test_new_worlds_place_wanderers_on_open_ground(t):
	for seed: int in SEEDS:
		t.equal(wanderers_under_trees(demo(seed)),[] as Array[String],"Demo forest (seed %d): no wanderer starts under a tree"%seed)
		t.equal(wedged(demo(seed)),[] as Array[String],"Demo forest (seed %d): no wanderer is wedged between two trees"%seed)
		var worlds: Array[RefCounted]=journey(seed)
		for id: int in range(worlds.size()):
			t.equal(wanderers_under_trees(worlds[id]),[] as Array[String],"%s (seed %d): no wanderer starts under a tree"%[WORLDS[id],seed])
			t.equal(wedged(worlds[id]),[] as Array[String],"%s (seed %d): no wanderer is wedged between two trees"%[WORLDS[id],seed])

func test_the_forest_keeps_a_wanderer_waiting_outside_each_wall(t):
	for seed: int in SEEDS:
		var sim: RefCounted=demo(seed)
		var west: bool=false
		var east: bool=false
		for person: Dictionary in sim.world.people:
			if person.role!="wanderer":continue
			# The discovered camp ring reaches 300 px past the west wall and 440 past the east one.
			west=west or (person.x<Layout.LEFT_WALL and person.x>Layout.LEFT_WALL-300)
			east=east or (person.x>Layout.RIGHT_WALL and person.x<Layout.RIGHT_WALL+440)
		t.truth(west and east,"seed %d: a wanderer still waits in the wild beyond each wall"%seed)

func test_dawn_arrivals_wait_on_open_ground(t):
	for seed: int in SEEDS:
		for sim: RefCounted in [demo(seed)]+journey(seed).slice(1,4):
			var hits: Array[String]=[]
			for day: int in range(2,6):
				for arrival: Dictionary in sim.ecology.renew(day,sim.world.people):
					hits.append_array(under_trees(sim,arrival.x))
					sim._add_person(arrival.x,arrival.region)
			t.equal(hits,[] as Array[String],"seed %d planet %d: newcomers arrive beside the trees, not under them"%[seed,sim.planet.id])

func test_strolling_wanderers_stay_out_from_under_trees(t):
	var sim: RefCounted=demo(1054)
	var away: float=sim.world.sites.hall
	var hits: Array[String]=[]
	for i: int in range(roundi(60.0/STEP)):
		sim.advance(STEP,away)
		if i%15==0:hits.append_array(wanderers_under_trees(sim))
	t.equal(hits,[] as Array[String],"a minute of strolling never takes a wanderer under a tree")

func test_a_wanderer_left_under_a_tree_walks_out_into_the_open(t):
	var sim: RefCounted=demo(1054)
	var tree: RefCounted=null
	for node: RefCounted in sim.frontier.nodes:
		if node.kind=="tree" and node.x<sim.world.sites.wall_left:tree=node;break
	t.truth(tree!=null,"a wild tree stands beyond the west wall")
	if tree==null:return
	var index: int=-1
	for i: int in range(sim.world.people.size()):
		if sim.world.people[i].role=="wanderer":index=i;break
	var person: Dictionary=sim.world.people[index]
	# As when a resident is knocked back to wanderer while standing under the tree.
	person.x=tree.x;person.erase("roam_role")
	for i: int in range(roundi(20.0/STEP)):sim.advance(STEP,sim.world.sites.hall)
	t.equal(under_trees(sim,person.x),[] as Array[String],"they walk out from under the tree")
	t.truth(absf(person.x-tree.x)<=240,"and stay near where they were (%.0f px away)"%absf(person.x-tree.x))

## Saved worlds are rebuilt from their seed and must match it tree for tree. These records
## were saved by v0.0.76, before wanderers looked for clearings.
func test_guided_forest_records_from_before_still_load(t):
	var codec: RefCounted=preload("res://application/campaign_snapshot.gd").new()
	for edition: String in ["demo","main"]:
		var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/guided-forest-v24-%s.json"%edition))
		var restored: Dictionary=codec.restore(raw)
		t.truth(not restored.is_empty(),"a v0.0.76 %s forest record still loads (%s)"%[edition,codec.last_error])
		if restored.is_empty():continue
		var sim: RefCounted=restored.session
		var trees: int=sim.frontier.nodes.filter(func(node: RefCounted)->bool:return node.kind=="tree").size()
		t.equal(trees,raw.nodes.filter(func(node: Dictionary)->bool:return node.kind=="tree").size(),"%s: it keeps every tree it was saved with"%edition)
		for i: int in range(roundi(20.0/STEP)):sim.advance(STEP,sim.world.sites.hall)
		var west: Array[String]=[]
		for person: Dictionary in sim.world.people:
			if person.role=="wanderer" and person.x>Layout.LEFT_WALL-Layout.WILD_RING and person.x<Layout.RIGHT_WALL+Layout.WILD_RING:west.append_array(under_trees(sim,person.x))
		t.equal(west,[] as Array[String],"%s: its camp's wild wanderers walk out from under the trees"%edition)

## Worlds made before the forest clearing have woods with no open ground at all. Their
## newcomers keep to their own region, where dawn still counts them as waiting.
func test_newcomers_in_a_dense_old_wood_stay_in_their_region(t):
	var old: Dictionary=base(1054)
	old.economy.erase("forest_clearing")
	var profiles: Array[Dictionary]=[]
	for name: String in WORLDS:profiles.append(load("res://data/planets/"+name+".tres").rules())
	var trip: RefCounted=Setup.create(old,profiles,load("res://data/journey_paces.tres").find(0).rules())
	var config: Dictionary=trip.configs[3].duplicate(true)
	config.merge(Setup.gate_rules(load("res://data/planets/swamp.tres")),true)
	var sim: RefCounted=Campaign.new(load("res://data/core_loop.tres").resolve_campaign(config))
	t.truth(not sim.ecology.gathering.clearing,"the world is laid out as before the clearing")
	for arrival: Dictionary in sim.ecology.renew(2,sim.world.people):sim._add_person(arrival.x,arrival.region)
	for i: int in range(roundi(30.0/STEP)):sim.advance(STEP,sim.world.sites.hall)
	var strays: Array[String]=[]
	for person: Dictionary in sim.world.people:
		var index: int=person.get("region",-1)
		if person.role!="wanderer" or index<0:continue
		var region: Dictionary=sim.frontier.regions[index]
		if person.x<region.x or person.x>region.x+region.width or absf(person.x-sim.ecology.gathering_x(index))>=160:strays.append("%.0f (region %d)"%[person.x,index])
	t.equal(strays,[] as Array[String],"newcomers stay where dawn counts them")
