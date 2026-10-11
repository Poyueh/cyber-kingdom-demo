class_name PlanetLevelProfile
extends Resource
## Authored route beats. Jitter changes room length, never their purpose or order.
@export var planet_id: int
@export var left_roles: PackedInt32Array
@export var right_roles: PackedInt32Array
@export var left_terrain: PackedInt32Array
@export var right_terrain: PackedInt32Array
@export var left_widths: PackedFloat32Array
@export var right_widths: PackedFloat32Array
@export var width_jitter: float
@export var station_spacing: float
func rules() -> Dictionary:
	return {"planet_id":planet_id,"left_roles":Array(left_roles),"right_roles":Array(right_roles),"left_terrain":Array(left_terrain),"right_terrain":Array(right_terrain),"left_widths":Array(left_widths),"right_widths":Array(right_widths),"width_jitter":width_jitter,"station_spacing":station_spacing}
