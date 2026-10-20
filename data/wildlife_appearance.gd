extends Resource
class_name WildlifeAppearance
## Native full-body artwork and distance-driven gait; no campaign snapshot data.
@export var id: StringName
@export var texture: Texture2D
@export var frame_size: Vector2i = Vector2i(96,80)
@export var columns: int = 4
@export var frame_count: int = 8
@export var ground_pivot: Vector2 = Vector2(48,74)
@export var stride: float = 32.0
@export var shadow: float = 20.0
