extends Node
## Isolated theatre: the real campaign actors and combat, with no player save or input.
signal completed
const GAME=preload("res://scenes/frontier.tscn")
const DIRECTION: Resource=preload("res://data/opening_direction.tres")
# Preserve the cinematic mix while following the player's preference levels.
const MUSIC_MIX: float=0.55
const EFFECTS_MIX: float=0.5
var sound_levels: Dictionary={} # Validated preferences supplied by the title; never written here.
var elapsed: float=0.0
var game: Node2D
var _shot: int=-1
var _finished: bool=false
func _ready() -> void:
 game=GAME.instantiate()
 game.campaign_save_path="";game.audio_preferences_path=""
 game._map_seed=416;game._seed_initialized=true
 game.tuning=game.tuning.duplicate();game.tuning.larger_desktop_window=false
 add_child(game)
 game.set_physics_process(false);game.controls.set_process_unhandled_key_input(false);game.controls.set_process_unhandled_input(false)
 game.hud.hide();game.hud.set_process(false);game.hud.cancel_touch_gestures()
 game.hud.drag_controls.enabled=false
 game.view.interactions_visible=false;game.view.cinematic=true
 game.knight.position=Vector2(-280,430)
 game.get_node("Knight/Camera2D").position.x=130
 game.get_node("Knight/Camera2D").reset_smoothing()
 game.sim.survival.enabled=false
 game.sim.hero.stats.max_hp=500;game.sim.hero.hp=500
 game.sim.hero.stats.max_stamina=200;game.sim.hero.stamina=200
 game.sim.pouch.amount=0
 game.sim.clock.remaining=game.sim.clock.day_seconds*0.55
 _configure_sound()
 game.get_node("Knight/Camera2D").force_update_scroll()
 game.knight.refresh_visual(0);game._sync_knight_equipment()
 game.view.present(game.sim,game.knight.position.x)
 game._water.present(game.sim);game._lantern.present(game.sim,game.knight);game._sunbeams.present(game.sim)
func _configure_sound() -> void:
 if not sound_levels.is_empty():
  game.audio.music_volume=float(sound_levels.music)
  game.audio.effects_volume=float(sound_levels.effects)
  game.audio.ambience_volume=float(sound_levels.ambience)
  game.audio.enabled=not bool(sound_levels.muted)
 game.audio.music_volume*=MUSIC_MIX
 game.audio.effects_volume*=EFFECTS_MIX

func _physics_process(seconds: float) -> void:
 if _finished or game==null:return
 elapsed+=seconds
 if elapsed>=DIRECTION.duration:
  _finished=true;completed.emit();return
 var shot: int=0
 for index: int in range(DIRECTION.shot_starts.size()):
  if elapsed>=DIRECTION.shot_starts[index]:shot=index
 if shot!=_shot:_enter(shot)
 var sim: RefCounted=game.sim
 sim.advance(seconds,game.knight.position.x,430)
 var moving: float=0.0
 if shot==0 and game.knight.position.x<25:moving=0.42
 if shot==1 and elapsed>DIRECTION.shot_starts[1]+2.0 and game.knight.position.x<sim.world.sites.workshop-20:moving=0.65
 game.knight.advance_motion(moving,false,seconds)
 game.knight.refresh_visual(seconds);game._sync_knight_equipment()
 game.view.present(sim,game.knight.position.x)
 game._water.present(sim);game._lantern.present(sim,game.knight);game._sunbeams.present(sim)
 game.audio.observe(seconds,sim,game.knight.position.x,false)
func _enter(shot: int) -> void:
 _shot=shot
 var sim: RefCounted=game.sim
 if shot==1:
  game.knight.position=Vector2(30,430);sim.interact(30,"hall")
  sim.world.people[0].role="engineer";sim.world.people[0].x=190
  sim.world.people[1].role="hunter";sim.world.people[1].x=250
  sim.world.walls.wall.pending=true
  sim.pouch.burst(5,190,430)
 elif shot==3:
  sim.clock.is_night=true;sim.clock.remaining=sim.clock.night_seconds*0.65
  sim.raiders.clear();game.knight.position=Vector2(650,430);sim.hero.facing=1
  for rift: Dictionary in sim.mission.rifts:rift.sealed=true
  sim._summon_dragon(game.knight.position.x)
  if not sim.raiders.is_empty():sim.raiders[0].x=970;sim.raiders[0].cooldown=DIRECTION.duration
  game.get_node("Knight/Camera2D").position.x=185
