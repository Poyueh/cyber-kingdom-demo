extends RefCounted
## Conserved wallet + physical rewards. Coordinates are feet positions, like actors.
const GROUND_Y := 430.0
var capacity: int
var amount: int
var drops: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var magnet_radius: float = 112.0
var magnet_speed: float = 300.0
var throw_grace: float = 2.0
var platforms: Array[Dictionary] = []
var left_boundary: float = -100000.0
var right_boundary: float = 100000.0
var _next_id := 0

func _init(limit: int = 12, starting: int = 8, start_x: float = 30.0) -> void:
	capacity = maxi(1,limit)
	amount = 0
	receive(maxi(0,starting),start_x,430)

func spend() -> bool:
	if amount<=0: return false
	amount -= 1
	return true

func receive(count: int, x: float, y: float = 430.0) -> void:
	if count<=0: return
	var stored := mini(count,capacity-amount)
	amount += stored
	drop(count-stored,x,y)

func _new_drop(count: int, x: float, y: float) -> Dictionary:
	_next_id+=1
	return {"id":_next_id,"x":x,"y":y,"amount":count,"vx":0.0,"vy":0.0,"age":0.0,"grace":0.0,"offering":false,"attracted":false}

func drop(count: int, x: float, y: float = 430.0) -> void:
	if count<=0:return
	for gem in drops:
		if not gem.offering and gem.vx==0 and gem.vy==0 and gem.grace==0 and absf(gem.x-x)<12 and absf(gem.y-y)<1:
			gem.amount+=count
			return
	drops.append(_new_drop(count,x,y))
	if drops.size()>64:_compact_resting()

func burst(count: int, x: float, y: float = 430.0) -> void:
	if drops.size()>64:_compact_resting()
	for index in range(maxi(0,count)):
		var gem := _new_drop(1,x,y-18)
		gem.vx=(float(index)-float(count-1)*0.5)*32.0
		gem.vy=-180.0-float(index%3)*22.0
		gem.grace=0.65
		drops.append(gem)

func toss(x: float, y: float, facing: int) -> bool:
	if drops.size()>64:_compact_resting()
	if not spend(): return false
	var gem := _new_drop(1,x+signf(facing)*12,y-20)
	gem.vx=signf(facing)*130.0
	gem.vy=-145.0
	gem.grace=throw_grace
	gem.offering=true
	drops.append(gem)
	return true

func advance(seconds: float, hero_x: float, hero_y: float) -> void:
	if seconds<=0 or not is_finite(seconds): return
	# Substeps keep landing and attraction stable at different frame rates.
	var target := Vector2(hero_x,hero_y)
	var reach := magnet_radius*magnet_radius
	var remaining := seconds
	while remaining>0.000001:
		var step := minf(remaining,1.0/60.0)
		var emptied := false
		for gem in drops:
			if _advance_drop(gem,step,target,reach): emptied=true
		# Rebuilding the list only matters once a pile has actually been emptied.
		if emptied: drops=drops.filter(func(gem): return gem.amount>0)
		remaining-=step

## A pile already at rest inside the world cannot move, so its fall is skipped.
func _settled(gem: Dictionary) -> bool:
	return platforms.is_empty() and gem.vx==0.0 and gem.vy==0.0 and gem.y==GROUND_Y \
		and gem.x>=left_boundary+8 and gem.x<=right_boundary-8

## Reports whether this pile was emptied by the knight.
func _advance_drop(gem: Dictionary, seconds: float, target: Vector2, reach: float) -> bool:
	gem.age+=seconds
	gem.grace=maxf(0,gem.grace-seconds)
	var at := Vector2(gem.x,gem.y)
	# Squared reach keeps a square root out of the per-pile loop.
	gem.attracted=amount<capacity and gem.grace<=0 and at.distance_squared_to(target)<=reach and absf(at.y-target.y)<48
	if gem.attracted:
		var direction := at.direction_to(target)
		gem["trail_x"]=direction.x
		gem["trail_y"]=direction.y
		at=at.move_toward(target,magnet_speed*seconds)
		gem.x=at.x
		gem.y=at.y
		gem.vx=0.0
		gem.vy=0.0
		if at.distance_to(target)<=8:
			var stored := mini(gem.amount,capacity-amount)
			amount+=stored
			gem.amount-=stored
			pickups.append({"x":target.x,"y":target.y,"amount":stored})
		return gem.amount<=0
	if _settled(gem): return false
	var next_x := clampf(gem.x+gem.vx*seconds,left_boundary+8,right_boundary-8)
	if next_x==left_boundary+8 or next_x==right_boundary-8: gem.vx=0.0
	gem.vy+=540.0*seconds
	var next_y: float=gem.y+gem.vy*seconds
	var floor_y := GROUND_Y
	for surface in platforms:
		if next_x>=surface.left and next_x<=surface.right and gem.y<=surface.y+0.1:
			floor_y=minf(floor_y,surface.y)
	gem.x=next_x
	if next_y>=floor_y and gem.vy>=0:
		gem.y=floor_y
		gem.vy=0.0
		gem.vx=move_toward(gem.vx,0,560.0*seconds)
	else: gem.y=next_y
	return false

func consume_offering(x: float, y: float) -> bool:
	for gem in drops:
		if gem.offering and gem.age>=0.3 and absf(gem.x-x)<36 and absf(gem.y-y)<16:
			gem.amount-=1
			drops=drops.filter(func(item): return item.amount>0)
			return true
	return false

func ground_total() -> int:
	var total := 0
	for pile in drops: total+=pile.amount
	return total

func _compact_resting() -> void:
	var buckets: Dictionary={}
	var compact: Array[Dictionary]=[]
	for gem in drops:
		if gem.grace>0 or not _settled(gem):
			compact.append(gem)
			continue
		var key: String="%d:%s"%[floori(gem.x/24),gem.offering]
		if buckets.has(key):buckets[key].amount+=gem.amount
		else:
			buckets[key]=gem;compact.append(gem)
	drops=compact
