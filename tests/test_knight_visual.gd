extends RefCounted
const KnightVisual = preload("res://presentation/knight_visual.gd")

func test_idle_animation_advances_only_with_game_time(t) -> void:
	var view = KnightVisual.new()
	var pose := {"alive": true, "facing": 1, "moving": false, "invulnerable": false}
	view.present(pose, 0.26)
	t.equal(view.frame, 1, "idle advances to its next drawing")
	view.present(pose, 0.0)
	t.equal(view.frame, 1, "paused game time holds the drawing")
	view.free()

func test_death_facing_and_restart_are_visible(t) -> void:
	var view = KnightVisual.new()
	view.present({"alive": true, "facing": -1, "moving": false, "invulnerable": true}, 0.26)
	t.truth(view.flip_h, "left-facing knight mirrors its drawing")
	t.truth(view.modulate != Color.WHITE, "invulnerability has visual feedback")
	view.present({"alive": false, "facing": -1, "moving": false, "invulnerable": false}, 0.1)
	t.equal(view.visible, false, "defeated knight disappears with its model")
	view.reset_pose()
	t.truth(view.visible, "restart restores knight artwork")
	t.equal(view.frame, 0, "restart begins a fresh idle loop")
	t.equal(view.modulate, Color.WHITE, "restart clears damage tint")
	view.free()

func test_grounded_motion_plays_run_then_returns_to_idle(t) -> void:
	var view = KnightVisual.new()
	var pose := {"alive": true, "facing": 1, "moving": true, "invulnerable": false, "grounded": true}
	view.present(pose, 0.1)
	t.equal(view.animation, &"run", "ground movement selects run artwork")
	t.equal(view.frame, 1, "run advances at its configured cadence")
	pose.moving = false
	view.present(pose, 0.0)
	t.equal(view.animation, &"idle", "stopping returns to idle")
	t.equal(view.frame, 0, "new clip begins from its first frame")
	view.free()

func test_attack_frames_follow_combat_progress_instead_of_render_time(t) -> void:
	var view = KnightVisual.new()
	var pose := {"alive": true, "facing": -1, "moving": true, "invulnerable": false, "attack_progress": 0.0}
	view.present(pose, 0.8)
	t.equal(view.animation, &"attack", "attack overrides running")
	t.equal(view.frame, 0, "windup stays tied to combat even after long render delta")
	pose.attack_progress = 0.15
	view.present(pose, 0.0)
	t.equal(view.frame, 1, "coiled anticipation precedes the cut")
	pose.attack_progress = 0.45
	view.present(pose, 0.0)
	t.equal(view.frame, 4, "horizontal blade makes first contact before the downward follow-through")
	pose.attack_progress = 0.95
	view.present(pose, 0.0)
	t.equal(view.frame, 7, "recovery uses the final drawing")
	pose.attack_progress = 1.0
	view.present(pose, 0.0)
	t.equal(view.animation, &"run", "completed swing releases movement animation")
	view.free()

func test_airborne_does_not_play_ground_run_cycle(t) -> void:
	var view = KnightVisual.new()
	var pose := {"alive": true, "facing": 1, "moving": true, "invulnerable": false, "grounded": false}
	view.present(pose, 0.3)
	t.equal(view.animation, &"jump", "airborne movement selects dedicated jump artwork")
	t.equal(view.frame, 2, "zero vertical speed uses the apex drawing")
	view.free()

func test_attack_respects_authored_anticipation_and_recovery_durations(t) -> void:
	var view = KnightVisual.new()
	view.sprite_frames = view.sprite_frames.duplicate()
	var texture = view.sprite_frames.get_frame_texture(&"attack", 0)
	view.sprite_frames.clear(&"attack")
	for duration in [3.0, 1.0, 1.0, 1.0]:
		view.sprite_frames.add_frame(&"attack", texture, duration)
	var pose := {"alive": true, "facing": 1, "moving": false, "invulnerable": false, "attack_progress": 0.4}
	view.present(pose, 0.0)
	t.equal(view.frame, 0, "long anticipation remains visible until its authored duration ends")
	pose.attack_progress = 0.6
	view.present(pose, 0.0)
	t.equal(view.frame, 1, "strike begins when authored anticipation completes")
	view.free()

