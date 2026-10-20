extends RefCounted
## Remove later fields when constructing genuinely older checkpoint shapes.
static func before_mount(packet: Dictionary) -> void:
 before_module_catalog(packet)
 packet.erase("mount")
 for key: String in packet.config.keys():
  if key.begins_with("mount_"):packet.config.erase(key)

static func before_module_catalog(packet: Dictionary) -> void:
 before_ruin_mechanisms(packet)
 if packet.has("modules"):
  packet.modules.erase("charge_ticks");packet.modules.erase("charge_last_tick")
 packet.config.erase("module_catalog_version")
 for key: String in packet.config.keys():
  for id: String in ["magnet","frost","gravity","workshop","command","capacitor"]:
   if key.begins_with("module_"+id+"_"):packet.config.erase(key)

static func before_night_patterns(packet: Dictionary) -> void:
 before_trails(packet)
 for key: String in packet.config.keys():
  if key.begins_with("night_pattern_"):packet.config.erase(key)

static func before_ruin_mechanisms(packet: Dictionary) -> void:
 before_night_patterns(packet)
 for key: String in packet.config.keys():
  if key.begins_with("mechanism_"):packet.config.erase(key)

static func before_trails(packet: Dictionary) -> void:
 before_planet(packet)
 packet.erase("core_loop")
 packet.erase("trails")
 if packet.has("merchant"):packet.merchant.erase("trip_end_x")

## v23 added the world's planet state; every older shape lacks it.
static func before_planet(packet: Dictionary) -> void:
 packet.erase("planet")
 packet.erase("command")
