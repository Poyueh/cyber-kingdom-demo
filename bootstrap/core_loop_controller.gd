extends Node
const Points=preload("res://application/core_checkpoints.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
var root: Node
var codec: RefCounted=Codec.new()
func _ready() -> void:
 var hud: Control=root.hud.core_hud
 hud.interaction_requested.connect(func()->void:root._requested_interaction=true)
 hud.orders_toggled.connect(func(open: bool)->void:
  root.paused=open;root.controls.release_all();root.hud.cancel_touch_gestures())
 hud.order_requested.connect(func(target: String, amount: int)->void:
  if root.sim.core_loop.enabled:root.sim.core_loop.orders.assign(root.sim,target,amount))
 hud.guidance_toggled.connect(func()->void:root.sim.core_loop.skipped=not root.sim.core_loop.skipped)
 hud.retry_requested.connect(func()->void:
  if root.sim.core_loop.checkpoint_index>0:retry()
  else:root.restart())
 hud.title_requested.connect(root.return_to_title)
func observe() -> void:
 if not root.sim.core_loop.enabled:return
 if root.sim.core_loop.checkpoint_pending>0:
  var body: Dictionary={"x":root.knight.position.x,"y":root.knight.position.y,"vx":0.0,"vy":0.0}
  if Points.capture_pending(root.sim,root._campaign_config,body,codec):root.save_campaign()
  else:
   root.paused=true
   push_error("Core preparation checkpoint failed validation: "+codec.last_error)
func retry() -> bool:
 var restored: Dictionary=Points.retry(root.sim,codec)
 if restored.is_empty():return false
 root.audio.stop()
 root._apply_restored(restored)
 root.hud.core_hud.panel.hide()
 root._requested_special=false
 root._save_elapsed=0.0
 root.paused=false
 root.hud.present_world(root.sim,false,root.knight.position.x,true)
 return root.save_campaign()
