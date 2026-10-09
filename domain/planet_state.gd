extends RefCounted
## Per-world expedition state. Persisted by the bounded voyage envelope.
var enabled: bool=false
var id: int=0
var cleared: bool=false
var core_claimed: bool=false
var reactor: bool=false
var wrecked: bool=false
var rocket_pending: bool=false
var rocket_ready: bool=false
var work: float=0.0
var work_required: float=30.0
var build_cost: int=20
var repair_cost: int=12
var launch_requested: bool=false
var completed: bool=false
var volley: int=0
func _init(config: Dictionary={}) -> void:
 enabled=int(config.get("voyage_enabled",0))==1
 id=int(config.get("planet_id",0))
 work_required=float(config.get("rocket_work",30.0))
 build_cost=int(config.get("rocket_cost",20));repair_cost=int(config.get("rocket_repair",12))
func claim_core() -> bool:
 if not enabled or not cleared or core_claimed:return false
 core_claimed=true;reactor=true
 return true
func cost() -> int:return repair_cost if wrecked else build_cost
func work_on(seconds: float) -> void:
 if not rocket_pending or seconds<=0:return
 work=minf(work_required,work+seconds)
 if work>=work_required:rocket_pending=false;rocket_ready=true
func capture() -> Dictionary:
 return {"cleared":cleared,"core_claimed":core_claimed,"reactor":reactor,"wrecked":wrecked,"rocket_pending":rocket_pending,"rocket_ready":rocket_ready,"work":work,"completed":completed,"volley":volley}
func restore(data: Variant) -> bool:
 if not data is Dictionary or data.size()!=9:return false
 for key: String in ["cleared","core_claimed","reactor","wrecked","rocket_pending","rocket_ready","completed"]:
  if not data.get(key) is bool:return false
 if not (data.get("work") is int or data.get("work") is float) or not is_finite(float(data.work)) or data.work<0 or data.work>work_required:return false
 if data.get("volley") not in [0,1]:return false
 if data.core_claimed and not data.cleared:return false
 if data.rocket_pending and data.rocket_ready:return false
 if (data.rocket_pending or data.rocket_ready or data.core_claimed) and not data.reactor:return false
 for key: String in data:set(key,data[key])
 return true
