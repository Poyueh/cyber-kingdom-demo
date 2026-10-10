extends RefCounted
## The summoning day locks the encounter strength; early seals never bypass the floor.
static func tuning(config: Dictionary) -> Dictionary:
 var result: Dictionary={"baseline_day":maxi(1,int(config.get("dragon_baseline_day",6))),"health":maxi(100,int(config.get("dragon_health",1800))),"damage":maxi(1,int(config.get("dragon_damage",36))),"daily_health":maxi(0,int(config.get("dragon_daily_health",240))),"daily_damage":maxi(0,int(config.get("dragon_daily_damage",4)))}
 if config.has("dragon_growth_days"):result["growth_days"]=int(config.dragon_growth_days)
 return result
static func growth_days(day: int, rules: Dictionary) -> int:
 return mini(maxi(0,day-int(rules.baseline_day)),int(rules.get("growth_days",1000000)))
static func strength(day: int, rules: Dictionary) -> Dictionary:
 var delay: int=growth_days(day,rules)
 return {"health":rules.health+delay*rules.daily_health,"damage":rules.damage+delay*rules.daily_damage}
