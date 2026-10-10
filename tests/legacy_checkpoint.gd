extends RefCounted
## Strip v16 additions when constructing genuine older checkpoint shapes.
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

static func before_ruin_mechanisms(packet: Dictionary) -> void:
 for key: String in packet.config.keys():
  if key.begins_with("mechanism_"):packet.config.erase(key)
