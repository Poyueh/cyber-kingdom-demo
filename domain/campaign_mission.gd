extends RefCounted
## Run outcome and strategic health; no engine nodes or external I/O.
var core_max_hp: int
var core_hp: int
var core_recharge: int
var outcome := "active"
var defeat_reason := ""
var rifts: Array[Dictionary] = []
var dragon_summoned:=false
var dragon_defeated:=false
var dragon_day:=0
var dragon_rules: Dictionary
var seal_seconds: float
func _init(config: Dictionary = {}) -> void:
	dragon_rules=preload("res://domain/dragon_rules.gd").tuning(config)
	seal_seconds=maxf(0.1,float(config.get("rift_seal_seconds",8.0)))
	core_max_hp=maxi(1,int(config.get("core_max_hp",180)))
	core_hp=core_max_hp
	core_recharge=maxi(1,int(config.get("core_recharge",60)))
func damage_core(amount: int) -> void:
	if outcome!="active" or amount<=0:return
	core_hp=maxi(0,core_hp-amount)
func recharge_core() -> void:
	if outcome!="active" or core_hp<=0:return
	core_hp=mini(core_max_hp,core_hp+core_recharge)
func resolve(knight_alive: bool, enemies_cleared: bool) -> void:
	if outcome!="active":return
	if not knight_alive or core_hp<=0:
		outcome="defeat"
		defeat_reason="knight" if not knight_alive else "core"
	elif not rifts.is_empty() and rifts.all(func(r):return r.sealed) and dragon_defeated and enemies_cleared:
		outcome="victory"

func add_rift(side: int, x: float) -> void:
	rifts.append({"side":side,"x":x,"discovered":false,"ordered":false,"sealed":false,"progress":0.0,"worker":-1,"wardens_spawned":false})
func reveal(at: float) -> void:
	if outcome!="active":return
	for rift in rifts:
		if absf(rift.x-at)<=320:rift.discovered=true
func order(index: int) -> bool:
	var rift: Dictionary=rifts[index]
	if outcome!="active" or not rift.discovered or rift.ordered or rift.sealed:return false
	rift.ordered=true
	return true
func side_open(side: int) -> bool:
	for rift in rifts:
		if rift.side==side and not rift.sealed:return true
	return false
func advance_seal(index: int, seconds: float, ready: bool, knight_near: bool, contested: bool) -> void:
	var rift: Dictionary=rifts[index]
	if seconds<=0 or not is_finite(seconds) or outcome!="active":return
	if not rift.ordered or rift.sealed or not rift.wardens_spawned or not ready or not knight_near or contested:return
	rift.progress=minf(seal_seconds,rift.progress+seconds)
	if rift.progress>=seal_seconds:rift.sealed=true

func entry_x(side: int) -> float:
	var entry: float=NAN
	for rift: Dictionary in rifts:
		if rift.side!=side or rift.sealed:continue
		if is_nan(entry) or absf(rift.x)<absf(entry):entry=float(rift.x)
	if not is_nan(entry):return entry
	# A thief already carrying a crystal can still retreat after the last seal.
	for rift: Dictionary in rifts:
		if rift.side==side:return float(rift.x)
	return NAN
