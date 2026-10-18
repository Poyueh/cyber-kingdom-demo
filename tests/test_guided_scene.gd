extends "res://tests/test_scene.gd"
func run_scene() -> void:
 var scene: Node=load("res://scenes/frontier.tscn").instantiate()
 scene._guided_campaign=true;scene.campaign_save_path="";scene.audio_preferences_path=""
 root.add_child(scene)
 await frames(15)
 check(scene.sim.core_loop.enabled and not scene.sim.core_loop.trial,"main scene starts guided campaign")
 check(scene.journey!=null and scene.journey.configs.size()==7,"main scene owns seven-world progress")
 check(scene.hud.core_hud.wallet.visible,"shared guidance HUD is visible in main game")
 scene.knight.position.x=scene.sim.world.sites.hall
 await frames(3)
 var action: Button=scene.hud.core_hud.action_button
 var click: InputEventMouseButton=InputEventMouseButton.new()
 click.position=action.get_global_rect().get_center();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true
 root.push_input(click,true);await frames(2)
 click=click.duplicate();click.pressed=false;root.push_input(click,true);await frames(180)
 check(scene.sim.frontier.city_level==1,"main-game guidance action actually founds camp")
 check(scene.sim.modules.relics.size()>0,"main scene still contains forest discoveries")
 scene.sim.core_loop.income=1;scene.sim.core_loop.observe(scene.sim)
 scene._core_controller.observe()
 var money: int=scene.sim.pouch.amount
 scene.sim.pouch.amount=0
 check(scene._core_controller.retry(),"main-game preparation retry restores successfully")
 check(scene.sim.pouch.amount==money and scene.journey!=null and scene.journey.configs.size()==7,"retry retains funds and seven-world envelope")
 scene.queue_free();await frames(3)
 print("Guided scene assertions: %d; failures: %d"%[assertions,failures]);quit(1 if failures else 0)
