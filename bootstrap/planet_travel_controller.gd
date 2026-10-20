extends Node
## Save-before-switch transaction and modal lifetime live at the composition edge.
const Map=preload("res://presentation/star_map.gd")
const Direction=preload("res://data/outcome_direction.tres")
var root: Node
var map: Map
var liberation: Control
var _observed: int=0
var _cleared_seen: bool=false
var _was_paused: bool=false
var _finale_seconds: float=0.0
var _finale_left: bool=false
func _ready() -> void:
 var ceremony_layer: CanvasLayer=CanvasLayer.new();ceremony_layer.layer=60;add_child(ceremony_layer)
 liberation=preload("res://presentation/planet_liberation.gd").new();ceremony_layer.add_child(liberation)
 map=Map.new();add_child(map)
 map.destination_selected.connect(_depart)
 map.closed.connect(close)
func active() -> bool:return map!=null and map.visible
func observe(seconds: float=0.0) -> void:
 _announce_fallen_dragon()
 _observe_finale(seconds)
 if root.journey==null:return
 root.journey.observe(root.sim)
 liberation.present(root.journey,root.sim,root.hud.safe_rect(),root.paused,root.hud.immersive_feedback.day_caption_bounds())
 if not root.sim.planet.launch_requested:return
 root.sim.planet.launch_requested=false
 if root.sim.invasion_empty() and root.sim.planet.rocket_ready:
  open_chart(false)
func _announce_fallen_dragon() -> void:
 if _observed!=root.sim.get_instance_id():
  _observed=root.sim.get_instance_id();_cleared_seen=root.sim.planet.cleared
 elif root.sim.planet.cleared and not _cleared_seen:
  _cleared_seen=true
  if not root.sim.planet.core_claimed:root._arrival_banner.show_notice(tr("planet.dragon_down"),tr("planet.claim_info"))

## The Demo has no voyage: once its rocket epilogue has been read, back to the start menu.
func _observe_finale(seconds: float) -> void:
 if not (root.sim.planet.finale and root.sim.planet.completed and root.sim.mission.outcome=="victory"):
  _finale_seconds=0.0;return
 if root.paused or _finale_left:return
 _finale_seconds+=seconds
 if _finale_seconds<Direction.finale_return:return
 _finale_left=true
 root.return_to_title()

func close() -> void:
 map.hide();root.paused=_was_paused;root.controls.release_all();root.hud.cancel_touch_gestures()
func _depart(id: int) -> void:
 var body: Dictionary={"x":root.knight.position.x,"y":root.knight.position.y,"vx":0.0,"vy":0.0}
 var prepared: Dictionary=root.journey.prepare(root.sim,body,id)
 if prepared.is_empty():map.show_error();return
 if root.progress!=null and not root.progress.save(prepared.session,prepared.config,prepared.body,prepared.journey):
  map.show_error();return
 map.hide();root._apply_restored(prepared);root.paused=false
 root._arrival_banner.show_arrival(id)

func open_chart(read_only: bool=true) -> void:
 if root.journey==null:return
 liberation.hide()
 _was_paused=root.paused
 root.paused=true;root.controls.release_all();root.hud.cancel_touch_gestures()
 root.hud.options_menu.hide()
 map.present(root.journey,root.sim,read_only)
