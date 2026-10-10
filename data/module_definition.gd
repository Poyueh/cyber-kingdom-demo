extends Resource
## Export-only content; the core receives numeric rules, not Resources or paths.
@export var id: StringName
@export_range(1,6) var planet: int
@export_enum("Left:-1","Right:1") var side: int=1
@export_range(0,60) var cost: float
@export_range(0,150) var damage: int
@export_range(60,600) var reach: float
@export_range(1,30) var cooldown: float
@export_range(1,5) var targets: int
@export_range(0,10) var duration: float
@export_range(0,50) var power: float
@export_range(0,1) var boss_power: float
@export_range(0,10) var boss_duration: float
@export_range(0,100) var threshold: float
func rules() -> Dictionary:
 var result: Dictionary={}
 for key: String in ["planet","side","cost","damage","reach","cooldown","targets","duration","power","boss_power","boss_duration","threshold"]:
  result["module_"+str(id)+"_"+key]=get(key)
 return result
