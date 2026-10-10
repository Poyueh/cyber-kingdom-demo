class_name RuinMechanismDefinition
extends Resource
@export_range(1,6,1) var planet: int
@export_enum("Circuit:1","Balance:2","Pulse:3") var kind: int
@export var initial: int
@export var target: int
@export var minimum: int
@export var maximum: int
@export var warm: int
@export var cool: int
@export var masks: Array[int]
@export var period_seconds: float
@export var window_seconds: float
@export var offsets_seconds: Array[float]
func rules() -> Dictionary:
 var result: Dictionary={}
 var prefix: String="mechanism_"+str(planet)+"_"
 for key: String in ["kind","initial","target","minimum","maximum","warm","cool"]:result[prefix+key]=get(key)
 result[prefix+"period"]=period_seconds;result[prefix+"window"]=window_seconds
 for index: int in range(3):result[prefix+"mask_"+str(index)]=masks[index];result[prefix+"offset_"+str(index)]=offsets_seconds[index]
 return result
