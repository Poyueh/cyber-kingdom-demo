extends Resource
## Complete visual set; replacing a costume must not change combat or travel rules.
@export var frames: SpriteFrames
@export var unarmed_run: Texture2D
@export var unarmed_idle: Texture2D
@export var unarmed_sprint: Texture2D
@export var unarmed_tired: Texture2D
@export var unarmed_hurt: Texture2D
@export var unarmed_death: Texture2D
@export var unarmed_jump: Texture2D
@export var unarmed_mounted: Texture2D
@export_range(2,8) var reaction_frames: int=2
@export var rest_transition_frames: bool=false
@export var module_sockets: Dictionary
@export var mounted_offset: Vector2=Vector2(0,-26)
@export var mounted_gait_frames: int=2
@export_range(1,40) var mounted_fps: float=18.0
@export var mounted_attack_start: int=3
@export_range(3,8) var mounted_attack_frames: int=3
@export var mounted_idle_start: int=0
@export_range(1,4) var mounted_idle_frames: int=1
@export var mounted_hurt_frame: int=0
@export var mounted_rest_frame: int=0
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

@export_group("Distance-driven gait")
## Zero retains the cadence of legacy costume resources.
@export_range(0,600,0.25) var run_reference_speed: float = 0.0
@export_range(0,600,0.25) var sprint_reference_speed: float = 0.0
@export_range(0,300,0.1) var tired_reference_speed: float = 0.0
