extends RefCounted
func test_controls_and_information_fit_notched_landscape_and_tablet(t):
	var path="res://presentation/campaign_layout.gd"
	t.truth(ResourceLoader.exists(path),"campaign needs a safe-area-aware layout")
	if not ResourceLoader.exists(path):return
	var layout=load(path)
	for safe in [Rect2(0,0,960,540),Rect2(90,18,840,490),Rect2(30,18,840,490),Rect2(0,0,960,720),Rect2(40,8,760,420)]:
		var result=layout.arrange(safe)
		var rectangles: Array=[]
		for rect in result.buttons.values():rectangles.append(rect)
		for key in result.panels:
			if key!="overlay":rectangles.append(result.panels[key])
		var inside=true
		for rect in rectangles:inside=inside and safe.encloses(rect)
		t.truth(inside,"all controls, costs and status stay inside safe display")
		var clear=true
		for i in range(rectangles.size()):
			for j in range(i+1,rectangles.size()):
				clear=clear and not rectangles[i].intersects(rectangles[j])
		t.truth(clear,"controls and information never cover each other")
		t.truth(result.buttons.move_left.size.x>=64 and result.buttons.attack.size.x>=64,"primary thumb targets retain usable size")

func test_safe_area_conversion_handles_scaling_and_letterboxing(t):
	var path="res://presentation/campaign_layout.gd"
	if not ResourceLoader.exists(path):t.truth(false,"missing safe-area conversion");return
	var layout=load(path)
	var viewport=Rect2(0,0,960,540)
	var to_screen=Transform2D(Vector2(2,0),Vector2(0,2),Vector2(100,0))
	var safe=layout.screen_to_canvas(viewport,to_screen,Rect2(160,20,1800,1000))
	t.equal(safe,Rect2(30,10,900,500),"safe physical pixels convert into local HUD coordinates")
	t.equal(layout.screen_to_canvas(viewport,to_screen,Rect2()),viewport,"unavailable platform safe area uses full viewport")

func test_corner_menu_and_purse_fit_phone_safe_area(t):
	var layout=preload("res://presentation/campaign_layout.gd")
	var purse=preload("res://presentation/crystal_purse_view.gd").new()
	for safe in [Rect2(0,0,960,540),Rect2(90,18,840,490),Rect2(40,8,760,420)]:
		var result=layout.arrange(safe,true)
		purse.present(0.5,safe,false)
		var rectangles: Array=[purse.bounds,Rect2(safe.position+Vector2(16,90),Vector2(370,258))]
		for key in ["pause","fullscreen","save","refuge","restart","new_map","audio"]:
			rectangles.append(result.buttons[key])
		var clear=true
		for i in range(rectangles.size()):
			clear=clear and safe.encloses(rectangles[i])
			for j in range(i+1,rectangles.size()):
				clear=clear and not rectangles[i].intersects(rectangles[j])
		t.truth(clear,"corner menu, options and purse fit without overlap on phones")
	purse.free()
