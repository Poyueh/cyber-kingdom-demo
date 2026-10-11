class_name SettlementIdentity
extends Resource
@export var attendants: Texture2D
@export var cell: Vector2i
@export var baseline: int
@export var sites: Array[StringName]
@export var offsets: PackedVector2Array
@export var buildings: Dictionary[StringName,Texture2D]
func valid() -> bool:
	return attendants!=null and cell.x>0 and cell.y>baseline and baseline>0 and sites.size()==6 and offsets.size()==sites.size() and buildings.size()==6
