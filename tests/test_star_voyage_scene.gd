extends "res://tests/test_scene.gd"
const Voyage=preload("res://application/star_voyage.gd")
func capture(game: Node, name: String) -> void:
 game.view.present(game.sim,game.knight.position.x)
 game.hud.present_world(game.sim,game.paused,game.knight.position.x,true)
 await frames(4)
 game._water.present(game.sim);game._sunbeams.present(game.sim);game._lantern.present(game.sim,game.knight)
 if game._star_travel.active():game.hud.options_menu.hide()
 await frames(2)
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute("res://test-results/three-planets")
 game.get_viewport().get_texture().get_image().save_png("res://test-results/three-planets/"+name+".png")
func run_scene() -> void:
 var game: Node=load("res://scenes/frontier.tscn").instantiate()
 game.campaign_save_path="";game.audio_preferences_path=""
 root.add_child(game);await frames(10);game.set_physics_process(false)
 game.sim.clock.remaining=game.sim.clock.day_seconds*0.65
 game.knight.position=Vector2(30,430);game.paused=false
 check(game.journey!=null and game.journey.configs.size()==3,"real scene creates three planet definitions")
 await capture(game,"forest")
 for rift: Dictionary in game.sim.mission.rifts:rift.sealed=true
 game.sim.mission.dragon_summoned=true;game.sim.mission.dragon_defeated=true;game.sim.mission.dragon_day=6
 game.sim.frontier.city_level=1;game.sim.survival.armed=true;game.sim.advance(0.1,30)
 check(game.sim.is_running(),"first dragon opens expedition rather than ending game")
 game.sim.planet.claim_core();game.sim.planet.rocket_ready=true;game.knight.position.x=-730
 game.sim.planet.launch_requested=true;game._star_travel.observe()
 check(game._star_travel.active(),"completed rocket opens real star chart")
 await capture(game,"star-chart")
 game._star_travel.map._buttons[1].pressed.emit();await frames(3)
 check(game.journey.current==1 and game.sim.planet.wrecked,"star chart button switches to desert wreck")
 game._arrival_banner.hide();game.sim.clock.remaining=game.sim.clock.day_seconds*0.65
 await capture(game,"desert")
 # The actual native game displays the distinct sand dragon art and telegraph.
 for rift: Dictionary in game.sim.mission.rifts:rift.sealed=true
 game.sim._summon_dragon(game.knight.position.x)
 var sand: Dictionary=game.sim.raiders[0];sand.x=game.knight.position.x+250;sand.direction=-1.0;sand.windup=1.4;sand.target={"kind":"hero","x":game.knight.position.x}
 await capture(game,"sand-dragon")
 game.sim.raiders.clear();game.sim.mission.dragon_defeated=true;game.sim.advance(0.1,game.knight.position.x);game.sim.planet.claim_core();game.sim.planet.rocket_ready=true
 game.knight.position.x=-730;game.sim.planet.launch_requested=true;game._star_travel.observe();game._star_travel.map._buttons[2].pressed.emit();await frames(3)
 check(game.journey.current==2,"second departure reaches third world")
 game._arrival_banner.hide();game.sim.clock.remaining=game.sim.clock.day_seconds*0.65
 await capture(game,"frost")
 for rift: Dictionary in game.sim.mission.rifts:rift.sealed=true
 game.sim._summon_dragon(game.knight.position.x)
 var ice: Dictionary=game.sim.raiders[0];ice.x=game.knight.position.x+250;ice.direction=-1.0;ice.windup=1.4;ice.target={"kind":"hero","x":game.knight.position.x}
 await capture(game,"frost-dragon")
 game.sim.raiders.clear();game.sim.mission.dragon_defeated=true;game.sim.advance(0.1,game.knight.position.x);game.sim.planet.claim_core();game.journey.observe(game.sim)
 check(game.sim.mission.outcome=="victory","third claimed dragon core completes the expedition")
 var packet: Dictionary=game.journey.capture(game.sim,{"x":game.knight.position.x,"y":430.0,"vx":0.0,"vy":0.0})
 check(not Voyage.restore(packet).is_empty(),"completed three-world save restores through real scene state")
 # Real audio mixing finishes on its own callback, after SceneTree teardown.
 game.audio.enabled=false;game.audio.stop()
 await create_timer(0.25).timeout
 game.queue_free();await frames(2)
 print("Three-planet scene assertions: %d; failures: %d"%[assertions,failures]);quit(1 if failures else 0)
