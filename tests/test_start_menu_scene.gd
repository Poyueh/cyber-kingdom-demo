extends "res://tests/test_scene.gd"
const Catalog=preload("res://infrastructure/campaign_catalog.gd")
func use_catalog(menu, folder: String) -> void:
 menu.catalog=Catalog.new(folder,"")
func run_scene() -> void:
 ProjectSettings.set_setting("campaign/persistence_enabled",true)
 var folder="user://test_start_menu_%d"%Time.get_ticks_usec()
 var menu=load("res://scenes/start_menu.tscn").instantiate()
 menu.campaigns_directory=folder;menu.legacy_path=""
 root.add_child(menu);current_scene=menu
 await frames(3)
 check(menu.catalog.entries().is_empty(),"opening title does not create or overwrite a journey")
 menu.view.new_button.pressed.emit()
 await frames(15)
 var game=current_scene
 check(game.name=="Frontier","new game launches actual campaign")
 if game.name!="Frontier":quit(1);return
 game.set_physics_process(false)
 var first: String=game.campaign_save_path
 check(first.begins_with(folder) and FileAccess.file_exists(first),"new game autosaves to an independent path")
 game.sim.interact(30) # New journeys ignite freely by drawing the sword.
 check(game.save_manual_campaign(),"first journey records manual checkpoint")
 game.sim.pouch.spend()
 check(game.save_campaign(),"newer automatic progress is saved separately")
 var latest=FileAccess.get_file_as_string(first)
 DirAccess.make_dir_absolute(first+".tmp")
 game.return_to_title();await frames(3)
 check(current_scene==game and game.progress.status=="error","failed save keeps player in the campaign to retry")
 DirAccess.remove_absolute(first+".tmp")
 game.return_to_title();await frames(5)
 menu=current_scene
 check(menu.name=="StartMenu","pause menu returns to title after successful save")
 use_catalog(menu,folder);menu.show_records()
 check(menu.rows.size()==2,"record picker shows automatic and manual choices")
 var automatic: int=0 if not menu.rows[0].manual else 1
 var manual: int=1-automatic
 check(menu.rows[automatic].crystals==11 and menu.rows[manual].crystals==12,"picker previews distinct automatic and manual records")
 menu.select_record(manual);await frames(15)
 game=current_scene;game.set_physics_process(false)
 check(game.campaign_save_path!=first and game.sim.frontier.city_level==1 and game.sim.pouch.amount==12,"manual choice forks a playable journey at the checkpoint")
 check(FileAccess.get_file_as_string(first)==latest,"manual fork preserves newer automatic progress")
 game.return_to_title();await frames(5)
 menu=current_scene;use_catalog(menu,folder)
 menu.start_new_game();await frames(15)
 game=current_scene;game.set_physics_process(false)
 check(game.sim.frontier.city_level==0 and game.sim.pouch.amount==12,"another new game begins fresh")
 check(FileAccess.get_file_as_string(first)==latest,"another new game keeps the first journey intact")
 game.return_to_title();await frames(5)
 menu=current_scene;use_catalog(menu,folder);menu.show_records()
 var index: int=-1
 for i in range(menu.rows.size()):
  if menu.rows[i].path==first:index=i
 var file=FileAccess.open(first,FileAccess.WRITE);file.store_string("damaged after listing");file.close()
 menu.select_record(index);await frames(3)
 check(current_scene==menu,"record changed after listing is revalidated before launching")
 check(FileAccess.get_file_as_string(first)=="damaged after listing","failed selection preserves original bytes")
 menu.queue_free();await process_frame
 for name in DirAccess.get_files_at(folder):DirAccess.remove_absolute(folder.path_join(name))
 DirAccess.remove_absolute(folder)
 print("Start menu assertions: %d; failures: %d"%[assertions,failures])
 quit(0 if failures==0 else 1)
