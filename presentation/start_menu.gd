extends Control
signal new_game_requested(pace: int)
signal records_requested
signal record_selected(index: int)
const Icons=preload("res://presentation/ui_icons.gd")
const LanguageSelector=preload("res://presentation/language_selector.gd")
var _bindings: Array[Dictionary]=[]
var _rows: Array[Dictionary]=[]
var _error_source: String=""
var new_button: Button
var records_button: Button
var back_button: Button
var _home: VBoxContainer
var _records: VBoxContainer
var _list: VBoxContainer
var _error: Label
var _heading: Label
var pace_picker: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme=Theme.new()
	theme.default_font=preload("res://presentation/localized_font.gd").current()
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var backdrop:=TextureRect.new()
	backdrop.texture=preload("res://art/refuge/v001/skyline.png")
	backdrop.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(backdrop);backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade:=ColorRect.new();shade.color=Color(0.015,0.035,0.07,0.42)
	shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(shade);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin:=MarginContainer.new();add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right"]:margin.add_theme_constant_override("margin_"+side,42)
	for side in ["top","bottom"]:margin.add_theme_constant_override("margin_"+side,26)
	var columns:=HBoxContainer.new();columns.add_theme_constant_override("separation",36);margin.add_child(columns)
	var identity:=VBoxContainer.new();identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	identity.size_flags_vertical=Control.SIZE_SHRINK_CENTER;identity.add_theme_constant_override("separation",16);columns.add_child(identity)
	var emblem:=TextureRect.new();emblem.texture=Icons.get_icon("crystal");emblem.custom_minimum_size=Vector2(46,46)
	emblem.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;emblem.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;identity.add_child(emblem)
	_label(identity,"CYBER\nKINGDOM",48,Color("c9f1e3"))
	_label(identity,"最後的避難所",24,Color("e2c9a0"))
	_label(identity,"帶著龍晶出征，帶著大家回家。",14,Color("b9c8c9"))
	var card:=PanelContainer.new();card.custom_minimum_size.x=380;card.size_flags_vertical=Control.SIZE_EXPAND_FILL;columns.add_child(card)
	var style:=StyleBoxFlat.new();style.bg_color=Color(0.02,0.06,0.08,0.93)
	style.border_color=Color("426c6c");style.set_border_width_all(1);style.set_corner_radius_all(12);style.set_content_margin_all(22)
	card.add_theme_stylebox_override("panel",style)
	var body:=VBoxContainer.new();body.add_theme_constant_override("separation",14);card.add_child(body)
	_heading=_label(body,"旅程",26,Color("d7e4d7"))
	var selector=LanguageSelector.new();body.add_child(selector);selector.owner=self;selector.unique_name_in_owner=true
	_home=VBoxContainer.new();_home.size_flags_vertical=Control.SIZE_EXPAND_FILL;_home.alignment=BoxContainer.ALIGNMENT_CENTER;_home.add_theme_constant_override("separation",18);body.add_child(_home)
	new_button=_button(_home,"新遊戲","camp");new_button.pressed.connect(show_paces)
	records_button=_button(_home,"選擇紀錄","restore");records_button.pressed.connect(func():records_requested.emit())
	_label(_home,"每次新遊戲都另存一段旅程。",14,Color("96acae"))
	if OS.has_feature("web"):
		var guide=_button(_home,"玩家圖文指南","book")
		guide.pressed.connect(preload("res://presentation/web_player_guide.gd").open)
	pace_picker=preload("res://presentation/journey_pace_picker.gd").new()
	pace_picker.name="JourneyPaceChooser"
	body.add_child(pace_picker)
	pace_picker.confirmed.connect(func(pace: int) -> void:new_game_requested.emit(pace))
	pace_picker.cancelled.connect(show_home)
	_records=VBoxContainer.new();_records.size_flags_vertical=Control.SIZE_EXPAND_FILL;_records.add_theme_constant_override("separation",10);body.add_child(_records)
	back_button=_button(_records,"返回","left");back_button.custom_minimum_size.y=48;back_button.pressed.connect(show_home)
	var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;_records.add_child(scroll)
	_list=VBoxContainer.new();_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_list.add_theme_constant_override("separation",10);scroll.add_child(_list)
	_error=_label(body,"",14,Color("ffbd9d"));_error.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	get_node("/root/GameLanguage").changed.connect(_refresh_language)
	show_home()

