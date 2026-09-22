extends Resource
## Complete visual set; replacing a costume must not change combat or travel rules.
@export var frames: SpriteFrames
@export var unarmed_run: Texture2D
@export var unarmed_idle: Texture2D
@export var unarmed_sprint: Texture2D
@export var unarmed_tired: Texture2D
@export var unarmed_hurt: Texture2D
@export var unarmed_death: Texture2D
@export var module_sockets: Dictionary
@export var mounted_offset: Vector2=Vector2(0,-26)
@export var mounted_gait_frames: int=2
@export var mounted_attack_start: int=3
@export var rest: Texture2D
@export var ceremony: Texture2D
@export var mounted: Texture2D
@export var combo: Resource
@export_range(1,32) var stride_frames: int = 8
@export_range(1,8) var stride_columns: int = 4
@export_range(1,8) var idle_frames: int = 1
@export_range(1,4) var idle_columns: int = 1
@export_range(1,60) var run_fps: float = 12.0
@export_range(1,60) var sprint_fps: float = 18.0
@export_range(1,60) var tired_fps: float = 7.0
