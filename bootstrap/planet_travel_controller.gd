extends Node
## Save-before-switch transaction and modal lifetime live at the composition edge.
const Map=preload("res://presentation/star_map.gd")
var root: Node
var map: Map
var _observed: int=0
var _cleared_seen: bool=false
var _was_paused: bool=false
func _ready() -> void:
 map=Map.new();add_child(map)
 map.destination_selected.connect(_depart)
 map.closed.connect(close)
func active() -> bool:return map!=null and map.visible
func observe() -> void:
 if root.journey==null:return
 root.journey.observe(root.sim)
 if _observed!=root.sim.get_instance_id():
  _observed=root.sim.get_instance_id();_cleared_seen=root.sim.planet.cleared
 elif root.sim.planet.cleared and not _cleared_seen:
  _cleared_seen=true
  if not root.sim.planet.core_claimed:root._arrival_banner.show_notice(tr("planet.dragon_down"),tr("planet.claim_info"))
 if not root.sim.planet.launch_requested:return
 root.sim.planet.launch_requested=false
 if root.sim.raiders.is_empty() and root.sim.planet.rocket_ready:
  open_chart(false)
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
 _was_paused=root.paused
 root.paused=true;root.controls.release_all();root.hud.cancel_touch_gestures()
 root.hud.options_menu.hide()
 map.present(root.journey,root.sim,read_only)
