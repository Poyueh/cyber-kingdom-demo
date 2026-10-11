extends RefCounted
## Creation-only route planning. Flat numeric rules are saved, never re-authored on load.
const Catalog=preload("res://domain/module_specs.gd")
const MARKER: String="level_design_version"
const PREFIX: String="level_"
const VERSION: int=1
const ROOMS_PER_SIDE: int=7
const TERRAIN: Array[StringName]=[&"forest",&"quarry",&"ruins"]
enum Role {SUPPLY, VISTA, SHRINE, TREASURE, APPROACH, MOUNT}
class Zone extends RefCounted:
	var index: int
	var side: int
	var role: int
	var kind: StringName
	var x: float
	var width: float
	func outer_anchor() -> float:
		return x+width*(0.16 if side<0 else 0.84)

static func zones(economy: Dictionary) -> Array[Zone]:
	var result: Array[Zone]=[]
	var edges: Array[float]=[float(economy.settlement_left),1800.0]
	for side_index: int in range(2):
		for depth: int in range(ROOMS_PER_SIDE):
			var i: int=side_index*ROOMS_PER_SIDE+depth
			var p: String=PREFIX+str(i)+"_"
			var zone: Zone=Zone.new()
			zone.index=i;zone.side=-1 if side_index==0 else 1
			zone.width=float(economy[p+"width"]);zone.role=int(economy[p+"role"])
			zone.kind=TERRAIN[int(economy[p+"terrain"])]
			zone.x=edges[side_index]-zone.width if side_index==0 else edges[side_index]
			edges[side_index]+=zone.side*zone.width
			result.append(zone)
	return result

static func apply(config: Dictionary, options: Dictionary, rng: RandomNumberGenerator) -> void:
	assert(valid_options(options),"Invalid authored planet routes")
	var profile: Dictionary=options.profiles[int(config.planet_id)]
	config[MARKER]=VERSION
	var economy: Dictionary=config.economy
	economy[MARKER]=VERSION
	economy.settlement_left=minf(-950.0,float(config.left_defense_x))-200.0
	for side_index: int in range(2):
		var side: String="left" if side_index==0 else "right"
		for depth: int in range(ROOMS_PER_SIDE):
			var p: String=PREFIX+str(side_index*ROOMS_PER_SIDE+depth)+"_"
			economy[p+"width"]=roundf((float(profile[side+"_widths"][depth])+rng.randf_range(-profile.width_jitter,profile.width_jitter))/10.0)*10
			economy[p+"role"]=int(profile[side+"_roles"][depth])
			economy[p+"terrain"]=int(profile[side+"_terrain"][depth])
	var rooms: Array[Zone]=zones(economy)
	var primary: Zone
	var forest_discovery: Zone
	for zone: Zone in rooms:
		if zone.role==Role.SHRINE:primary=zone
		if zone.side<0 and zone.role==Role.TREASURE:forest_discovery=zone
		if zone.role==Role.MOUNT:config.mount_distance=30.0-zone.outer_anchor()
	config.ruin_spacing=profile.station_spacing
	config.level_trial_module=0 if int(config.planet_id)==0 else int(config.planet_id)+1
	for spec: Catalog.Spec in Catalog.build(config):
		if spec.planet!=int(config.planet_id):continue
		var zone: Zone=forest_discovery if spec.id=="lance" else primary
		var p: String="level_module_"+spec.id+"_"
		config[p+"region"]=zone.index
		config[p+"x"]=zone.x+zone.width*0.82 if spec.id=="lance" else zone.outer_anchor()
	assert(valid_config(config),"Generated level must keep rewards and controls in authored rooms")

static func is_supply(region: Dictionary) -> bool:
	return not region.has("level_role") or int(region.level_role)==Role.SUPPLY

static func has_puzzle(config: Dictionary, id: String) -> bool:
	return not config.has(MARKER) or Catalog.IDS[int(config.level_trial_module)]==id

static func _number(value: Variant, lo: float, hi: float, whole: bool=false) -> bool:
	if not (value is float or value is int) or not is_finite(float(value)):return false
	return value>=lo and value<=hi and (not whole or floorf(float(value))==float(value))

