extends CharacterBody2D
## Engine adapter: movement/collision/rendering only. Combat rules live in model.
const Fighter = preload("res://domain/combatant.gd")
const PIXELS := [
	".....rrr........", "....ssssss......", "...sHHHHHHs.....", "...sHhhhhHs.....",
	"...sHddddds.....", "...sHhggggs.....", "....sHHHHs......", "..rrssssss......",
	".rrsHHHHHHss....", ".rrsHhHHhHsGs...", ".rrsHHHHHHsGs...", ".rrsHHGGHHss....",
	".rr.sHHHHs......", "..r.sGGGGs......", "....sHHHHs......", "....sGssGs......",
	"....sGs.Gs......", "....sGs.Gs......", "...sGGs.GGs....."]
const PALETTE := {"s": Color("101523"), "H": Color("829eab"), "h": Color("d5e3dd"),
	"d": Color("171e2c"), "g": Color("88e4df"), "r": Color("78445a"), "G": Color("c49b66")}
@export var is_enemy: bool = false
@export var procedural_slash: bool = true
var model: Fighter
var tuning: Resource
var telegraph: bool = false
var mounted:=false
func set_mounted(value: bool) -> void:
	if mounted!=value:_dash_trail.clear()
	mounted=value
	if visual!=null and visual.has_method("set_mounted"):visual.set_mounted(value)
var _dash_trail: Array[Dictionary] = []
var _trail_interval: float = 0.0
@onready var visual: AnimatedSprite2D = get_node_or_null("SentinelVisual" if is_enemy else "KnightVisual")

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func configure(fighter: Fighter, parameters: Resource) -> void:
	model = fighter
	tuning = parameters
	velocity = Vector2.ZERO
	_dash_trail.clear()
	_trail_interval = 0.0
	if visual != null:
		visual.reset_pose()
	queue_redraw()

func advance_motion(direction: float, jump_requested: bool, seconds: float) -> void:
	if model == null or seconds <= 0.0 or not is_finite(seconds):
		return
	var attack_travel := model.consume_attack_travel()
	if model.is_alive():
		velocity.x = direction * tuning.move_speed * (1.25 if mounted else 1.0)
		if (model.stats.attack_movement_locked and model.attack_remaining > 0.0) or not is_zero_approx(attack_travel):
			velocity.x = attack_travel / seconds
		if model.dash_remaining > 0.0:
			velocity.x = model.facing * tuning.dash_speed * (1.15 if mounted else 1.0)
		if jump_requested and is_on_floor() and model.spend_stamina(model.stats.jump_cost):
			velocity.y = -tuning.jump_speed
	else:
		velocity.x = 0.0
	velocity.y += tuning.gravity * seconds
	# move_and_slide uses the engine's full physics delta. Scale its velocity
	# for any partial tick left after hit stop, then restore world units.
	var fraction := clampf(seconds / get_physics_process_delta_time(), 0.0, 1.0)
	if fraction > 0.0:
		velocity *= fraction
		move_and_slide()
		velocity /= fraction

func refresh_visual(seconds: float) -> void:
	for sample in _dash_trail:
		sample.age += seconds
	_dash_trail = _dash_trail.filter(func(sample): return sample.age < 0.12)
	_trail_interval -= seconds
	if visual != null:
		visual.present({"alive": model.is_alive(), "facing": action_facing(),
			"moving": absf(velocity.x) > 0.1 and not (model.stats.attack_movement_locked and model.attack_remaining > 0.0), "horizontal_speed":absf(velocity.x), "locomotion_rate": velocity.x*action_facing()/maxf(1,tuning.move_speed), "grounded": is_on_floor(), "vertical_speed":velocity.y,
			"telegraph": telegraph, "dashing": model.dash_remaining > 0.0, "dash_progress": model.dash_progress(), "attack_progress": model.attack_progress(), "combo_step": model.combo_step,
			"hp":model.hp,"shield":model.shield,"invulnerable": model.invulnerability_remaining > 0.0}, seconds)
		if model.dash_remaining > 0.0 and model.is_alive() and not mounted:
			if _trail_interval <= 0.0:
				_dash_trail.append({"origin": visual.global_position + visual.offset,
					"texture": visual.sprite_frames.get_frame_texture(visual.animation, visual.frame),
					"facing": action_facing(), "age": 0.0})
				_trail_interval = 0.04
		else:
			_trail_interval = 0.0
	queue_redraw()

