extends Resource
## Presentation timing only; changing this resource never changes a journey.
@export_range(0.3,2.0,0.1) var fade_in_seconds: float
@export_range(0.2,2.0,0.1) var fade_out_seconds: float
@export_range(0.2,2.0,0.1) var menu_reveal_seconds: float
@export var shot_starts: PackedFloat32Array
@export var caption_keys: PackedStringArray
@export var duration: float
