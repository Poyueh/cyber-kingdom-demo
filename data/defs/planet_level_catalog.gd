class_name PlanetLevelCatalog
extends Resource
@export var profiles: Array[PlanetLevelProfile]
func rules() -> Dictionary:
	var result: Array[Dictionary]=[]
	for profile: PlanetLevelProfile in profiles:result.append(profile.rules())
	return {"version":1,"profiles":result}
