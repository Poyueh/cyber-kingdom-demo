extends RefCounted
## Adapter for short effects on legacy resident/raider records. Modifiers stay labelled.
const Stats=preload("res://domain/stats/stat_block.gd")
const Buff=preload("res://domain/stats/modifier.gd")
const Clock=preload("res://domain/time/tick_clock.gd")
static func adjusted(base: float, power: float, op: Buff.Op, source: StringName, until: int, now: int) -> float:
 if until<=now:return base
 var stats: Stats=Stats.new();stats.set_base(&"value",base)
 stats.apply(Buff.make(&"value",op,power,source,until));stats.expire_at(now)
 return stats.value_of(&"value")
static func valid(record: Dictionary, key: String, data: Dictionary, duration_key: String) -> bool:
 if not record.has(key):return true
 var until: Variant=record[key]
 if not until is int or not data.config.has("module_catalog_version"):return false
 var now: int=roundi(data.workforce.elapsed*Clock.TICKS_PER_SECOND)
 return until>now and until<=now+Clock.ticks_for(data.config[duration_key])
