extends RefCounted
## Three observable puzzle families. Mutable state is bounded to value + marks.
const Clock=preload("res://domain/time/tick_clock.gd")
enum Kind {CIRCUIT=1, BALANCE=2, PULSE=3}
const PREFIX: String="mechanism_"
const FIELDS: Array[String]=["kind","initial","target","minimum","maximum","warm","cool","mask_0","mask_1","mask_2","period","window","offset_0","offset_1","offset_2"]
var planet: int
var kind: Kind
var initial: int
var target: int
var minimum: int
var maximum: int
var warm: int
var cool: int
var masks: Array[int]=[]
var period: int
var window: int
var offsets: Array[int]=[]
var value: int
var marks: int=0
func _init(config: Dictionary, planet: int) -> void:
 self.planet=planet
 var prefix: String=PREFIX+str(planet)+"_"
 kind=int(config[prefix+"kind"]) as Kind
 for key: String in ["initial","target","minimum","maximum","warm","cool"]:set(key,int(config[prefix+key]))
 for index: int in range(3):
  masks.append(int(config[prefix+"mask_"+str(index)]))
  offsets.append(Clock.ticks_for(config[prefix+"offset_"+str(index)]))
 period=Clock.ticks_for(config[prefix+"period"]);window=Clock.ticks_for(config[prefix+"window"])
 value=initial
static func configured(config: Dictionary) -> bool:
 return config.get("mechanism_version",0)==1 and int(config.get("planet_id",0))>0
static func valid_config(config: Dictionary) -> bool:
 var enabled: bool=config.has("mechanism_version")
 if not enabled:
  for key: String in config:
   if key.begins_with(PREFIX):return false
  return true
 if config.mechanism_version!=1 or config.get("module_catalog_version",0)!=1 or config.get("ruin_enabled",0)!=1:return false
 for planet: int in range(1,7):
  var p: String=PREFIX+str(planet)+"_"
  for key: String in FIELDS:
   var n: Variant=config.get(p+key)
   if not (n is int or n is float) or not is_finite(n) or absf(n)>60:return false
   if key not in ["period","window","offset_0","offset_1","offset_2"] and floorf(n)!=n:return false
  var type: int=int(config[p+"kind"])
  if type not in [Kind.CIRCUIT,Kind.BALANCE,Kind.PULSE]:return false
  var lo: int=int(config[p+"minimum"]);var hi: int=int(config[p+"maximum"])
  var start: int=int(config[p+"initial"]);var goal: int=int(config[p+"target"])
  if lo< -12 or hi>12 or lo>=hi or start<lo or start>hi or goal<lo or goal>hi or start==goal:return false
  if int(config[p+"warm"])<=0 or int(config[p+"cool"])>=0:return false
  var reachable: Array[int]=[start]
  for mask_index: int in range(3):
   var mask: int=int(config[p+"mask_"+str(mask_index)])
   if mask<1 or mask>7:return false
   var previous: Array[int]=reachable.duplicate()
   for v: int in previous:
    if not reachable.has(v^mask):reachable.append(v^mask)
  if type==Kind.CIRCUIT and (lo!=0 or hi!=7 or goal!=7 or not reachable.has(goal)):return false
  if type==Kind.BALANCE and not _balance_reachable(start,goal,lo,hi,int(config[p+"warm"]),int(config[p+"cool"])):return false
  if config[p+"period"]<4 or config[p+"period"]>12 or config[p+"window"]<1.5 or config[p+"window"]>=config[p+"period"]:return false
  for index: int in range(3):
   if config[p+"offset_"+str(index)]<0 or config[p+"offset_"+str(index)]>=config[p+"period"]:return false
 return true
static func _balance_reachable(start: int, goal: int, lo: int, hi: int, up: int, down: int) -> bool:
 var visited: Array[int]=[start];var cursor: int=0
 while cursor<visited.size():
  var current: int=visited[cursor];cursor+=1
  for step: int in [up,down]:
   var next: int=current+step
   if next<lo or next>hi or visited.has(next):continue
   if next==goal:return true
   visited.append(next)
 return false
func progress() -> int:
 if kind==Kind.BALANCE:return 3 if marks==1 else 0
 var bits: int=value if kind==Kind.CIRCUIT else marks
 return int(bool(bits&1))+int(bool(bits&2))+int(bool(bits&4))
func lit(station: int) -> bool:
 if kind==Kind.BALANCE:return marks==1 or (station==2 and value==target)
 return ((value if kind==Kind.CIRCUIT else marks)&(1<<station))!=0
func phase(station: int, now: int) -> int:
 return posmod(now+offsets[station],period)
func accepts(station: int, now: int) -> bool:
 return kind!=Kind.PULSE or phase(station,now)<window
func activate(station: int, now: int) -> bool:
 if station<0 or station>2 or now<0 or progress()==3:return false
 match kind:
  Kind.CIRCUIT:value=value^masks[station]
  Kind.BALANCE:
   if station==2:
    if value!=target:return false
    marks=1
   else:
    var next: int=value+(warm if station==0 else cool)
    if next<minimum or next>maximum:return false
    value=next
  Kind.PULSE:
   if lit(station) or not accepts(station,now):return false
   marks=marks|(1<<station)
 return true
func unlock() -> void:
 if kind==Kind.CIRCUIT:value=target
 elif kind==Kind.BALANCE:value=target;marks=1
 else:marks=7
func capture() -> Dictionary:
 return {"value":value,"marks":marks}
func restore(data: Variant, expected_progress: int) -> bool:
 if not data is Dictionary or data.size()!=2 or not data.get("value") is int or not data.get("marks") is int:return false
 var v: int=data.value;var m: int=data.marks
 if v<minimum or v>maximum:return false
 match kind:
  Kind.CIRCUIT:
   if m!=0:return false
   var reachable: bool=false
   for mask: int in range(8):
    var candidate: int=initial
    for i: int in range(3):
     if mask&(1<<i):candidate=candidate^masks[i]
    if candidate==v:reachable=true
   if not reachable:return false
  Kind.BALANCE:
   if m not in [0,1] or (m==1 and v!=target):return false
   if v!=initial and not _balance_reachable(initial,v,minimum,maximum,warm,cool):return false
  Kind.PULSE:
   if v!=initial or m<0 or m>7:return false
 var old_value: int=value;var old_marks: int=marks
 value=v;marks=m
 if progress()==expected_progress:return true
 value=old_value;marks=old_marks
 return false
