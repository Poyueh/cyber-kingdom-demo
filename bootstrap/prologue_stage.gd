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
var _attack_in: float=0.0
var _breath_queued: bool=false
var atmosphere: Node2D
func _ready() -> void:
 game=GAME.instantiate()
 game.campaign_save_path="";game.audio_preferences_path=""
 game._map_seed=416;game._seed_initialized=true
 game.tuning=game.tuning.duplicate();game.tuning.larger_desktop_window=false
 add_child(game)
 _isolate_cast()
 game.set_physics_process(false);game.controls.set_process_unhandled_key_input(false);game.controls.set_process_unhandled_input(false)
 game.hud.hide();game.hud.set_process(false);game.hud.cancel_touch_gestures()
 game.hud.drag_controls.enabled=false
 game.view.interactions_visible=false;game.view.cinematic=true
 game.knight.position=Vector2(-170,430)
 game.sim.world.sites.wall=DIRECTION.wall_x
 game.sim.world.sites.hall=DIRECTION.camp_x
 atmosphere=preload("res://presentation/prologue_atmosphere.gd").new()
 atmosphere.z_index=24;game.add_child(atmosphere)
 game.get_node("Knight/Camera2D").position.x=DIRECTION.camera_center-game.knight.position.x
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
func _isolate_cast() -> void:
 # The directed opening has its own cast; optional road encounters belong to play.
 var config: Dictionary=game._campaign_config.duplicate(true)
 for key: String in config.keys():
  if key.begins_with("trail_"):config.erase(key)
 game.sim=preload("res://application/campaign_session.gd").new(config,game.sim.hero.stats)
 game._campaign_config=config;game.journey=null
 game.knight.configure(game.sim.hero,game.knight_tuning)
 game.sword_feedback.reset(game.sim.effects)

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
 if elapsed>=DIRECTION.duration or (preload("res://infrastructure/distribution.gd").demo() and elapsed>=DIRECTION.shot_starts[4]):
  _finished=true;completed.emit();return
 var shot: int=0
 for index: int in range(DIRECTION.shot_starts.size()):
  if elapsed>=DIRECTION.shot_starts[index]:shot=index
 if shot!=_shot:_enter(shot)
 var sim: RefCounted=game.sim
 var acting: float=game.sword_feedback.advance(seconds)
 _attack_in-=seconds
 if shot==2 and _attack_in<=0:
  sim.hero.facing=1;sim.hero.start_attack();_attack_in=DIRECTION.sword_interval
 if shot==3 and not _breath_queued and not sim.raiders.is_empty():
  var dragon: Dictionary=sim.raiders.back()
  if dragon.x<=DIRECTION.dragon_strike_x:
   dragon.target={"kind":"wall","x":DIRECTION.wall_x,"wall_id":"wall"}
   dragon.windup=DIRECTION.dragon_warning_seconds;dragon.cooldown=4.4
   _breath_queued=true
 sim.advance(acting,game.knight.position.x,430)
 var moving: float=0.0
 if shot==0 and game.knight.position.x<DIRECTION.camp_x-35:moving=0.55
 game.knight.advance_motion(moving,false,acting)
 sim.strike_from(game.knight.position.x,game.knight.position.y)
 game.sword_feedback.observe(sim.effects,game.knight.position)
 var camera: Camera2D=game.get_node("Knight/Camera2D")
 camera.position.x=DIRECTION.camera_center-game.knight.position.x
 game.knight.refresh_visual(acting);game._sync_knight_equipment()
 game.view.present(sim,game.knight.position.x)
 atmosphere.present(sim,elapsed-DIRECTION.shot_starts[3],shot==3)
 game._water.present(sim);game._lantern.present(sim,game.knight);game._sunbeams.present(sim)
 game.audio.observe(seconds,sim,game.knight.position.x,false)

func _enter(shot: int) -> void:
 _shot=shot
 var sim: RefCounted=game.sim
 if shot==1:
  game.knight.position=Vector2(DIRECTION.camp_x+30,430);sim.interact(DIRECTION.camp_x,"hall")
  sim.world.people[0].role="engineer";sim.world.people[0].x=DIRECTION.wall_x-12
  sim.world.people[1].role="citizen";sim.world.people[1].x=150
  sim.world.walls.wall.pending=true
  sim.pouch.burst(5,DIRECTION.camp_x+55,430)
 elif shot==2:
  sim.clock.is_night=true;sim.clock.remaining=sim.clock.night_seconds*0.85
  game.knight.position=Vector2(DIRECTION.combat_x,430);sim.hero.facing=1
  for offset: float in [55.0,155.0,260.0]:
   var enemy: Dictionary=sim._spawn_raider()
   enemy.x=DIRECTION.combat_x+offset;enemy.direction=-1.0
   enemy.fighter.stats.max_hp=DIRECTION.enemy_health;enemy.fighter.hp=DIRECTION.enemy_health
   sim.raiders.append(enemy)
 elif shot==3:
  sim.raiders.clear();game.knight.position=Vector2(DIRECTION.wall_x-95,430);sim.hero.facing=1
  for rift: Dictionary in sim.mission.rifts:rift.sealed=true
  sim._summon_dragon(game.knight.position.x)
  var dragon: Dictionary=sim.raiders.back()
  dragon.x=DIRECTION.dragon_x;dragon.direction=-1.0;dragon.cooldown=0.6
  # The theatre uses the real wall damage rule, with enough force to break it.
  dragon.wall_damage=sim.world.wall_max_hp(sim.world.walls.wall.level)
  for person: Dictionary in sim.world.people:person.x=minf(person.x,100)
 elif shot==4:
  # Fade into the star visions after the defense has visibly fallen.
  game.set_physics_process(false)
