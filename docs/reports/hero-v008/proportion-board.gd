extends SceneTree
var output: String = "/tmp/cyber50-proportions.png"
class Board extends Node2D:
	var appearance: Resource
	var textures: Array[Texture2D] = []
	func _draw() -> void:
		draw_rect(Rect2(0,0,1536,440),Color("101d25"))
		var names: Array[StringName] = [&"idle", &"run", &"sprint"]
		for i: int in range(3):
			var texture: Texture2D = textures[i]
			draw_texture_rect(texture,Rect2(i*512,40,512,384),false)
			draw_line(Vector2(i*512+80,364),Vector2(i*512+432,364),Color("547b79"),1)
func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output=arg.trim_prefix("--output=")
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1536,440)
	var board: Board=Board.new()
	board.appearance=load("res://data/hero_v005_appearance.tres")
	for i: int in range(3):
		var texture: Texture2D=board.appearance.frames.get_frame_texture([&"idle",&"run",&"sprint"][i],0 if i==0 else 2)
		board.textures.append(texture)
	board.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var viewport: SubViewport=SubViewport.new()
	viewport.size=Vector2i(1536,440)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	viewport.add_child(board)
	for i: int in range(3):
		var label: Label=Label.new();label.text=["IDLE / SAME NATIVE SCALE","WALK / SAME NATIVE SCALE","SPRINT / SAME NATIVE SCALE"][i]
		label.position=Vector2(i*512+100,12);label.add_theme_font_size_override("font_size",18);board.add_child(label)
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	viewport.get_texture().get_image().save_png(output)
	quit()
