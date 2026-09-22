extends Resource
## Inspector tuning for the knight's three-cut chain.
@export var enabled: bool = true
@export_range(0.05, 0.5, 0.01) var input_buffer_seconds: float = 0.30
@export_range(0.0, 0.4, 0.01) var followup_grace_seconds: float = 0.18
@export_range(0.8, 1.0, 0.01) var chain_progress: float = 0.88
@export_range(0.7, 1.2, 0.01) var return_duration_scale: float = 0.82
@export_range(1.0, 1.8, 0.05) var finisher_duration_scale: float = 1.25
@export_range(1.0, 3.0, 0.1) var finisher_damage_scale: float = 1.6

@export_group("Forward Step")
## Direction-held opening and return cuts share this controlled step distance.
@export_range(0.0, 64.0, 1.0) var return_step_distance: float = 22.0
@export_range(0.0, 64.0, 1.0) var finisher_step_distance: float = 32.0
