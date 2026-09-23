extends RefCounted
## Combat feedback for the training arena, which has two fighters and no world.
## Read-only observer: it never touches the model.
const COMBO = ["slash1", "slash2", "slash3"]

var _started := false
var _active := false
var _combo := 0
var _dash := 0.0
var _hero_hp := 0
var _foe_hp := 0
var _foe_alive := true
var _windup := 0.0

func sample(hero, foe, windup: float, paused: bool) -> Array[String]:
	var result: Array[String] = []
	var active: bool = hero.is_attack_active()
	if _started and not paused:
		if active and (not _active or _combo != hero.combo_step):
			result.append(COMBO[clampi(hero.combo_step - 1, 0, COMBO.size() - 1)])
		if hero.dash_remaining > _dash: result.append("dash")
		if foe.hp < _foe_hp: result.append("hit")
		if hero.hp < _hero_hp: result.append("hurt")
		if _foe_alive and not foe.is_alive(): result.append("enemy_death")
		if windup > 0 and _windup <= 0: result.append("enemy_telegraph")
		elif windup <= 0 and _windup > 0: result.append("enemy_attack")
	_started = true
	_active = active
	_combo = hero.combo_step
	_dash = hero.dash_remaining
	_hero_hp = hero.hp
	_foe_hp = foe.hp
	_foe_alive = foe.is_alive()
	_windup = windup
	return result
