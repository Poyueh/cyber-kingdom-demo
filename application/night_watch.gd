extends RefCounted
## Read-only tactical description. No warnings or UI history enter the save.
const Clock = preload("res://domain/time/tick_clock.gd")
const Pattern = preload("res://domain/night_pattern.gd")
static func describe(sim: RefCounted) -> Dictionary:
	var pattern: Pattern = sim.night_pattern
	if not pattern.enabled or not sim.is_running():return {}
	if not sim.mission.side_open(-1) and not sim.mission.side_open(1):return {}
	if not sim.clock.is_night and sim.clock.remaining*Clock.TICKS_PER_SECOND>pattern.warning_ticks:return {}
	# Early exploration needs a way home even after the opening spirit has left.
	# Reuse the authored warning window; this is presentation, not a new raid rule.
	if sim.clock.day<pattern.first_day:
		if sim.clock.is_night or sim.frontier.city_level==0 or sim.work_area.contains(sim._hero_x):return {}
		var homeward: int=-1 if sim._hero_x>sim.world.sites.hall else 1
		return {"key":"night.return","phase":&"return","day":sim.clock.day,"left":homeward<0,"right":homeward>0,"lead":homeward,"style":&"home"}
	var total: int = sim.planned_night_count()
	var style: StringName = pattern.style(sim.clock.day)
	var lead: int = pattern.lead_side(sim.clock.day)
	var phase: StringName = &"dusk"
	if sim.clock.is_night:
		phase = &"assault"
		if style==Pattern.PINCER and sim._night_spawn_index>=pattern.split_at(total):phase=&"second"
	var left: bool = sim.mission.side_open(-1)
	var right: bool = sim.mission.side_open(1)
	# A sealed portal never promises an attack, even when it was the scheduled lead.
	var direction: StringName = &"west" if lead<0 else &"east"
	if not left:direction=&"east"
	if not right:direction=&"west"
	var key: String = "night.%s.%s"%[style,direction]
	if style==Pattern.BALANCED:key="night.balanced"
	if not left or not right:key="night.only.%s"%direction
	elif phase==&"second":key="night.second.%s"%(&"east" if lead<0 else &"west")
	return {"key":key,"phase":phase,"day":sim.clock.day,"left":left,"right":right,"lead":lead,"style":style}
