extends RefCounted
const Campaign=preload("res://application/campaign_session.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
func test_module_balance_and_switching_share_cooldown(t) -> void:
 var sim=Campaign.new({"seed":42,"immersive_loop":1,"module_arc_cost":7.0,"module_arc_damage":9})
 sim.interact(30,"hall")
 sim.modules.found.assign(["arc","lance"]);sim.modules.stored.assign(["arc","lance"])
 sim.pouch.amount=12
 t.truth(sim.equip_module("arc",sim.world.sites.drill),"first paid installation succeeds")
 var enemy: Dictionary=sim._spawn_raider();enemy.x=550;sim.raiders.append(enemy)
 var before: int=enemy.fighter.hp
 sim.hero.stamina=20
 t.truth(sim.activate_module(500),"custom balanced module activates")
 t.equal(sim.hero.stamina,13.0,"module stamina cost comes from run configuration")
 t.equal(enemy.fighter.hp,before-9,"module damage comes from run configuration")
 sim.pouch.amount=12
 t.truth(sim.equip_module("lance",sim.world.sites.drill),"paid switch during cooldown succeeds")
 sim.hero.stamina=100
 t.truth(not sim.activate_module(500),"switching modules cannot bypass shared cooldown")
 sim.modules.ready_tick=0;sim.hero.stamina=0
 t.truth(not sim.activate_module(500),"empty stamina rejects the special action")
func test_relics_auto_equip_and_preserve_saved_cooldown(t) -> void:
 var config: Dictionary={"seed":42,"immersive_loop":1}
 var sim=Campaign.new(config)
 if not sim.has_method("equip_module"):
  t.truth(false,"campaign supports equipping discovered special modules");return
 sim.interact(30,"hall")
 var relic=sim.modules.relics[0]
 t.truth(not sim.equip_module(relic.id,sim.world.sites.drill),"unknown module cannot be equipped")
 sim.advance(0.1,relic.x)
 t.truth(sim.modules.found.has(relic.id),"exploring the relic physically collects it")
 t.truth(not sim.equip_module(relic.id,relic.x),"carried module cannot be installed in the wild")
 sim.advance(0.1,sim.world.sites.drill)
 t.truth(sim.modules.stored.has(relic.id),"collected module remains available at the workshop")
 t.equal(sim.modules.equipped,relic.id,"pickup automatically equips the discovered module")
 t.truth(not sim.equip_module(relic.id,sim.world.sites.drill),"already equipped module cannot be charged again")
 var enemy: Dictionary=sim._spawn_raider();enemy.x=sim.world.sites.drill+50
 sim.raiders.append(enemy)
 var hp: int=enemy.fighter.hp
 t.truth(sim.activate_module(sim.world.sites.drill),"equipped special module activates")
 t.truth(enemy.fighter.hp<hp,"special action damages an actual enemy")
 var stamina: float=sim.hero.stamina
 t.truth(not sim.activate_module(sim.world.sites.drill),"cooldown rejects repeated activation")
 t.equal(sim.hero.stamina,stamina,"rejected activation never charges stamina twice")
 var codec=Codec.new();var body: Dictionary={"x":sim.world.sites.drill,"y":430.0,"vx":0.0,"vy":0.0}
 var saved: Dictionary=codec.capture(sim,config,body)
 var copy: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(saved)))
 t.truth(not copy.is_empty(),"module inventory and cooldown survive a save")
 if copy.is_empty():return
 for i in range(30):
  sim.advance(1.0/30,body.x);copy.session.advance(1.0/30,body.x)
 t.truth(preload("res://application/campaign_checkpoint_rules.gd").same(codec.capture(sim,config,body),codec.capture(copy.session,config,body)),"module run continues identically after loading")
 var old: Dictionary=saved.duplicate(true);old.version=9;old.erase("modules")
 t.truth(not codec.restore(old).is_empty(),"version nine upgrades with unexplored modules")
 saved.modules.equipped="unknown"
 t.truth(codec.restore(saved).is_empty(),"unknown equipped module is rejected")

func test_seeded_modules_and_directional_lance(t) -> void:
 var a=Campaign.new({"seed":42,"immersive_loop":1})
 if not a.has_method("activate_module"):
  t.truth(false,"campaign has a special module action");return
 var b=Campaign.new({"seed":42,"immersive_loop":1})
 t.equal(a.modules.relics[0].x,b.modules.relics[0].x,"same seed finds the same first relic")
 t.equal(a.modules.relics[1].x,b.modules.relics[1].x,"same seed finds the same second relic")
 a.interact(30,"hall")
 var relic=a.modules.relics[1]
 a.advance(0.1,relic.x);a.advance(0.1,a.world.sites.drill)
 a.equip_module(relic.id,a.world.sites.drill)
 var front: Dictionary=a._spawn_raider();front.x=600
 var back: Dictionary=a._spawn_raider();back.x=400
 a.raiders.append(front);a.raiders.append(back)
 var initial: int=back.fighter.hp
 a.hero.facing=1;a.activate_module(500)
 t.truth(front.fighter.hp<initial and back.fighter.hp==initial,"lance only strikes the faced direction")
