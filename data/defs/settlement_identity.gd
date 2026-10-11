class_name SettlementIdentity
extends Resource
@export var attendants: Texture2D
@export var cell: Vector2i
@export var baseline: int
@export var frames_per_second: float
@export var cycle: PackedInt32Array
@export var sites: Array[StringName]
@export var offsets: PackedVector2Array
@export var buildings: Dictionary[StringName,Texture2D]
func valid() -> bool:
	return attendants!=null and cell.x>0 and cell.y>baseline and baseline>0 and sites.size()==6 and offsets.size()==sites.size() and cycle.size()>0 and frames_per_second>0 and buildings.size()==6