func test_enemy_telegraph_displays_raised_weapon_without_starting_swing(t) -> void:
	var view = KnightVisual.new()
	view.sprite_frames = view.sprite_frames.duplicate()
	view.sprite_frames.add_animation(&"windup")
	view.sprite_frames.add_frame(&"windup", view.sprite_frames.get_frame_texture(&"attack", 1))
	var pose := {"alive": true, "facing": -1, "moving": false, "invulnerable": false, "telegraph": true}
	view.present(pose, 0.2)
	t.equal(view.animation, &"windup", "guard raises its weapon throughout the warning")
	pose.telegraph = false
	view.present(pose, 0.0)
	t.equal(view.animation, &"idle", "cancelled warning returns to guard stance")
	view.free()

func test_dash_has_launch_burst_braking_and_freezes_with_progress(t) -> void:
	var view = KnightVisual.new()
	var pose := {"alive": true, "facing": -1, "moving": true, "invulnerable": true, "dashing": true, "dash_progress": 0.0}
	view.present(pose, 0.5)
	t.equal(view.animation, &"dash", "dash uses a distinct silhouette rather than standing")
	t.equal(view.frame, 0, "dash begins with launch pose")
	pose.dash_progress = 0.4
	view.present(pose, 0.0)
	t.equal(view.frame, 1, "burst follows actual dash progress")
	view.present(pose, 0.0)
	t.equal(view.frame, 1, "paused dash holds its burst pose")
	pose.dash_progress = 0.95
	view.present(pose, 0.0)
	t.equal(view.frame, 3, "dash ends with braking pose")
	pose.dashing = false
	view.present(pose, 0.0)
	t.equal(view.animation, &"run", "movement regains run animation after dash")
	view.free()

func test_default_cleave_shows_all_eight_poses_at_thirty_fps(t) -> void:
	var stats = preload("res://domain/combat_stats.gd").new()
	var view = KnightVisual.new()
	var seen := {}
	var pose := {"alive": true, "facing": 1, "moving": false, "invulnerable": false}
	var elapsed := 0.0
	while elapsed < stats.attack_duration:
		pose.attack_progress = elapsed / stats.attack_duration
		view.present(pose, 1.0 / 30.0)
		seen[view.frame] = true
		elapsed += 1.0 / 30.0
	t.equal(seen.size(), 8, "mobile cadence must show every transition drawing")
	view.free()

func test_running_phase_continues_through_attack_and_recovery(t) -> void:
	var view=KnightVisual.new()
	var pose={"alive":true,"facing":1,"moving":true,"grounded":true,"invulnerable":false,"attack_progress":1.0}
	view.present(pose,0.15)
	pose.attack_progress=0.4
	view.present(pose,0.2)
	pose.attack_progress=1.0
	view.present(pose,0)
	t.equal(view.frame,4,"running resumes at continuing stride, not frame zero")
	view.present(pose,0)
	t.equal(view.frame,4,"paused stride holds its phase")
	view.free()

func test_moving_swing_displays_running_legs_without_changing_attack_timing(t) -> void:
	var view=KnightVisual.new()
	view.set("moving_attack_atlas",preload("res://art/characters/fluid-v001/moving-attack.png"))
	var pose={"alive":true,"facing":1,"moving":true,"grounded":true,"invulnerable":false,"attack_progress":0.45}
	view.present(pose,0.1)
	var legs=view.get_node_or_null("MovingAttack")
	t.truth(legs!=null and legs.visible,"moving attack draws its combined gait and sword")
	t.equal(view.frame,4,"moving attack keeps authored strike timing")
	pose.moving=false
	view.present(pose,0)
	t.truth(legs!=null and not legs.visible,"stopping restores planted attack pose")
	view.free()

