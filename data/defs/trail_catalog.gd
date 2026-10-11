class_name TrailCatalog
extends Resource
@export var profiles: Array[TrailProfile]
func rules() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for profile: TrailProfile in profiles:result.append(profile.rules())
	return result
