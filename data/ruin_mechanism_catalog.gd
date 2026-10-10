extends Resource
@export var definitions: Array[RuinMechanismDefinition]
func rules() -> Dictionary:
 assert(definitions.size()==6,"Six destination mechanism definitions required")
 var seen: Array[int]=[]
 var result: Dictionary={"mechanism_version":1}
 for definition: RuinMechanismDefinition in definitions:
  assert(not seen.has(definition.planet),"Duplicate mechanism world")
  seen.append(definition.planet);result.merge(definition.rules(),true)
 return result
