extends Node
## Isolated theatre: the real campaign actors and combat, with no player save or input.
signal completed
const GAME=preload("res://scenes/frontier.tscn")
const DURATION: float=25.0
var elapsed: float=0.0
var game: Node2D
var _shot: int=-1
var _attack_at: float=0.0
var _finished: bool=false
func _ready() -> void:
 game=GAME.instantiate()
 game.campaign_save_path="";game.audio_preferences_path=""
 game.tuning=game.tuning.duplicate();game.tuning.larger_desktop_window=false
 add_child(game)
 game.set_physics_process(false);game.controls.set_process_unhandled_key_input(false)
 game.hud.hide();game.hud.set_process(false);game.hud.cancel_touch_gestures()
 game.hud.drag_controls.enabled=false
 game.view.interactions_visible=false
 game.knight.position=Vector2(-280,430)
 game.get_node("Knight/Camera2D").position.x=130
 game.get_node("Knight/Camera2D").reset_smoothing()
 game.sim.survival.enabled=false
 game.sim.hero.stats.max_hp=500;game.sim.hero.hp=500
 game.sim.hero.stats.max_stamina=200;game.sim.hero.stamina=200
 game.sim.pouch.amount=0
 game.sim.clock.remaining=game.sim.clock.day_seconds*0.55
 game.audio.music_volume=0.22;game.audio.effects_volume=0.4
 game.get_node("Knight/Camera2D").force_update_scroll()
 game.knight.refresh_visual(0);game._sync_knight_equipment()
 game.view.present(game.sim,game.knight.position.x)
 game._water.present(game.sim);game._lantern.present(game.sim,game.knight);game._sunbeams.present(game.sim)
func _physics_process(seconds: float) -> void:
 if _finished or game==null:return
 elapsed+=seconds
 if elapsed>=DURATION:
  _finished=true;completed.emit();return
 var shot: int=0 if elapsed<4 else 1 if elapsed<10 else 2 if elapsed<18 else 3
 if shot!=_shot:_enter(shot)
 var sim: RefCounted=game.sim
 sim.advance(seconds,game.knight.position.x,430)
 var moving: float=0.0
 if shot==0 and game.knight.position.x<25:moving=0.42
 if shot==1 and elapsed>7 and game.knight.position.x<sim.world.sites.workshop-20:moving=0.65
 if shot>=2:
  if elapsed>=_attack_at:
   sim.hero.start_attack();_attack_at=elapsed+0.29
  sim.hero.stamina=maxf(sim.hero.stamina,80)
 game.knight.advance_motion(moving,false,seconds)
 if shot>=2:sim.strike_from(game.knight.position.x,430)
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
 elif shot==2:
  game.knight.position=Vector2(650,430);game.get_node("Knight/Camera2D").reset_smoothing()
  sim.clock.is_night=true;sim.clock.remaining=sim.clock.night_seconds*0.65
  for i in range(4):
   var enemy: Dictionary=sim._spawn_raider();enemy.x=710+i*105;enemy.side=1
   sim.raiders.append(enemy)
  sim.world.people[1].x=560
 elif shot==3:
  sim.raiders.clear();game.knight.position=Vector2(650,430)
  for rift: Dictionary in sim.mission.rifts:rift.sealed=true
  sim._summon_dragon(game.knight.position.x)
  if not sim.raiders.is_empty():sim.raiders[0].x=970;sim.raiders[0].cooldown=0.8
  game.get_node("Knight/Camera2D").position.x=200
