extends Node
const Cues=preload("res://presentation/campaign_audio_cues.gd")
const Music=preload("res://presentation/campaign_music.gd")
const Ambience=preload("res://presentation/campaign_ambience.gd")
const SOUNDS={
 "arrow_hit":[preload("res://art/audio/campaign-v002/arrow_hit.wav")],
 "bow_shot":[preload("res://art/audio/campaign-v002/bow_shot.wav")],
 "build":[preload("res://art/audio/campaign-v002/build.wav")],
 "charge_empty":[preload("res://art/audio/campaign-v002/charge_empty.wav")],
 "chest":[preload("res://art/audio/campaign-v002/chest.wav")],
 "core_hit":[preload("res://art/audio/campaign-v002/core_hit.wav")],
 "crystal_drop":[preload("res://art/audio/campaign-v002/crystal_drop.wav")],
 "crystal_land":[preload("res://art/audio/campaign-v002/crystal_land_1.wav"),preload("res://art/audio/campaign-v002/crystal_land_2.wav"),preload("res://art/audio/campaign-v002/crystal_land_3.wav")],
 "dash":[preload("res://art/audio/campaign-v002/dash.wav")],
 "dawn":[preload("res://art/audio/campaign-v002/dawn.wav")],
 "death":[preload("res://art/audio/campaign-v002/death.wav")],
 "defeat":[preload("res://art/audio/campaign-v002/defeat.wav")],
 "dragon_arrival":[preload("res://art/audio/campaign-v002/dragon_arrival.wav")],
 "dragon_death":[preload("res://art/audio/campaign-v002/dragon_death.wav")],
 "dragon_fire":[preload("res://art/audio/campaign-v002/dragon_fire.wav")],
 "dragon_hurt":[preload("res://art/audio/campaign-v002/dragon_hurt.wav")],
 "dragon_wing":[preload("res://art/audio/campaign-v002/dragon_wing.wav")],
 "enemy_attack":[preload("res://art/audio/campaign-v002/enemy_attack_1.wav"),preload("res://art/audio/campaign-v002/enemy_attack_2.wav"),preload("res://art/audio/campaign-v002/enemy_attack_3.wav")],
 "enemy_death":[preload("res://art/audio/campaign-v002/enemy_death.wav")],
 "enemy_grab":[preload("res://art/audio/campaign-v002/enemy_grab.wav")],
 "enemy_telegraph":[preload("res://art/audio/campaign-v002/enemy_telegraph.wav")],
 "farewell":[preload("res://art/audio/campaign-v002/farewell.wav")],
 "footstep":[preload("res://art/audio/campaign-v002/footstep_1.wav"),preload("res://art/audio/campaign-v002/footstep_2.wav"),preload("res://art/audio/campaign-v002/footstep_3.wav")],
 "footstep_slow":[preload("res://art/audio/campaign-v002/footstep_slow_1.wav"),preload("res://art/audio/campaign-v002/footstep_slow_2.wav"),preload("res://art/audio/campaign-v002/footstep_slow_3.wav")],
 "gatekeeper_appear":[preload("res://art/audio/campaign-v002/gatekeeper_appear.wav")],
 "handoff":[preload("res://art/audio/campaign-v002/handoff.wav")],
 "heal":[preload("res://art/audio/campaign-v002/heal.wav")],
 "heavy":[preload("res://art/audio/campaign-v002/heavy.wav")],
 "hit":[preload("res://art/audio/campaign-v002/hit_1.wav"),preload("res://art/audio/campaign-v002/hit_2.wav"),preload("res://art/audio/campaign-v002/hit_3.wav")],
 "horse_gallop":[preload("res://art/audio/campaign-v002/horse_gallop.wav")],
 "hurt":[preload("res://art/audio/campaign-v002/hurt.wav")],
 "ignition":[preload("res://art/audio/campaign-v002/ignition.wav")],
 "kingdom":[preload("res://art/audio/campaign-v002/kingdom.wav")],
 "module_equip":[preload("res://art/audio/campaign-v002/module_equip.wav")],
 "module_pickup":[preload("res://art/audio/campaign-v002/module_pickup.wav")],
 "module_store":[preload("res://art/audio/campaign-v002/module_store.wav")],
 "mount":[preload("res://art/audio/campaign-v002/mount.wav")],
 "night":[preload("res://art/audio/campaign-v002/night.wav")],
 "pay":[preload("res://art/audio/campaign-v002/pay.wav")],
 "pickup":[preload("res://art/audio/campaign-v002/pickup_1.wav"),preload("res://art/audio/campaign-v002/pickup_2.wav"),preload("res://art/audio/campaign-v002/pickup_3.wav")],
 "portal_spawn":[preload("res://art/audio/campaign-v002/portal_spawn.wav")],
 "raid_warning":[preload("res://art/audio/campaign-v002/raid_warning.wav")],
 "recruit":[preload("res://art/audio/campaign-v002/recruit.wav")],
 "resident_hit":[preload("res://art/audio/campaign-v002/resident_hit.wav")],
 "seal":[preload("res://art/audio/campaign-v002/seal.wav")],
 "seal_progress":[preload("res://art/audio/campaign-v002/seal_progress.wav")],
 "shield":[preload("res://art/audio/campaign-v002/shield.wav")],
 "slash1":[preload("res://art/audio/campaign-v002/slash1_1.wav"),preload("res://art/audio/campaign-v002/slash1_2.wav"),preload("res://art/audio/campaign-v002/slash1_3.wav")],
 "slash2":[preload("res://art/audio/campaign-v002/slash2_1.wav"),preload("res://art/audio/campaign-v002/slash2_2.wav"),preload("res://art/audio/campaign-v002/slash2_3.wav")],
 "slash3":[preload("res://art/audio/campaign-v002/slash3_1.wav"),preload("res://art/audio/campaign-v002/slash3_2.wav"),preload("res://art/audio/campaign-v002/slash3_3.wav")],
 "slot_complete":[preload("res://art/audio/campaign-v002/slot_complete.wav")],
 "slot_refund":[preload("res://art/audio/campaign-v002/slot_refund.wav")],
 "sword_drop":[preload("res://art/audio/campaign-v002/sword_drop.wav")],
 "sword_recover":[preload("res://art/audio/campaign-v002/sword_recover.wav")],
 "throw":[preload("res://art/audio/campaign-v002/throw.wav")],
 "tool_pickup":[preload("res://art/audio/campaign-v002/tool_pickup.wav")],
 "tower_laser":[preload("res://art/audio/campaign-v002/tower_laser.wav")],
 "ui_confirm":[preload("res://art/audio/campaign-v002/ui_confirm.wav")],
 "ui_mute":[preload("res://art/audio/campaign-v002/ui_mute.wav")],
 "ui_pause":[preload("res://art/audio/campaign-v002/ui_pause.wav")],
 "ui_resume":[preload("res://art/audio/campaign-v002/ui_resume.wav")],
 "ui_save":[preload("res://art/audio/campaign-v002/ui_save.wav")],
 "ui_select":[preload("res://art/audio/campaign-v002/ui_select.wav")],
 "upgrade":[preload("res://art/audio/campaign-v002/upgrade.wav")],
 "victory":[preload("res://art/audio/campaign-v002/victory.wav")],
 "wall_break":[preload("res://art/audio/campaign-v002/wall_break.wav")],
 "wall_hit":[preload("res://art/audio/campaign-v002/wall_hit_1.wav"),preload("res://art/audio/campaign-v002/wall_hit_2.wav"),preload("res://art/audio/campaign-v002/wall_hit_3.wav")],
 "wall_repair":[preload("res://art/audio/campaign-v002/wall_repair.wav")],
 "work_chop":[preload("res://art/audio/campaign-v002/work_chop_1.wav"),preload("res://art/audio/campaign-v002/work_chop_2.wav"),preload("res://art/audio/campaign-v002/work_chop_3.wav")],
 "work_hammer":[preload("res://art/audio/campaign-v002/work_hammer_1.wav"),preload("res://art/audio/campaign-v002/work_hammer_2.wav"),preload("res://art/audio/campaign-v002/work_hammer_3.wav")],
 "work_harvest":[preload("res://art/audio/campaign-v002/work_harvest_1.wav"),preload("res://art/audio/campaign-v002/work_harvest_2.wav"),preload("res://art/audio/campaign-v002/work_harvest_3.wav")],
 "work_mine":[preload("res://art/audio/campaign-v002/work_mine_1.wav"),preload("res://art/audio/campaign-v002/work_mine_2.wav"),preload("res://art/audio/campaign-v002/work_mine_3.wav")]}## Emitted when feedback is accepted; headless validates commands without starting a mixer.
