extends RefCounted
const Campaign = preload("res://application/campaign_session.gd")
const Progress = preload("res://application/settlement_progress.gd")
const Codec = preload("res://application/campaign_snapshot.gd")

func test_paid_camp_upgrade_explains_actual_new_facility(t: SceneTree) -> void:
	var tuning: Resource = load("res://data/campaign.tres")
	var config: Dictionary = tuning.campaign_rules()
	config.merge({"seed":108,"economy":tuning.economy_rules()},true)
	var sim: RefCounted = Campaign.new(config)
	sim.interact(sim.world.sites.hall)
	sim.pouch.amount = 30
	var purchase: Dictionary = sim.context(sim.world.sites.hall)
	for i: int in range(purchase.cost - 1):
		sim.interact(sim.world.sites.hall)
	t.equal(Progress.read(sim).get("level"), 1, "partial investment must not announce the farm workshop")
	sim.interact(sim.world.sites.hall)
	var progress: Dictionary = Progress.read(sim)
	t.equal(progress.get("level"), 2, "full payment records the settlement stage")
	var stages: Array = progress.get("stages", [])
	t.truth(stages.size() == 3 and stages[1].get("unlocks") == ["farm_tools"], "second stage leads to the actual farm-tool facility")
	t.equal(sim.world.tools.hoe, 0, "celebrating unlock does not manufacture free tools")
	purchase = sim.context(sim.world.sites.hall)
	for i: int in range(purchase.cost):sim.interact(sim.world.sites.hall)
	var codec: RefCounted = Codec.new()
	var body: Dictionary = {"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}
	var before: String = JSON.stringify(codec.capture(sim,config,body))
	progress = Progress.read(sim)
	t.equal(progress.stages[2].unlocks,["armory"],"third stage names the spear-kit facility")
	t.equal(sim.world.tools.blade,0,"upgrade review cannot grant free spear kits")
	t.truth(progress.stages.all(func(stage: Dictionary) -> bool:return stage.complete),"all built camp stages remain visible for review")
	t.equal(JSON.stringify(codec.capture(sim,config,body)),before,"reading milestones leaves the entire saved simulation unchanged")
	var restored: Dictionary = codec.restore(JSON.parse_string(before))
	t.truth(not restored.is_empty(),"existing schema can restore a fully upgraded settlement")
	if not restored.is_empty():t.equal(Progress.read(restored.session),progress,"loaded settlement has identical milestone information")
	var fresh: RefCounted = Campaign.new(config)
	t.truth(Progress.read(fresh).stages.all(func(stage: Dictionary) -> bool:return not stage.complete),"another world cannot inherit the old camp's milestones")
	fresh.life.enabled=false
	t.equal(Progress.read(fresh).stages,[],"legacy standalone economy gets no misleading new unlock list")