static func valid_options(options: Dictionary) -> bool:
	if options.size()!=2 or not _number(options.get("version"),VERSION,VERSION,true) or not options.get("profiles") is Array or options.profiles.size()!=7:return false
	for planet: int in range(7):
		var p: Variant=options.profiles[planet]
		if not p is Dictionary or p.size()!=9 or not _number(p.get("planet_id"),planet,planet,true):return false
		if not _number(p.get("width_jitter"),0,50) or not _number(p.get("station_spacing"),180,220):return false
		var roles: Array[int]=[]
		for side: String in ["left","right"]:
			for field: String in ["roles","terrain","widths"]:
				if not p.get(side+"_"+field) is Array or p[side+"_"+field].size()!=ROOMS_PER_SIDE:return false
			for i: int in range(ROOMS_PER_SIDE):
				var role: Variant=p[side+"_roles"][i]
				if not _number(role,Role.SUPPLY,Role.MOUNT,true) or not _number(p[side+"_terrain"][i],0,2,true):return false
				if not _number(p[side+"_widths"][i],500,1300):return false
				if i==0 and role!=Role.SUPPLY or i==ROOMS_PER_SIDE-1 and role!=Role.APPROACH:return false
				if role in [Role.SHRINE,Role.MOUNT] and p[side+"_widths"][i]<1050:return false
				roles.append(int(role))
		if roles.count(Role.SHRINE)!=1 or roles.count(Role.TREASURE)!=2 or roles.count(Role.MOUNT)!=(1 if planet==0 else 0):return false
	return true

static func valid_config(config: Dictionary) -> bool:
	if config.has("level_design"):return false
	var economy: Variant=config.get("economy",{})
	if not economy is Dictionary:return false
	var active: bool=config.has(MARKER)
	if not active:
		return not config.keys().any(func(key: String)->bool:return key.begins_with(PREFIX)) and not economy.keys().any(func(key: String)->bool:return key.begins_with(PREFIX))
	if not _number(config.get(MARKER),VERSION,VERSION,true) or not _number(economy.get(MARKER),VERSION,VERSION,true):return false
	if not _number(config.get("ruin_enabled"),1,1,true) or not _number(config.get("module_catalog_version"),1,1,true):return false
	if not _number(config.get("planet_id"),0,6,true) or not _number(config.get("left_defense_x"),-1200,-950):return false
	var settlement: float=minf(-950.0,float(config.left_defense_x))-200.0
	if not _number(economy.get("settlement_left"),settlement,settlement):return false
	var allowed_economy: Array[String]=[MARKER]
	for index: int in range(ROOMS_PER_SIDE*2):
		var p: String=PREFIX+str(index)+"_"
		if not _number(economy.get(p+"width"),450,1350):return false
		if not _number(economy.get(p+"role"),Role.SUPPLY,Role.MOUNT,true):return false
		if not _number(economy.get(p+"terrain"),0,2,true):return false
		for suffix: String in ["width","role","terrain"]:allowed_economy.append(p+suffix)
	for key: String in economy:
		if key.begins_with(PREFIX) and not allowed_economy.has(key):return false
	var rooms: Array[Zone]=zones(economy)
	var roles: Array[int]=[]
	for zone: Zone in rooms:
		roles.append(zone.role)
		if zone.index%ROOMS_PER_SIDE==0 and zone.role!=Role.SUPPLY:return false
		if zone.index%ROOMS_PER_SIDE==ROOMS_PER_SIDE-1 and (zone.role!=Role.APPROACH or zone.width<750):return false
		if zone.role in [Role.SHRINE,Role.MOUNT] and zone.width<1000:return false
	if roles.count(Role.SHRINE)!=1 or roles.count(Role.TREASURE)!=2 or roles.count(Role.MOUNT)!=(1 if config.planet_id==0 else 0):return false
	var trial: int=0 if config.planet_id==0 else int(config.planet_id)+1
	if not _number(config.get("level_trial_module"),trial,trial,true):return false
	if not _number(config.get("ruin_spacing"),180,220):return false
	var allowed: Array[String]=[MARKER,"level_trial_module"]
	for spec: Catalog.Spec in Catalog.build(config):
		if spec.planet!=config.planet_id:continue
		var p: String="level_module_"+spec.id+"_"
		allowed.append(p+"region");allowed.append(p+"x")
		if not _number(config.get(p+"region"),0,rooms.size()-1,true):return false
		var zone: Zone=rooms[int(config[p+"region"])]
		if zone.role!=(Role.TREASURE if spec.id=="lance" else Role.SHRINE):return false
		if not _number(config.get(p+"x"),zone.x+100,zone.x+zone.width-100):return false
		if spec.id!="lance":
			var inner: float=config[p+"x"]-zone.side*config.ruin_spacing*3
			if inner<zone.x+100 or inner>zone.x+zone.width-100:return false
	for zone: Zone in rooms:
		if zone.role==Role.MOUNT:
			if not _number(config.get("mount_distance"),1800,3800) or not _number(config.get("mount_spacing"),240,400):return false
			var at: float=30.0-config.mount_distance
			if at<zone.x+100 or at+config.mount_spacing*2>zone.x+zone.width-100:return false
	for key: String in config:
		if key.begins_with(PREFIX) and not allowed.has(key):return false
	return true
