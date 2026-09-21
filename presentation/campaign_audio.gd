extends Node
const Cues=preload("res://presentation/campaign_audio_cues.gd")
const SOUNDS={
 "slash1":preload("res://art/audio/campaign-v001/slash1.wav"),"slash2":preload("res://art/audio/campaign-v001/slash2.wav"),"slash3":preload("res://art/audio/campaign-v001/slash3.wav"),
 "hit":preload("res://art/audio/campaign-v001/hit.wav"),"heavy":preload("res://art/audio/campaign-v001/heavy.wav"),"hurt":preload("res://art/audio/campaign-v001/hurt.wav"),"dash":preload("res://art/audio/campaign-v001/dash.wav"),
 "pickup":preload("res://art/audio/campaign-v001/pickup.wav"),"pay":preload("res://art/audio/campaign-v001/pay.wav"),"chest":preload("res://art/audio/campaign-v001/chest.wav"),"recruit":preload("res://art/audio/campaign-v001/recruit.wav"),"build":preload("res://art/audio/campaign-v001/build.wav"),
 "night":preload("res://art/audio/campaign-v001/night.wav"),"seal":preload("res://art/audio/campaign-v001/seal.wav"),"victory":preload("res://art/audio/campaign-v001/victory.wav"),"defeat":preload("res://art/audio/campaign-v001/defeat.wav")}
## Emitted when feedback is accepted; headless validates commands without starting a mixer.
signal cue_requested(kind: String)
@export_range(-40.0,0.0,1.0) var volume_db: float=-10.0
@export var enabled:=true:
 set(value):
  enabled=value
  if not enabled:stop()
var music_volume:=0.4
var effects_volume:=0.8
var suspended:=false
var music_player: AudioStreamPlayer
var cues=Cues.new()
var voices: Array[AudioStreamPlayer]=[]
var _cooldowns: Dictionary={}
var _ignition_run: RefCounted
var _ignition_released: bool=false
func _ready() -> void:
 music_player=AudioStreamPlayer.new()
 music_player.name="Music"
 var loop: AudioStreamWAV=preload("res://art/audio/frontier-music-v001/last-refuge.wav").duplicate()
 loop.loop_mode=AudioStreamWAV.LOOP_FORWARD
 loop.loop_end=loop.data.size()/2
 music_player.stream=loop
 add_child(music_player)
 for i in range(6):
  var voice=AudioStreamPlayer.new()
  add_child(voice)
  voices.append(voice)
func observe(seconds: float,sim,x: float,paused: bool) -> void:
 if is_instance_valid(music_player):
  music_player.volume_db=-12+linear_to_db(maxf(0.0001,music_volume))
  if enabled and not suspended and music_volume>0 and DisplayServer.get_name()!="headless":
   if not music_player.playing:music_player.play()
  else:music_player.stop()
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
    _play("seal")
 for kind in pending:_play(kind)
func _play(kind: String) -> void:
 if effects_volume<=0:return
 if _cooldowns.get(kind,0.0)>0:return
 var available=voices.filter(func(v):return not v.playing)
 if available.is_empty():
  # Small pickups cannot cut off a sword hit, danger cue, or result.
  if kind in ["pickup","pay"]:return
  available=[voices[0]]
 var voice: AudioStreamPlayer=available[0]
 voice.stop()
 voice.stream=SOUNDS[kind]
 voice.volume_db=volume_db+linear_to_db(maxf(0.0001,effects_volume))
 if DisplayServer.get_name()!="headless":voice.play()
 voices.erase(voice);voices.append(voice)
 _cooldowns[kind]=0.08 if kind in ["pickup","hit","heavy"] else 0.05
 cue_requested.emit(kind)
func stop() -> void:
 if is_instance_valid(music_player):music_player.stop()
 for voice in voices:voice.stop()

func _exit_tree() -> void:
 stop()
 for voice in voices:voice.stream=null
 if is_instance_valid(music_player):music_player.stream=null
 cues=null