func _label(parent: Node, text: String, size: int, color: Color) -> Label:
	var label:=Label.new();label.text=tr(text);_bindings.append({"node":label,"source":text});label.add_theme_font_size_override("font_size",size);label.add_theme_color_override("font_color",color);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(label);return label

func _button(parent: Node, text: String, icon: String) -> Button:
	var button:=Button.new();button.text=tr(text);_bindings.append({"node":button,"source":text});button.icon=Icons.get_icon(icon);button.expand_icon=true
	button.custom_minimum_size=Vector2(0,64);button.add_theme_constant_override("icon_max_width",26);button.add_theme_constant_override("h_separation",14)
	button.add_theme_font_size_override("font_size",19)
	var style:=StyleBoxFlat.new();style.bg_color=Color("19383e");style.set_corner_radius_all(7);style.set_content_margin_all(12)
	button.add_theme_stylebox_override("normal",style)
	var active:=style.duplicate();active.bg_color=Color("2b5659");button.add_theme_stylebox_override("hover",active);button.add_theme_stylebox_override("pressed",active)
	parent.add_child(button);return button

func show_home() -> void:
	_home.show();_records.hide();pace_picker.hide();_heading.text=tr("旅程");_error.text="";_error_source=""
	new_button.call_deferred("grab_focus")

func show_paces() -> void:
	_home.hide();_records.hide();pace_picker.show()
	_heading.text=tr("journey.choose")
	pace_picker.select(0)
	pace_picker.confirm.call_deferred("grab_focus")

func show_records(rows: Array[Dictionary]) -> void:
	_rows=rows
	_home.hide();pace_picker.hide();_records.show();_heading.text=tr("選擇紀錄");_error.text="";_error_source=""
	for child in _list.get_children():_list.remove_child(child);child.queue_free()
	if rows.is_empty():_label(_list,"還沒有旅程，先建立新遊戲。",16,Color("b9c8c9"))
	for i in range(rows.size()):
		var row: Dictionary=rows[i]
		var kind: String=tr("手動檢查點 · 另存續玩") if row.manual else (tr("先前旅程") if row.legacy else tr("自動紀錄"))
		var text: String=tr("%s\n無法讀取 · 原檔已保留")%kind
		if row.status=="ready":
			var outcome: String={"active":"","victory":tr(" · 已通關"),"defeat":tr(" · 挑戰結束")}[row.outcome]
			text=tr("第 %d 天 · 聚落 %d%s\n%s")%[row.day,row.settlement,outcome,kind]
		var button=_button(_list,text,"restore" if row.manual else "save");button.add_theme_font_size_override("font_size",16)
		button.disabled=row.status!="ready";button.pressed.connect(func():record_selected.emit(i))
		var pace: int=int(row.get("pace",-1))
		var pace_key: String="journey.legacy" if pace<0 else ["journey.expedition","journey.settler","journey.siege"][pace]
		_label(_list,tr(pace_key)+" · "+row.date,12,Color("8fa9ad"))
	back_button.call_deferred("grab_focus")

func show_error(message: String) -> void:
	_error_source=message
	_error.text=tr(message)

func _refresh_language() -> void:
	if not is_node_ready():return
	_bindings=_bindings.filter(func(binding):return is_instance_valid(binding.node))
	for binding in _bindings:binding.node.text=tr(binding.source)
	var error=_error_source
	if _records.visible:show_records(_rows)
	elif pace_picker.visible:
		_heading.text=tr("journey.choose");pace_picker.refresh()
	else:_heading.text=tr("旅程")
	if not error.is_empty():show_error(error)