signal cue_requested(kind: String)
@export_range(-40.0,0.0,1.0) var volume_db: float=-10.0
@export var enabled:=true:
 set(value):
  enabled=value
  if not enabled:stop()
  if music!=null:music.enabled=value
  if ambience!=null:ambience.enabled=value
var music_volume:=0.4:
 set(value):
  music_volume=value
  if music!=null:music.volume=value
var effects_volume:=0.8
var ambience_volume:=0.6:
 set(value):
  ambience_volume=value
  if ambience!=null:ambience.volume=value
var suspended:=false:
 set(value):
  suspended=value
  if music!=null:music.suspended=value
  if ambience!=null:ambience.suspended=value
var music: Node
var ambience: Node
var cues=Cues.new()
var voices: Array[AudioStreamPlayer]=[]
var _cooldowns: Dictionary={}
var _last_variant: Dictionary={}
var _ignition_run: RefCounted
var _ignition_released: bool=false
func _ready() -> void:
 music=Music.new()
 music.name="Music"
 music.volume=music_volume
 music.enabled=enabled
 add_child(music)
 ambience=Ambience.new()
 ambience.name="Ambience"
 ambience.volume=ambience_volume
 ambience.enabled=enabled
 add_child(ambience)
 for i in range(6):
  var voice=AudioStreamPlayer.new()
  voice.bus="SFX"
  add_child(voice)
  voices.append(voice)
