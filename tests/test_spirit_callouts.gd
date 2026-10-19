extends RefCounted
## After the guided opening the ghost keeps calling the current goal:
## build, gather crystals, survive the night raid, seal the gates (then the dragon).
func after_guidance(stage: int=5) -> RefCounted:
	var sim: RefCounted=load("res://tests/test_resident_revert.gd").new().guided()
	sim.frontier.city_level=1
	sim.core_loop.income=6;sim.core_loop.stage=stage;sim.core_loop.checkpoint_index=2;sim.core_loop.checkpoint_pending=0
	sim.clock.is_night=false;sim.clock.remaining=sim.clock.day_seconds-30.0
	sim.raiders.clear()
	return sim

func callout(sim: RefCounted) -> String:
	return str(sim.spirit.advice(sim,sim.world.sites.hall).get("goal",""))

func test_the_ghost_calls_the_goal_of_the_moment(t):
	var sim: RefCounted=after_guidance()
	sim.pouch.amount=10
	t.equal(callout(sim),"spirit.call.seal","with crystals for a gate and gates still open: seal the gates")
	sim.pouch.amount=1
	t.equal(callout(sim),"spirit.call.gather","short of crystals: gather crystals")
	sim.pouch.amount=10
	for rift: Dictionary in sim.mission.rifts:rift.sealed=true
	t.equal(callout(sim),"spirit.call.build","every gate sealed and crystals at hand: build")
	sim.mission.dragon_summoned=true
	t.equal(callout(sim),"spirit.call.dragon","the dragon has come: defeat it")
	sim.clock.is_night=true
	t.equal(callout(sim),"spirit.call.survive","at night: survive the raid")

func test_callouts_start_once_the_first_night_message_has_been_said(t):
	var sim: RefCounted=after_guidance(3)
	sim.clock.remaining=sim.clock.day_seconds-2.0
	t.equal(str(sim.spirit.advice(sim,sim.world.sites.hall).get("kind","")),"rest","the morning after the first night still hands over preparation")
	sim.clock.remaining=sim.clock.day_seconds-30.0
	t.truth(callout(sim).begins_with("spirit.call."),"later that day the ghost calls the goal")
	sim.core_loop.skipped=true
	t.truth(sim.spirit.advice(sim,sim.world.sites.hall).is_empty(),"a player who hid the guide hears nothing")

func test_the_call_repeats_while_the_goal_stands(t):
	var view: Node2D=load("res://presentation/campaign_guide_view.gd").new()
	view._ready()
	var hint: Dictionary={"kind":"call_build","x":300.0,"y":430.0,"key":"","action":"wait","stage":0,"core":true,"mood":"cheer","lesson":"spirit.call.build","goal":"spirit.call.build"}
	var heard: Array[float]=[]
	var was: bool=false
	var time: float=0.0
	var x: float=300.0
	while time<45.0:
		# The knight keeps walking; the calling ghost travels with them.
		x+=3.0;hint.x=x
		view.present(hint,Rect2(0,0,960,540),x,Rect2(),false)
		view.track(Vector2(480,420),time)
		var now: bool=view._guide_label.visible
		if now and not was:heard.append(time)
		was=now;time+=1.0/30.0
	t.truth(heard.size()>=3,"the goal is called again and again while the knight walks (%d calls in 45 s)"%heard.size())
	t.truth(not heard.is_empty() and heard[0]<0.5,"the first call comes at once")
	t.equal(view._guide_label.text,view.tr("spirit.call.build"),"the call is the goal itself")
	view.free()
