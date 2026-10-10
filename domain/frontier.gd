extends RefCounted
## Seeded, passable region templates and finite harvests, independent of scenes.
const Harvest = preload("res://domain/harvest_node.gd")
var regions: Array[Dictionary] = []
var nodes: Array[RefCounted] = []
var animals: Array[Dictionary] = []
var left_boundary := -700.0
var right_boundary := 1800.0
var wood: int = 0
var food: int = 0
var stone: int = 0
var herbs: int = 0
var city_level: int = 1
var farm_active := false
var farm_progress := 0.0
var drill_level: int = 0

var farm_cycle := 12.0
var farm_yield := 2
var training_food := 2
var training_damage := 5
var training_limit := 3
var work_seconds := 6.0
var outpost_seconds := 5.0

func _init(map_seed: int, rules: Dictionary = {}) -> void:
	left_boundary=float(rules.get("settlement_left",-700.0))
	work_seconds = maxf(0.1,float(rules.get("work_seconds",6.0)))
	outpost_seconds = maxf(0.1,float(rules.get("outpost_seconds",5.0)))
	farm_cycle = maxf(0.1,float(rules.get("farm_cycle",12.0)))
	farm_yield = maxi(1,int(rules.get("farm_yield",2)))
	training_food = maxi(1,int(rules.get("training_food",2)))
	training_damage = maxi(1,int(rules.get("training_damage",5)))
	training_limit = maxi(1,int(rules.get("training_limit",3)))
	var rng := RandomNumberGenerator.new()
	rng.seed = map_seed
	var types := ["forest","forest","quarry","quarry","ruins","ruins"]
	var biome: int=int(rules.get("planet_id",0))
	if biome>0:rng=preload("res://domain/rng/rng_streams.gd").new(map_seed).of(preload("res://domain/rng/rng_streams.gd").Stream.WORLD)
	if biome==1:types=["forest","quarry","quarry","quarry","ruins","ruins"]
	if biome==3:types=["forest","forest","forest","quarry","ruins","ruins"]
	if biome==4:types=["forest","quarry","quarry","quarry","quarry","ruins"]
	if biome==5:types=["forest","quarry","ruins","ruins","ruins","ruins"]
	if biome==6:types=["forest","forest","quarry","quarry","ruins","ruins"]
	if biome==2:types=["forest","forest","quarry","ruins","ruins","ruins"]
	for index in range(types.size()-1,0,-1):
		var swap := rng.randi_range(0,index)
		var kind: String = types[index]
		types[index] = types[swap]
		types[swap] = kind
	for index in range(types.size()):
		var width := float(rng.randi_range(4,6)*100)
		var x := right_boundary
		if index < 3:
			left_boundary -= width
			x = left_boundary
		else:
			right_boundary += width
		regions.append({"kind":types[index],"x":x,"width":width,"discovered":false,"outpost_x":0.0,"outpost_ready":false,"outpost_pending":false,"outpost_built":false,"outpost_progress":0.0})
		_populate(index,types[index],x,width,rng)
	# Keep the original six regions and random sequence intact for legacy saves.
	var extra:=clampi(int(rules.get("outer_regions_per_side",0)),0,8)
	for side in [-1,1]:
		var outer_types: Array=["forest","quarry","ruins"]
		for i in range(2,0,-1):
			var swap:=rng.randi_range(0,i)
			var kind: String=outer_types[i]
			outer_types[i]=outer_types[swap]
			outer_types[swap]=kind
		for depth in range(extra):
			var width:=float(rng.randi_range(6,9)*100)
			var x:=right_boundary
			if side<0:
				left_boundary-=width
				x=left_boundary
			else:right_boundary+=width
			var kind: String=outer_types[depth%3]
			var index:=regions.size()
			regions.append({"kind":kind,"x":x,"width":width,"discovered":false,"outpost_x":0.0,"outpost_ready":false,"outpost_pending":false,"outpost_built":false,"outpost_progress":0.0})
			_populate(index,kind,x,width,rng)

	if rules.get("flat_ground",0):
		for node in nodes:node.y=430.0;node.pickup_y=430.0

