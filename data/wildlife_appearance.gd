extends Resource
class_name WildlifeAppearance
## Pixel artwork and distance-driven gait; never written into campaign snapshots.
@export var id: StringName
@export var rows: Array[String]
@export var colors: PackedColorArray
@export var origin: Vector2
@export var legs: PackedVector2Array
@export var stride: float
@export var step: float
@export var lift: float
@export var bounce: float
@export var shadow: float
@export var tail_rows: Array[String]
@export var tail_origin: Vector2
@export var tail_sway: float