func observe(seconds: float,sim,x: float,paused: bool) -> void:
 if is_instance_valid(music):music.observe(seconds,sim,x,paused)
 if is_instance_valid(ambience):ambience.observe(seconds,sim,x,paused)
 for key in _cooldowns:_cooldowns[key]=maxf(0,_cooldowns[key]-seconds)
 var pending: Array[String]=cues.sample(sim,x,paused or not enabled or suspended)
 if paused or not enabled or suspended:
  for voice in voices:voice.stop()
  return
 if not is_same(_ignition_run,sim):_ignition_run=sim;_ignition_released=false
 if not _ignition_released:
  for effect in sim.effects:
   if effect.kind=="camp_ignition" and effect.life<=1.58:
    _ignition_released=true
    _play("ignition")
 for kind in pending:_play(kind)
func _play(kind: String) -> void:
 if effects_volume<=0:return
 if not SOUNDS.has(kind):return
 if _cooldowns.get(kind,0.0)>0:return
 var available=voices.filter(func(v):return not v.playing)
 if available.is_empty():
  # Small pickups cannot cut off a sword hit, danger cue, or result.
  if kind in ["pickup","pay"]:return
  available=[voices[0]]
 var voice: AudioStreamPlayer=available[0]
 voice.stop()
 voice.bus="UI" if kind.begins_with("ui_") else "SFX"
 voice.stream=_variant(kind)
 voice.volume_db=volume_db+linear_to_db(maxf(0.0001,effects_volume))
 if DisplayServer.get_name()!="headless":voice.play()
 voices.erase(voice);voices.append(voice)
 _cooldowns[kind]=0.08 if kind in ["pickup","hit","heavy"] else 0.05
 cue_requested.emit(kind)
func _variant(kind: String) -> AudioStream:
 var choices: Array=SOUNDS[kind]
 if choices.size()==1:return choices[0]
 # Never the same take twice running, so repeated blows do not sound mechanical.
 var index: int=randi()%choices.size()
 if index==_last_variant.get(kind,-1):index=(index+1)%choices.size()
 _last_variant[kind]=index
 return choices[index]
func stop() -> void:
 if is_instance_valid(music):music.stop()
 if is_instance_valid(ambience):ambience.stop()
 for voice in voices:voice.stop()

func _exit_tree() -> void:
 stop()
 for voice in voices:voice.stream=null
 cues=null
