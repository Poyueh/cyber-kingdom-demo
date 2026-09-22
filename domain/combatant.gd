extends RefCounted
const Stats = preload("res://domain/combat_stats.gd")

var stats: Stats
var shield: int = 0
var shield_absorbed: int = 0
var hp: int
var stamina: float
var facing: int = 1
var attack_facing: int = 1
var attack_remaining: float = 0.0
var cooldown_remaining: float = 0.0
var dash_remaining: float = 0.0
var invulnerability_remaining: float = 0.0
var _hit_targets: Dictionary = {}
var combo_step: int = 0
var _swing_duration: float = 0.0
var _queued_attack_seconds: float = 0.0
var _combo_grace_remaining: float = 0.0
var _pending_attack_travel: float = 0.0

func _init(configuration: Stats) -> void:
	stats = configuration
	hp = stats.max_hp
	stamina = stats.max_stamina

func is_alive() -> bool:
	return hp > 0

## True means the press started a swing or queued exactly one continuation.
func start_attack() -> bool:
	if not is_alive() or dash_remaining > 0.0 or stamina<stats.attack_cost:
		return false
	if stats.combo_enabled and combo_step > 0 and combo_step < 3:
		if attack_remaining > 0.0:
			_queued_attack_seconds = stats.combo_buffer_seconds
			return true
		if _combo_grace_remaining > 0.0:
			return _begin_attack(combo_step + 1)
	if attack_remaining > 0.0 or cooldown_remaining > 0.0:
		return false
	return _begin_attack(1 if stats.combo_enabled else 0)

func _begin_attack(step: int) -> bool:
	if not spend_stamina(stats.attack_cost):return false
	combo_step = step
	attack_facing = facing
	var duration_scale := stats.combo_return_duration if step == 2 else (stats.combo_finisher_duration if step == 3 else 1.0)
	_swing_duration = maxf(0.001, stats.attack_duration * duration_scale)
	attack_remaining = _swing_duration
	cooldown_remaining = maxf(stats.attack_cooldown, _swing_duration + 0.12) if stats.combo_enabled else stats.attack_cooldown
	_queued_attack_seconds = 0.0
	_combo_grace_remaining = 0.0
	_hit_targets.clear()
	return true

## Pause/focus loss discards intent while preserving the current pose.
func clear_attack_buffer() -> void:
	_queued_attack_seconds = 0.0

func _cancel_combo() -> void:
	_pending_attack_travel = 0.0
	clear_attack_buffer()
	_combo_grace_remaining = 0.0
	combo_step = 0
	attack_remaining = 0.0

func attack_damage() -> int:
	return maxi(1, roundi(stats.damage * stats.combo_finisher_damage)) if combo_step == 3 else stats.damage

func start_dash() -> bool:
	if not is_alive() or dash_remaining > 0.0 or stamina < stats.dash_cost:
		return false
	stamina -= stats.dash_cost
	dash_remaining = stats.dash_duration
	invulnerability_remaining = maxf(invulnerability_remaining, stats.dash_invulnerability)
	# A dodge cancels the current sword swing, preventing an invisible attack.
	_cancel_combo()
	return true

func strike(target: RefCounted, signed_distance: float) -> bool:
	if not is_alive() or not is_attack_active():
		return false
	if signed_distance * attack_facing < 0.0 or absf(signed_distance) > stats.attack_range:
		return false
	var target_id: int = target.get_instance_id()
	if _hit_targets.has(target_id):
		return false
	if not target.take_damage(attack_damage()):
		return false
	_hit_targets[target_id] = true
	return true

func take_damage(amount: int) -> bool:
	if amount <= 0 or not is_alive() or invulnerability_remaining > 0.0:
		return false
	var absorbed := mini(maxi(0, shield), amount)
	shield = maxi(0, shield - absorbed)
	shield_absorbed += absorbed
	hp = maxi(0, hp - (amount - absorbed))
	if stats.combo_enabled:
		_cancel_combo()
	invulnerability_remaining = stats.hurt_invulnerability
	return true

