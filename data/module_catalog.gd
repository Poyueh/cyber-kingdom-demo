extends Resource
@export var definitions: Array[Resource]=[]
func rules() -> Dictionary:
 var result: Dictionary={"module_catalog_version":1}
 for definition: Resource in definitions:result.merge(definition.rules(),true)
 assert(preload("res://domain/module_specs.gd").valid_config(result),"Incomplete or invalid module catalogue")
 return result
