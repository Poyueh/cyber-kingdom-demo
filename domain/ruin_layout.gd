extends RefCounted
## Creation-only generation. Resolved numbers are saved; no reroll occurs on load.
const Mechanism=preload("res://domain/ruin_mechanism.gd")
const VERSION: int=1
const MARKER: String="ruin_layout_version"

static func apply(config: Dictionary, options: Dictionary, rng: RandomNumberGenerator) -> void:
	assert(valid_options(options),"Invalid ruin variation tuning")
	assert(Mechanism.valid_config(config),"Invalid authored mechanism catalogue")
	config[MARKER]=VERSION
	var planet: int=int(config.planet_id)
	if planet==0:return
	var prefix: String=Mechanism.PREFIX+str(planet)+"_"
	match int(config[prefix+"kind"]):
		Mechanism.Kind.CIRCUIT:_circuit(config,prefix,options,rng)
		Mechanism.Kind.BALANCE:_balance(config,prefix,options,rng)
		Mechanism.Kind.PULSE:_pulse(config,prefix,options,rng)
	assert(Mechanism.valid_config(config),"Generated ruin must remain solvable")

static func _shuffle(items: Array[int], rng: RandomNumberGenerator) -> void:
	for i: int in range(items.size()-1,0,-1):
		var other: int=rng.randi_range(0,i)
		var previous: int=items[i];items[i]=items[other];items[other]=previous

static func _circuit(config: Dictionary, p: String, options: Dictionary, rng: RandomNumberGenerator) -> void:
	var controls: Array[int]=[0,1,2];var lamps: Array[int]=[0,1,2]
	_shuffle(controls,rng);_shuffle(lamps,rng)
	var masks: Array[int]=[]
	for index: int in controls:
		var original: int=int(config[p+"mask_"+str(index)]);var mapped: int=0
		for bit: int in range(3):
			if original&(1<<bit):mapped|=1<<lamps[bit]
		masks.append(mapped)
	var starts: Array[int]=[]
	for start: int in range(7):
		var shortest: int=4
		for presses: int in range(8):
			var value: int=start;var count: int=0
			for i: int in range(3):
				if presses&(1<<i):value^=masks[i];count+=1
			if value==7:shortest=mini(shortest,count)
		if shortest>=options.circuit_minimum and shortest<=options.circuit_maximum:starts.append(start)
	assert(not starts.is_empty(),"No circuit satisfies the requested move range")
	config[p+"initial"]=starts[rng.randi_range(0,starts.size()-1)]
	for index: int in range(3):config[p+"mask_"+str(index)]=masks[index]

static func _balance(config: Dictionary, p: String, options: Dictionary, rng: RandomNumberGenerator) -> void:
	var lo: int=int(config[p+"minimum"]);var hi: int=int(config[p+"maximum"])
	var up: int=int(config[p+"warm"]);var down: int=int(config[p+"cool"])
	var original_sign: int=signi(int(config[p+"initial"]))
	var choices: Array[Vector2i]=[]
	for start: int in range(lo,hi+1):
		if signi(start)!=original_sign:continue
		for goal: int in range(maxi(lo,-options.balance_target_radius),mini(hi,options.balance_target_radius)+1):
			var difference: int=goal-start
			if difference==0 or (difference>0 and difference%up==0) or (difference<0 and difference%down==0):continue
			var distance: int=_distance(start,goal,lo,hi,up,down)
			if distance>=options.balance_minimum and distance<=options.balance_maximum:choices.append(Vector2i(start,goal))
	assert(not choices.is_empty(),"No balance puzzle satisfies both-control requirement")
	var chosen: Vector2i=choices[rng.randi_range(0,choices.size()-1)]
	config[p+"initial"]=chosen.x;config[p+"target"]=chosen.y

static func _distance(start: int, goal: int, lo: int, hi: int, up: int, down: int) -> int:
	var values: Array[int]=[start];var distances: Array[int]=[0];var cursor: int=0
	while cursor<values.size():
		var value: int=values[cursor];var distance: int=distances[cursor];cursor+=1
		for change: int in [up,down]:
			var next: int=value+change
			if next<lo or next>hi or values.has(next):continue
			if next==goal:return distance+1
			values.append(next);distances.append(distance+1)
	return -1

static func _pulse(config: Dictionary, p: String, options: Dictionary, rng: RandomNumberGenerator) -> void:
	var period: float=float(options.pulse_periods[rng.randi_range(0,options.pulse_periods.size()-1)])
	var slots: Array[int]=[]
	for i: int in range(roundi(period/options.pulse_step)):slots.append(i)
	_shuffle(slots,rng);config[p+"period"]=period
	for i: int in range(3):config[p+"offset_"+str(i)]=slots[i]*float(options.pulse_step)

static func valid_options(options: Dictionary) -> bool:
	if options.size()!=8:return false
	var limits: Dictionary={"version":Vector2(1,1),"circuit_minimum":Vector2(2,3),"circuit_maximum":Vector2(2,3),"balance_minimum":Vector2(3,6),"balance_maximum":Vector2(3,6),"balance_target_radius":Vector2(1,4),"pulse_step":Vector2(0.25,2)}
	for key: String in limits:
		var value: Variant=options.get(key)
		if not (value is int or value is float) or not is_finite(float(value)):return false
		if value<limits[key].x or value>limits[key].y:return false
		if key!="pulse_step" and floorf(value)!=value:return false
	if options.circuit_minimum>options.circuit_maximum or options.balance_minimum>options.balance_maximum:return false
	if not options.get("pulse_periods") is Array or options.pulse_periods.is_empty() or options.pulse_periods.size()>6:return false
	for value: Variant in options.pulse_periods:
		if not (value is int or value is float) or not is_finite(float(value)) or value<4 or value>12:return false
		if value/options.pulse_step<3 or not is_equal_approx(value/options.pulse_step,roundf(value/options.pulse_step)):return false
	return true
