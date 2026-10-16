extends "res://tests/test_scene.gd"
const MerchantView=preload("res://presentation/crystal_merchant_view.gd")
func run_scene()->void:
 var game:Node=load("res://scenes/frontier.tscn").instantiate()
 game.campaign_save_path="";game.audio_preferences_path=""
 root.add_child(game);await frames(8)
 game.set_physics_process(false);game.knight.set_physics_process(false)
 game.sim.world.people.clear();game.sim.spirit.opening_finished=true;game.sim.spirit.expires_tick=0
 game.hud.hide();game.knight.position=Vector2(-3000,430)
 var cam:Camera2D=game.knight.get_node("Camera2D")
 cam.zoom=Vector2(2,2);cam.position=Vector2(0,-45);cam.reset_smoothing();cam.force_update_scroll()
 for region:Dictionary in game.sim.frontier.regions:region.discovered=true
 game.sim.merchant.phase=game.sim.merchant.Phase.APPROACHING
 game.sim.merchant.x=-3045;game.sim.pouch.amount=0
 DirAccess.make_dir_recursive_absolute("/tmp/cyber52-merchant")
 for i:int in range(120):
  game.sim.advance(1.0/30,-3000,430)
  if i==35:
   check(game.sim.merchant.moving,"merchant is still walking after gift")
   check(game.sim.interact(game.sim.merchant.x,"merchant"),"dispatch succeeds while trader walks back")
   check(MerchantView.opacity(game.sim.merchant,-3000)>0.99,"remote dispatch does not erase the merchant")
  if i>35 and i<60:check(game.sim.merchant.visible() and MerchantView.opacity(game.sim.merchant,-3000)>0.99,"departing merchant remains fully visible")
  game.view.present(game.sim,-3000)
  await process_frame;RenderingServer.force_draw()
  root.get_texture().get_image().save_png("/tmp/cyber52-merchant/frame-%03d.png"%i)
 game.queue_free();await frames(2)
 print("Merchant scene: %d checks, %d failures"%[assertions,failures]);quit(1 if failures else 0)
