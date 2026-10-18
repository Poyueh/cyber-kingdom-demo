extends RefCounted
## Snapshot boundary supplied by the caller avoids a session/codec dependency cycle.
static func capture_pending(sim: RefCounted, config: Dictionary, body: Dictionary, codec: RefCounted) -> bool:
 var core: RefCounted=sim.core_loop
 if not core.enabled or core.checkpoint_pending==0:return false
 var previous: Dictionary=core.capture()
 core.checkpoint_index=core.checkpoint_pending;core.checkpoint_pending=0;core.checkpoint={}
 var packet: Dictionary=codec.capture(sim,config,body)
 if codec.restore(packet,true).is_empty():
  core.restore(previous)
  return false
 core.checkpoint=packet
 return true
static func retry(sim: RefCounted, codec: RefCounted) -> Dictionary:
 if not sim.core_loop.enabled or sim.core_loop.checkpoint.is_empty():return {}
 var packet: Dictionary=sim.core_loop.checkpoint.duplicate(true)
 var restored: Dictionary=codec.restore(packet,true)
 if restored.is_empty():return {}
 restored.session.core_loop.checkpoint=packet
 return restored
