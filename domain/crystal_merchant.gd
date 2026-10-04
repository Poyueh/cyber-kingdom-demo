extends RefCounted
## One trader, one first gift, and one funded delivery per trip. No engine I/O.
const Clock = preload("res://domain/time/tick_clock.gd")
enum Phase {DORMANT, APPROACHING, WAITING_PAYMENT, OUTBOUND, AWAY, RETURNING, READY}
const CONFIG_RANGES: Dictionary = {
	"merchant_enabled":Vector2(0,1),"merchant_delivery":Vector2(1,12),"merchant_cost":Vector2(1,12),
	"merchant_speed":Vector2(20,200),"merchant_radius":Vector2(30,120),"merchant_approach":Vector2(300,1200),
	"merchant_trip":Vector2(300,1200),"merchant_offset":Vector2(100,600),"treasure_limit":Vector2(0,5),
	"treasure_camp_distance":Vector2(1000,5000),"treasure_spacing":Vector2(1000,5000)}
var rules: Dictionary
var enabled: bool
var home_x: float
var left_x: float
var right_x: float
var x: float
var phase: int = Phase.DORMANT
var last_tick: int = 0
var return_day: int = 0
var facing: int = 1
var walk_distance: float = 0.0
var moving: bool = false

func _init(config: Dictionary, camp_x: float, left: float, right: float) -> void:
	rules=config
	enabled=int(config.get("merchant_enabled",0))==1
	home_x=camp_x+float(config.merchant_offset) if enabled else camp_x
	left_x=left;right_x=right;x=home_x

static func valid_config(config: Dictionary) -> bool:
	if not CONFIG_RANGES.keys().any(func(key: String) -> bool: return config.has(key)):return true
	for key: String in CONFIG_RANGES:
		var value: Variant=config.get(key)
		if not (value is int or value is float):return false
		if not is_finite(float(value)) or value<CONFIG_RANGES[key].x or value>CONFIG_RANGES[key].y:return false
		if key in ["merchant_enabled","merchant_delivery","merchant_cost","treasure_limit"] and value!=floorf(value):return false
	return true

func visible() -> bool:
	return enabled and phase not in [Phase.DORMANT,Phase.AWAY]

func can_dispatch() -> bool:
	return enabled and phase==Phase.WAITING_PAYMENT

func dispatch(day: int) -> bool:
	if not can_dispatch():return false
	phase=Phase.OUTBOUND;return_day=day+1
	return true

func carrying_reward() -> bool:
	return enabled and phase in [Phase.APPROACHING,Phase.READY,Phase.RETURNING]

func advance(now_tick: int, day: int, knight_x: float, knight_y: float, empty_pouch: bool) -> int:
	var ticks: int=maxi(0,now_tick-last_tick)
	last_tick=maxi(last_tick,now_tick)
	moving=false
	if not enabled or ticks==0:return 0
	if phase==Phase.DORMANT:
		if empty_pouch:
			var approach: float=float(rules.merchant_approach)
			x=knight_x-approach if knight_x-left_x>=approach else minf(right_x,knight_x+approach)
			phase=Phase.APPROACHING
		return 0
	var destination: float=x
	match phase:
		Phase.APPROACHING:destination=knight_x
		Phase.WAITING_PAYMENT,Phase.RETURNING:destination=home_x
		Phase.OUTBOUND:destination=minf(right_x,home_x+float(rules.merchant_trip))
		Phase.AWAY:
			if day>=return_day:phase=Phase.RETURNING
	_move(destination,ticks)
	if phase==Phase.OUTBOUND and is_equal_approx(x,destination):phase=Phase.AWAY
	if phase==Phase.RETURNING and is_equal_approx(x,home_x):phase=Phase.READY
	if phase in [Phase.APPROACHING,Phase.READY] and absf(x-knight_x)<=float(rules.merchant_radius) and absf(knight_y-430.0)<40:
		phase=Phase.WAITING_PAYMENT
		return int(rules.merchant_delivery)
	return 0

func _move(destination: float, ticks: int) -> void:
	var next_x: float=move_toward(x,destination,float(rules.merchant_speed)*ticks/Clock.TICKS_PER_SECOND)
	moving=not is_equal_approx(next_x,x)
	if moving:facing=1 if next_x>x else -1
	walk_distance+=absf(next_x-x)
	x=next_x

func capture() -> Dictionary:
	return {"phase":phase,"x":x,"last_tick":last_tick,"return_day":return_day,"facing":facing,"walk_distance":walk_distance,"moving":moving}

func restore(data: Variant, now_tick: int, day: int) -> bool:
	if not data is Dictionary or data.size()!=7:return false
	for key: String in ["phase","last_tick","return_day","facing"]:
		if not data.get(key) is int:return false
	for key: String in ["x","walk_distance"]:
		if not (data.get(key) is int or data.get(key) is float) or not is_finite(float(data[key])):return false
	if not data.get("moving") is bool:return false
	if data.phase<Phase.DORMANT or data.phase>Phase.READY or data.facing not in [-1,1]:return false
	if data.x<left_x or data.x>right_x or data.walk_distance<0:return false
	if data.last_tick<0 or data.last_tick>now_tick+1 or data.return_day<0 or data.return_day>day+1:return false
	if data.phase in [Phase.OUTBOUND,Phase.AWAY,Phase.RETURNING,Phase.READY] and data.return_day<2:return false
	if data.phase in [Phase.DORMANT,Phase.APPROACHING] and data.return_day!=0:return false
	if data.phase in [Phase.RETURNING,Phase.READY,Phase.WAITING_PAYMENT] and data.return_day>day:return false
	if data.phase==Phase.READY and not is_equal_approx(float(data.x),home_x):return false
	if not enabled and data.phase!=Phase.DORMANT:return false
	phase=data.phase;x=data.x;last_tick=data.last_tick;return_day=data.return_day
	facing=data.facing;walk_distance=data.walk_distance;moving=data.moving
	return true
