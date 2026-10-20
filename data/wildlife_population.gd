class_name WildlifePopulationTuning
extends Resource
## Resolved for new journeys. Existing saved populations are never filled in.
@export_range(2,4,1) var per_forest: int
@export var near_camp: Array[float]
func rules() -> Dictionary:
 var result: Dictionary={"wildlife_version":1,"wildlife_per_forest":per_forest}
 for index: int in range(near_camp.size()):result["wildlife_near_%d"%index]=near_camp[index]
 return result
