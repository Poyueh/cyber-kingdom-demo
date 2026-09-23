extends "res://tests/test_scene.gd"
const Catalog=preload("res://infrastructure/campaign_catalog.gd")
func use_catalog(menu, folder: String) -> void:
 menu.catalog=Catalog.new(folder,"")
# Scene replacement is deferred to idle; physics ticks alone can observe null.
func scene_frames(count: int) -> void:
 await frames(count)
 await process_frame;await process_frame
func run_scene() -> void:
 ProjectSettings.set_setting("campaign/persistence_enabled",true)
 var folder="user://test_start_menu_%d"%Time.get_ticks_usec()
 var menu=load("res://scenes/start_menu.tscn").instantiate()
 menu.campaigns_directory=folder;menu.legacy_path=""
 root.add_child(menu);current_scene=menu
 await scene_frames(3)
 check(menu.catalog.entries().is_empty(),"opening title does not create or overwrite a journey")
 menu.view.new_button.pressed.emit()
 await scene_frames(15)
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
 game.return_to_title();await scene_frames(3)
 check(current_scene==game and game.progress.status=="error","failed save keeps player in the campaign to retry")
 DirAccess.remove_absolute(first+".tmp")
 game.return_to_title();await scene_frames(5)
 menu=current_scene
 check(menu.name=="StartMenu","pause menu returns to title after successful save")
 use_catalog(menu,folder);menu.show_records()
 check(menu.rows.size()==2,"record picker shows automatic and manual choices")
 var automatic: int=0 if not menu.rows[0].manual else 1
 var manual: int=1-automatic
 check(menu.rows[automatic].crystals==5 and menu.rows[manual].crystals==6,"picker previews distinct automatic and manual records")
 menu.select_record(manual);await scene_frames(15)
 game=current_scene;game.set_physics_process(false)
 check(game.campaign_save_path!=first and game.sim.frontier.city_level==1 and game.sim.pouch.amount==6,"manual choice forks a playable journey at the checkpoint")
 check(FileAccess.get_file_as_string(first)==latest,"manual fork preserves newer automatic progress")
 game.return_to_title();await scene_frames(5)
 menu=current_scene;use_catalog(menu,folder)
 menu.start_new_game();await scene_frames(15)
 game=current_scene;game.set_physics_process(false)
 check(game.sim.frontier.city_level==0 and game.sim.pouch.amount==6,"another new game begins fresh")
 check(FileAccess.get_file_as_string(first)==latest,"another new game keeps the first journey intact")
 game.return_to_title();await scene_frames(5)
 menu=current_scene;use_catalog(menu,folder);menu.show_records()
 var index: int=-1
 for i in range(menu.rows.size()):
  if menu.rows[i].path==first:index=i
 var file=FileAccess.open(first,FileAccess.WRITE);file.store_string("damaged after listing");file.close()
 menu.select_record(index);await scene_frames(3)
 check(current_scene==menu,"record changed after listing is revalidated before launching")
 check(FileAccess.get_file_as_string(first)=="damaged after listing","failed selection preserves original bytes")
 menu.queue_free();await process_frame
 await _check_title_audio(folder)
 for name in DirAccess.get_files_at(folder):DirAccess.remove_absolute(folder.path_join(name))
 DirAccess.remove_absolute(folder)
 print("Start menu assertions: %d; failures: %d"%[assertions,failures])
 quit(0 if failures==0 else 1)

## The title theme is a whole generated track; a silent start page wastes it.
func _check_title_audio(folder: String) -> void:
 var settings=folder.path_join("audio.cfg")
 var file=FileAccess.open(settings,FileAccess.WRITE)
 file.store_string("[audio]\nmusic=0.5\neffects=0.8\nambience=0.6\nmuted=false\n");file.close()
 var menu=load("res://scenes/start_menu.tscn").instantiate()
 menu.campaigns_directory=folder;menu.legacy_path="";menu.audio_preferences_path=settings
 root.add_child(menu);current_scene=menu
 await scene_frames(8)
 check(menu.has_node("TitleAudio"),"the start page carries its own audio")
 if not menu.has_node("TitleAudio"):menu.queue_free();return
 var title=menu.get_node("TitleAudio")
 check(title.music.current=="title","the start page runs the title theme")
 check(is_equal_approx(title.music.volume,0.5),"the saved music level is honoured on the title screen")
 var heard: Array[String]=[]
 title.cue_requested.connect(func(kind):heard.append(kind))
 title.click("ui_confirm")
 check(heard==["ui_confirm"],"a menu press is heard once")
 menu.queue_free();await process_frame
 var muted=FileAccess.open(settings,FileAccess.WRITE)
 muted.store_string("[audio]\nmusic=0.5\neffects=0.8\nambience=0.6\nmuted=true\n");muted.close()
 var quiet=load("res://scenes/start_menu.tscn").instantiate()
 quiet.campaigns_directory=folder;quiet.legacy_path="";quiet.audio_preferences_path=settings
 root.add_child(quiet);current_scene=quiet
 await scene_frames(8)
 var silent=quiet.get_node("TitleAudio")
 check(not silent.enabled,"a muted player is not greeted with music")
 check(silent.music.current.is_empty(),"a muted title screen runs no track")
 quiet.queue_free();await process_frame
