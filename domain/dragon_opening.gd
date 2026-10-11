extends RefCounted
## An immutable policy projected from the saved attack phase; no second timer.
const Stats=preload("res://domain/stats/stat_block.gd")
const Buff=preload("res://domain/stats/modifier.gd")
const KEYS: Array[String]=["dragon_opening_version","dragon_opening_multiplier","dragon_opening_minimum"]
var _damage: Stats=Stats.new()
var enabled: bool=false
var multiplier: float=1.0
var minimum_recovery: float=0.0
func _init(config: Dictionary) -> void:
	assert(valid_config(config),"Invalid dragon opening rules")
	enabled=config.has(KEYS[0])
	if not enabled:return # Pre-opening saves retain their exact attack and damage rules.
	multiplier=float(config[KEYS[1]]);minimum_recovery=float(config[KEYS[2]])
	_damage.apply(Buff.make(&"damage",Buff.Op.MULT,multiplier,&"dragon:exposed_core"))
func exposed(enemy: Dictionary) -> bool:
	return enabled and enemy.get("kind","")=="dragon" and enemy.fighter.is_alive() and enemy.windup==0.0 and enemy.cooldown>0.0 and not enemy.target.is_empty()
func damage(enemy: Dictionary, amount: int) -> int:
	if amount<=0 or not exposed(enemy):return amount
	_damage.set_base(&"damage",amount)
	return roundi(_damage.value_of(&"damage"))
static func valid_config(config: Dictionary) -> bool:
	if not config.has(KEYS[0]):return not config.has(KEYS[1]) and not config.has(KEYS[2])
	if not config[KEYS[0]] is int or config[KEYS[0]]!=1:return false
	for key: String in [KEYS[1],KEYS[2]]:
		var value: Variant=config.get(key)
		if not (value is int or value is float) or not is_finite(float(value)):return false
	return config[KEYS[1]]>=1.1 and config[KEYS[1]]<=2.0 and config[KEYS[2]]>=5.0 and config[KEYS[2]]<=10.0