func _populate(index: int, kind: String, x: float, width: float, rng: RandomNumberGenerator) -> void:
	match kind:
		"forest":
			for tree in range(4):
				_add(index,"tree",x+50+tree*(width-100)/3.0+rng.randf_range(-10,10),430,3,0,1 if tree == 0 else 0,0)
			_add(index,"berries",x+width*0.5,430,0,2,0,0)
			for animal in range(2):
				animals.append({"x":x+90+animal*(width-180),"region":index,"alive":true})
		"quarry":
			_add(index,"crystal",x+width*0.3,430,0,0,2,0)
			_add(index,"crystal",x+width*0.7,430,0,0,2,0)
		"ruins":
			_add(index,"cache",x+width*0.35,366,0,0,0,4)
			_add(index,"cache",x+width*0.75,430,0,0,0,4)
func _add(region_index: int, kind: String, x: float, y: float, timber: int, rations: int, crystal: int, salvage: int) -> void:
	var node := Harvest.new()
	node.region = region_index
	node.kind = kind
	node.x = x
	node.y = y
	node.pickup_x = x
	node.pickup_y = y
	node.wood = timber
	node.food = rations
	node.crystals = crystal
	node.scrap = salvage
	nodes.append(node)

func layout_signature() -> String:
	var layout: Array = []
	for node in nodes: layout.append([node.kind,node.x,node.y,node.wood,node.food,node.crystals,node.scrap])
	return str(layout)

func reveal(x: float) -> void:
	for region in regions:
		if x >= region.x-100 and x <= region.x+region.width+100: region.discovered = true

func discovered_count() -> int:
	var count := 0
	for region in regions:
		if region.discovered: count += 1
	return count

func collect(node: RefCounted) -> Dictionary:
	if not nodes.has(node) or node.remaining_work > 0 or node.collected:
		return {}
	node.collected = true
	return {"wood":node.wood,"food":node.food,"crystals":node.crystals,"scrap":node.scrap}

func mark(node: RefCounted) -> bool:
	if not nodes.has(node) or node.marked or node.collected or not regions[node.region].discovered: return false
	node.marked = true
	return true

func deposit(node: RefCounted) -> Dictionary:
	if not nodes.has(node) or not node.collected or node.delivered: return {}
	node.delivered = true
	node.carried = false
	node.worker = -1
	wood += node.wood
	food += node.food
	stone += node.stone
	herbs += node.herbs
	var region := regions[node.region]
	if not region.outpost_ready:
		region.outpost_ready = true
		region.outpost_x = node.x
	return {"crystals":node.crystals,"scrap":node.scrap}

func expansion_cleared(index: int) -> bool:
	if index<0 or index>=regions.size() or not regions[index].discovered:return false
	# Buildings appear only after the finite terrain resources have actually been removed.
	return not nodes.any(func(n):return n.region==index and n.kind in ["tree","crystal","stone","cache"] and not n.collected)

func order_outpost(index: int, available_scrap: int) -> int:
	if index<0 or index>=regions.size(): return 0
	var region := regions[index]
	if not region.outpost_ready or region.outpost_pending or region.outpost_built or available_scrap<3: return 0
	region.outpost_pending = true
	return 3

func work_outpost(index: int, seconds: float) -> bool:
	if seconds<=0 or not is_finite(seconds) or index<0 or index>=regions.size(): return false
	var region := regions[index]
	if not region.outpost_pending: return false
	region.outpost_progress += seconds
	if region.outpost_progress>=outpost_seconds:
		region.outpost_built = true
		region.outpost_pending = false
	return true

func outpost_count() -> int:
	var count := 0
	for region in regions:
		if region.outpost_built: count += 1
	return count

func plant() -> bool:
	if farm_active or wood < 2 or food < 1: return false
	wood -= 2
	food -= 1
	farm_active = true
	return true

func advance_farm(seconds: float, workers: int) -> void:
	if not farm_active or workers <= 0 or seconds <= 0 or not is_finite(seconds): return
	farm_progress += seconds*workers
	while farm_progress >= farm_cycle:
		farm_progress -= farm_cycle
		food += farm_yield # Net surplus after retaining seed for the next crop.

func city_cost() -> Dictionary:
	return {"wood":8,"food":4,"scrap":4} if city_level == 1 else {"wood":12,"food":6,"scrap":8}

func upgrade_city(available_scrap: int) -> int:
	var cost := city_cost()
	if city_level >= 3 or wood < cost.wood or food < cost.food or available_scrap < cost.scrap: return 0
	wood -= cost.wood
	food -= cost.food
	city_level += 1
	return cost.scrap