func advance(seconds: float) -> void:
	_pending_attack_travel = 0.0
	if seconds <= 0.0 or not is_finite(seconds):
		return
	_advance_attack(seconds)
	dash_remaining = maxf(0.0, dash_remaining - seconds)
	invulnerability_remaining = maxf(0.0, invulnerability_remaining - seconds)
	if is_alive():
		stamina = minf(stats.max_stamina, stamina + stats.stamina_regen * seconds)

func _advance_attack(seconds: float) -> void:
	# Split at the handoff so a coarse frame cannot erase or delay a valid press.
	var handoff := maxf(0.0, attack_remaining - _swing_duration * (1.0 - stats.combo_chain_progress))
	if stats.combo_enabled and combo_step > 0 and combo_step < 3 and _queued_attack_seconds > 0.0 and _queued_attack_seconds >= handoff and seconds >= handoff and stamina>=stats.attack_cost:
		_accumulate_attack_travel(handoff)
		_begin_attack(combo_step + 1)
		_advance_attack(seconds - handoff)
		return
	_accumulate_attack_travel(seconds)
	var previous_remaining := attack_remaining
	attack_remaining = maxf(0.0, attack_remaining - seconds)
	cooldown_remaining = maxf(0.0, cooldown_remaining - seconds)
	_queued_attack_seconds = maxf(0.0, _queued_attack_seconds - seconds)
	if stats.combo_enabled and attack_remaining <= 0.0:
		if previous_remaining > 0.0 and combo_step < 3:
			_combo_grace_remaining = maxf(0.0, stats.combo_grace_seconds - (seconds - previous_remaining))
		else:
			_combo_grace_remaining = maxf(0.0, _combo_grace_remaining - seconds)
		if _combo_grace_remaining <= 0.0 and cooldown_remaining <= 0.0:
			combo_step = 0

func attack_progress() -> float:
	if attack_remaining <= 0.0 or _swing_duration <= 0.0:
		return 1.0
	return clampf(1.0 - attack_remaining / _swing_duration, 0.0, 1.0)

func is_attack_active() -> bool:
	var progress := attack_progress()
	return progress >= attack_active_start() and progress < attack_active_end()

func attack_active_start() -> float:
	return 0.25 if combo_step == 2 else 0.4

func attack_active_end() -> float:
	return 0.65 if combo_step == 2 else 0.75

func dash_progress() -> float:
	if dash_remaining <= 0.0 or stats.dash_duration <= 0.0:
		return 1.0
	return clampf(1.0 - dash_remaining / stats.dash_duration, 0.0, 1.0)

## Signed horizontal travel produced by combat time, consumed by the physics adapter.
func consume_attack_travel(movement_direction: float = 0.0) -> float:
	var travel := _pending_attack_travel
	_pending_attack_travel = 0.0
	# Intent is sampled by the caller each tick. Releasing it discards that tick's
	# step; pressing later cannot release a backlog or reverse the locked sword.
	if not is_finite(movement_direction) or is_zero_approx(movement_direction):
		return 0.0
	return travel

func _accumulate_attack_travel(seconds: float) -> void:
	if attack_remaining <= 0.0 or combo_step < 1:
		return
	var distance := stats.combo_finisher_step if combo_step == 3 else stats.combo_return_step
	var before := attack_progress()
	var after := minf(1.0, before + seconds / _swing_duration)
	_pending_attack_travel += attack_facing * maxf(0.0, distance) * (_step_fraction(after) - _step_fraction(before))

func _step_fraction(progress: float) -> float:
	# Ease into and out of the active sword cut; anticipation/recovery stay planted.
	var phase := clampf((progress - attack_active_start()) / (attack_active_end() - attack_active_start()), 0.0, 1.0)
	return phase * phase * (3.0 - 2.0 * phase)

func spend_stamina(amount: float) -> bool:
	if not is_alive() or not is_finite(amount) or amount<0 or stamina<amount:return false
	stamina-=amount
	return true