func action_facing() -> int:
	return model.attack_facing if model.attack_remaining > 0.0 else model.facing

func _draw() -> void:
	if model == null or not model.is_alive():
		return
	if model.shield > 0:
		draw_arc(Vector2(0, -25), 31, 0, TAU, 24, Color(0.35, 0.92, 0.91, 0.6), 1.5)
	_draw_dash_trail()
	var reach: float = model.stats.attack_range if model.is_attack_active() else 22.0
	var facing := action_facing()
	if visual == null:
		for row in range(PIXELS.size()):
			for column in range(PIXELS[row].length()):
				var key: String = PIXELS[row][column]
				if not PALETTE.has(key):
					continue
				var shade: Color = PALETTE[key]
				if is_enemy and key == "H":
					shade = Color("826875")
				if model.invulnerability_remaining > 0.0:
					shade = shade.lightened(0.35)
				var x := column if facing > 0 else 15 - column
				draw_rect(Rect2(x * 2 - 16, row * 2 - 38, 2, 2), shade)
		draw_line(Vector2(facing * 12, -20), Vector2(facing * reach, -26), Color("d8d6b1"), 3.0)
	if model.is_attack_active() and (procedural_slash or mounted):
		_draw_slash(reach, facing)
	if telegraph:
		draw_rect(Rect2(-3, -62, 6, 13), Color("f4b26b"))
		draw_rect(Rect2(-3, -46, 6, 3), Color("f4b26b"))
	if is_enemy:
		draw_rect(Rect2(-24, -72, 48, 4), Color("342332"))
		draw_rect(Rect2(-24, -72, 48.0 * model.hp / model.stats.max_hp, 4), Color("d97884"))

func _draw_slash(reach: float, facing: int) -> void:
	var progress := clampf((model.attack_progress() - model.attack_active_start()) / (model.attack_active_end()-model.attack_active_start()), 0.0, 1.0)
	var rising := model.combo_step == 2
	var heavy := model.combo_step == 3
	var leading_angle := lerpf(0.1, 0.8, progress)
	var origin := Vector2(12*facing, -65) if mounted else Vector2(0, -27)
	var points := PackedVector2Array()
	# A tapered crescent travels downward; mirroring preserves sword direction.
	for index in range(9):
		var angle := leading_angle - 1.5 + index * 1.5 / 8.0
		points.append((origin + Vector2(cos(angle) * facing, sin(angle) * (-0.55 if rising else 0.55)) * reach).round())
	for index in range(8, -1, -1):
		var angle := leading_angle - 1.5 + index * 1.5 / 8.0
		var radius := reach - 1.0 - sin(index * PI / 8.0) * (9.0 if heavy else 5.0)
		points.append((origin + Vector2(cos(angle) * facing, sin(angle) * (-0.55 if rising else 0.55)) * radius).round())
	var tint := Color("ffbd68") if is_enemy else (Color("d2fff0") if heavy else Color("8ce9e1"))
	draw_colored_polygon(points, Color(tint, 0.85 if heavy else 0.65))
	var tip := origin + Vector2(cos(leading_angle) * facing, sin(leading_angle) * (-0.55 if rising else 0.55)) * reach
	draw_line((tip - Vector2(3 * facing, 5)).round(), tip.round(), Color("fff2cd"), 2.0)

func _draw_dash_trail() -> void:
	for sample in _dash_trail:
		var texture: Texture2D = sample.texture
		var alpha := 0.35 * (1.0 - float(sample.age) / 0.12)
		draw_set_transform(sample.origin - global_position, 0.0, Vector2(sample.facing, 1))
		draw_texture(texture, -texture.get_size() * 0.5, Color(0.4, 1.0, 0.95, alpha))
	draw_set_transform(Vector2.ZERO)
