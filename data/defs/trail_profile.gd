class_name TrailProfile
extends Resource
@export var planet_id: int
@export var combat_side: int
@export var guard_count: int
@export var health: int
@export var damage: int
@export var speed: float
@export var windup_seconds: float
@export var recovery_seconds: float
@export var reach: float
@export var charge_distance: float
@export var charge_seconds: float
@export var territory: float
@export var notice: float
@export var combat_reward: int
@export var discovery_reward: int
func rules() -> Dictionary:
	return {"planet_id":planet_id,"combat_side":combat_side,"guard_count":guard_count,"health":health,"damage":damage,"speed":speed,"windup_seconds":windup_seconds,"recovery_seconds":recovery_seconds,"reach":reach,"charge_distance":charge_distance,"charge_seconds":charge_seconds,"territory":territory,"notice":notice,"combat_reward":combat_reward,"discovery_reward":discovery_reward}