func test_return_cut_starts_from_previous_low_pose_and_rises_while_running(t) -> void:
	var view = KnightVisual.new()
	view.moving_attack_atlas = preload("res://art/characters/fluid-v001/moving-attack.png")
	var pose = {"alive":true,"facing":1,"moving":true,"grounded":true,"invulnerable":false,"attack_progress":0.95,"combo_step":1}
	view.present(pose,0.1)
	var previous: int = view.frame
	pose.combo_step = 2
	pose.attack_progress = 0.0
	view.present(pose,0.0)
	t.equal(view.frame, previous, "return cut picks up the first cut's low sword")
	pose.attack_progress = 0.95
	view.present(pose,0.15)
	t.equal(view.frame, 0, "return cut ends with sword raised for the finisher")
	var stride = view.get_node("MovingAttack")
	t.truth(stride.visible, "return cut keeps its running legs")
	t.equal(int(stride.texture.region.position.x), 0, "combined atlas follows reversed sword pose")
	pose.combo_step = 3
	pose.attack_progress = 0.0
	view.present(pose,0.0)
	t.equal(view.frame, 0, "finisher begins from raised return-cut pose")
	view.free()

func test_authored_combo_uses_independent_forward_frames_and_freezes(t) -> void:
	var view = KnightVisual.new()
	var motion = preload("res://data/combo_motion.gd").new()
	# Existing textures stand in for imported pixels; assert actual visible regions.
	motion.planted_atlas = preload("res://art/characters/fluid-v001/moving-attack.png")
	motion.moving_atlas = motion.planted_atlas
	view.combo_motion = motion
	var pose = {"alive":true,"facing":-1,"moving":false,"grounded":true,"invulnerable":false,"attack_progress":0.0,"combo_step":2}
	view.present(pose,0.1)
	var sprite = view.get_node_or_null("ComboAttack")
	t.truth(sprite!=null and sprite.visible,"authored return has its own visible sprite")
	if sprite==null:
		view.free()
		return
	t.equal(sprite.texture.region,Rect2(0,128,160,128),"return begins on its first drawing, not reversed slash")
	t.truth(sprite.flip_h,"authored attack mirrors to face left")
	pose.attack_progress=0.5
	view.present(pose,0.0)
	var region: Rect2 = sprite.texture.region
	view.present(pose,0.0)
	t.equal(sprite.texture.region,region,"paused pose is deterministic")
	pose.combo_step=3
	view.present(pose,0)
	t.equal(sprite.texture.region.position.y,256.0,"finisher selects independent choreography")
	pose.moving=true
	view.present(pose,0.1)
	var moving=view.get_node("MovingAttack")
	t.truth(moving.visible and not sprite.visible,"moving combo uses one integrated body")
	t.truth(moving.texture.region.position.y>=2048,"moving finisher selects its own gait group")
	pose.attack_progress=1.0
	view.present(pose,0)
	t.truth(not sprite.visible and not moving.visible,"recovery restores normal locomotion without stale overlay")
	view.free()

func test_equipment_refresh_never_reopens_another_body(t) -> void:
	var view = KnightVisual.new()
	view.combo_motion = preload("res://data/combo_motion.gd").new()
	view.combo_motion.planted_atlas = preload("res://art/characters/fluid-v001/moving-attack.png")
	var pose = {"alive":true,"facing":1,"moving":true,"grounded":true,"invulnerable":false,"attack_progress":1.0}
	for mode in ["unarmed", "rest", "mounted_rest", "mounted", "combo", "run"]:
		view.unarmed = mode == "unarmed"
		view.breathing = mode in ["rest", "mounted_rest"]
		view.set_mounted(mode in ["mounted", "mounted_rest"])
		pose.attack_progress = 0.45 if mode == "combo" else 1.0
		view.present(pose, 0.1)
		# The real campaign refreshes equipment after presenting each physics frame.
		view.set_equipment(3, 0)
		view.set_mounted(mode in ["mounted", "mounted_rest"])
		t.equal(_visible_bodies(view), 1, mode + " has exactly one body after equipment refresh")
	view.unarmed = true
	view.present(pose, 0.1)
	view.set_mounted(true)
	view.present(pose, 0.1)
	t.equal(_visible_bodies(view), 1, "mounting replaces the previously visible unarmed body")
	view.reset_pose()
	t.equal(_visible_bodies(view), 1, "reset removes stale alternative bodies")
	view.free()

func _visible_bodies(view) -> int:
	var count: int = 1 if view.visible and view.self_modulate.a > 0 else 0
	for child in view.get_children():
		if child is Sprite2D and child.visible and child.texture != null:
			count += 1
	return count
