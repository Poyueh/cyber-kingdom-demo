extends RefCounted
## The training arena is where combat feel is judged, so it needs the combat sounds.
const Path="res://presentation/arena_audio_cues.gd"
const Stats=preload("res://domain/combat_stats.gd")
const Fighter=preload("res://domain/combatant.gd")

func _duel():
	var hero=Fighter.new(Stats.new())
	var foe=Fighter.new(Stats.new())
	hero.stats.combo_enabled=true
	return [hero,foe]

func test_the_duel_is_heard_swinging_landing_and_ending(t):
	t.truth(ResourceLoader.exists(Path),"arena cue observer exists")
	if not ResourceLoader.exists(Path):return
	var cues=load(Path).new()
	var pair=_duel()
	var hero=pair[0];var foe=pair[1]
	t.equal(cues.sample(hero,foe,0.0,false),[],"opening the arena replays nothing")
	hero.start_attack()
	t.equal(cues.sample(hero,foe,0.0,false),[],"windup is silent until the blade is active")
	hero.advance(hero.stats.attack_duration*0.42)
	t.truth("slash1" in cues.sample(hero,foe,0.0,false),"the active cut is heard")
	foe.invulnerability_remaining=0
	foe.take_damage(10)
	t.truth("hit" in cues.sample(hero,foe,0.0,false),"a landed blow is heard")
	hero.invulnerability_remaining=0
	hero.take_damage(10)
	t.truth("hurt" in cues.sample(hero,foe,0.0,false),"taking a blow is heard")
	hero.start_dash()
	t.truth("dash" in cues.sample(hero,foe,0.0,false),"the dash burst is heard")
	foe.invulnerability_remaining=0
	foe.hp=0
	var fallen: Array=cues.sample(hero,foe,0.0,false)
	t.truth("enemy_death" in fallen,"the sentinel going down is heard")
	t.equal(cues.sample(hero,foe,0.0,false).count("enemy_death"),0,"a fallen sentinel does not keep falling")

func test_a_warning_precedes_the_sentinel_strike(t):
	var cues=load(Path).new()
	var pair=_duel()
	cues.sample(pair[0],pair[1],0.0,false)
	t.truth("enemy_telegraph" in cues.sample(pair[0],pair[1],0.6,false),"the wind-up warns the player")
	t.equal(cues.sample(pair[0],pair[1],0.6,false).count("enemy_telegraph"),0,"the warning does not repeat")
	t.truth("enemy_attack" in cues.sample(pair[0],pair[1],0.0,false),"the blow that follows is heard")

func test_pause_swallows_arena_feedback(t):
	var cues=load(Path).new()
	var pair=_duel()
	cues.sample(pair[0],pair[1],0.0,false)
	pair[1].invulnerability_remaining=0
	pair[1].take_damage(10)
	t.equal(cues.sample(pair[0],pair[1],0.0,true),[],"pause consumes pending feedback")
	t.equal(cues.sample(pair[0],pair[1],0.0,false),[],"resuming never replays it")
