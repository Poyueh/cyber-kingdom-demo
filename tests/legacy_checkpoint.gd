extends RefCounted
## Strip v16 additions when constructing genuine older checkpoint shapes.
static func before_mount(packet: Dictionary) -> void:
 packet.erase("mount")
 for key: String in packet.config.keys():
  if key.begins_with("mount_"):packet.config.erase(key)
