extends Control
signal new_game_requested(pace: int)
signal core_game_requested
signal prologue_requested
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
var replay_button: Button
var _entrance: Tween
var pace_picker: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme=preload("res://presentation/refuge_theme.gd").make()
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(preload("res://presentation/title_backdrop.gd").new())
	var margin:=MarginContainer.new();add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right"]:margin.add_theme_constant_override("margin_"+side,42)
	for side in ["top","bottom"]:margin.add_theme_constant_override("margin_"+side,26)
	var columns:=HBoxContainer.new();columns.add_theme_constant_override("separation",36);margin.add_child(columns)
	var identity:=VBoxContainer.new();identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	identity.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;identity.add_theme_constant_override("separation",16);columns.add_child(identity)
	_label(identity,"opening.kicker",13,Color("d4b680"))
	_label(identity,"CYBER\nKINGDOM",52,Color("d5eade"))
	_label(identity,"最後的避難所",23,Color("e2c9a0"))
	_label(identity,"opening.promise",15,Color("b9c8c9"))
	var card:=PanelContainer.new();card.custom_minimum_size.x=350;card.size_flags_vertical=Control.SIZE_EXPAND_FILL;columns.add_child(card)
	var style: StyleBoxFlat=preload("res://presentation/refuge_theme.gd").plate(Color("0a151fef"),Color("82795f"),24)
	card.add_theme_stylebox_override("panel",style)
	preload("res://presentation/refuge_theme.gd").decorate(card)
	var scroll_body: ScrollContainer=ScrollContainer.new();scroll_body.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll_body.size_flags_vertical=Control.SIZE_EXPAND_FILL;card.add_child(scroll_body)
	var body:=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",12);scroll_body.add_child(body)
	_heading=_label(body,"旅程",22,Color("e0c995"))
	body.add_child(HSeparator.new())
	var selector=LanguageSelector.new();body.add_child(selector);selector.owner=self;selector.unique_name_in_owner=true
	_home=VBoxContainer.new();_home.size_flags_vertical=Control.SIZE_EXPAND_FILL;_home.alignment=BoxContainer.ALIGNMENT_CENTER;_home.add_theme_constant_override("separation",12);body.add_child(_home)
	var core_button: Button=_button(_home,"core.begin","camp")
	core_button.pressed.connect(func()->void:core_game_requested.emit())
	new_button=_button(_home,"opening.begin","camp");new_button.pressed.connect(show_paces)
	var primary: StyleBoxFlat=new_button.get_theme_stylebox("normal").duplicate()
	primary.bg_color=Color("796241");primary.border_color=Color("d6bb86");primary.set_border_width_all(1)
	new_button.add_theme_stylebox_override("normal",primary)
	var primary_hover: StyleBoxFlat=primary.duplicate();primary_hover.bg_color=Color("9b7b4e")
	new_button.add_theme_stylebox_override("hover",primary_hover);new_button.add_theme_stylebox_override("pressed",primary_hover)
	new_button.add_theme_color_override("font_color",Color("fff1d9"))
	records_button=_button(_home,"選擇紀錄","restore");records_button.custom_minimum_size.y=50;records_button.pressed.connect(func():records_requested.emit())
	_label(_home,"每次新遊戲都另存一段旅程。",14,Color("96acae"))
	if OS.has_feature("web"):
		var guide=_button(_home,"玩家圖文指南","book");guide.custom_minimum_size.y=40;guide.add_theme_font_size_override("font_size",preload("res://data/scene_finish.tres").action_size)
		guide.pressed.connect(preload("res://presentation/web_player_guide.gd").open)
	replay_button=_button(_home,"opening.replay","restore");replay_button.custom_minimum_size.y=36
	replay_button.add_theme_font_size_override("font_size",preload("res://data/scene_finish.tres").action_size)
	replay_button.pressed.connect(func() -> void:prologue_requested.emit())
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
	var label:=Label.new();label.text=tr(text);_bindings.append({"node":label,"source":text});label.add_theme_font_size_override("font_size",preload("res://presentation/refuge_theme.gd").type_size(size));label.add_theme_color_override("font_color",color);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(label);return label

func _button(parent: Node, text: String, icon: String) -> Button:
	var button:=Button.new();button.text=tr(text);_bindings.append({"node":button,"source":text});button.icon=Icons.get_icon(icon);button.expand_icon=true
	button.custom_minimum_size=Vector2(0,64);button.add_theme_constant_override("icon_max_width",26);button.add_theme_constant_override("h_separation",14)
	button.add_theme_font_size_override("font_size",preload("res://data/scene_finish.tres").action_size)
	button.alignment=HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_stylebox_override("normal",preload("res://presentation/refuge_theme.gd").plate(Color("152a32f2"),Color("536b6c"),14))
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
		var button=_button(_list,text,"restore" if row.manual else "save");button.add_theme_font_size_override("font_size",preload("res://data/scene_finish.tres").body_size)
		button.disabled=row.status!="ready";button.pressed.connect(func():record_selected.emit(i))
		var pace: int=int(row.get("pace",-1))
		var pace_key: String="journey.legacy" if pace<0 else ["journey.expedition","journey.settler","journey.siege"][pace]
		if row.get("core",false):pace_key="core.begin"
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

func reveal() -> void:
	show_home();show()
	if _entrance!=null:_entrance.kill()
	modulate.a=0.0
	_entrance=create_tween()
	_entrance.tween_property(self,"modulate:a",1.0,preload("res://data/opening_direction.tres").menu_reveal_seconds)
