extends RefCounted
## Presentation-only names, colours and symbols. Never used for gameplay decisions.
const IDS: Array[String]=preload("res://domain/module_specs.gd").IDS
const COLORS: Array[String]=["78e9c8","c1a0ff","f3cc78","9cddff","d69bee","ecad69","82dbb4","9faeff"]
const WORLDS: Array[String]=["planet.forest","planet.desert","planet.frost","planet.swamp","planet.volcanic","planet.storm","planet.void"]
static func tint(id: String) -> Color:
 var index: int=IDS.find(id)
 return Color(COLORS[index]) if index>=0 else Color.WHITE
static func title(id: String) -> String:return "module.name."+id
static func detail(id: String) -> String:return "module.detail."+id
static func role(id: String) -> String:return "module.role."+id
static func icon(id: String) -> String:return "module_"+id
static func world(planet: int) -> String:
 return WORLDS[clampi(planet,0,6)]
