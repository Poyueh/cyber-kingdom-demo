class_name AttendantBehavior
extends Resource
@export var profiles: Array[AttendantProfile]
@export var approach_radius: float
@export var departure_radius: float
@export var notice_seconds: float
@export var greeting_seconds: float
@export var greeting_interval: float
@export var acknowledgement_seconds: float
@export var service_seconds: float
@export var danger_radius: float
@export var safety_radius: float
@export var safety_seconds: float
func valid() -> bool:
 return profiles.size()==6 and profiles.all(func(p: AttendantProfile)->bool:return p!=null and p.valid()) and approach_radius>0 and departure_radius>approach_radius and notice_seconds>0 and greeting_seconds>notice_seconds and greeting_interval>greeting_seconds and acknowledgement_seconds>0 and service_seconds>acknowledgement_seconds and danger_radius>0 and safety_radius>danger_radius and safety_seconds>0
