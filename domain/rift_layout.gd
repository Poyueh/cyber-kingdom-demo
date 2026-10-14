extends RefCounted
## Bounded, creation-time gate allocation. Missing marker means the original two gates.
static func valid_config(config: Dictionary) -> bool:
 if not config.has("rift_layout_version"):
  return not config.has("rift_left_count") and not config.has("rift_right_count")
 if config.rift_layout_version!=1:return false
 for key: String in ["rift_left_count","rift_right_count"]:
  var value: Variant=config.get(key)
  if not (value is int or value is float) or value not in [1,2]:return false
 return true
static func populate(mission: RefCounted, config: Dictionary, left: float, right: float) -> void:
 mission.add_rift(-1,left-180.0);mission.add_rift(1,right+180.0)
 if not config.has("rift_layout_version"):return
 # The extra gate occupies the final approach, 830 px from its outer gate.
 # No extra rooms, resources, random draws or nightly enemy quotas are created.
 if int(config.rift_left_count)==2:mission.add_rift(-1,left+650.0)
 if int(config.rift_right_count)==2:mission.add_rift(1,right-650.0)
