extends PanelContainer
## Pause menu has large touch targets and shares the same controls on desktop.
const Icons=preload("res://presentation/ui_icons.gd")
signal volume_changed(music: float,effects: float,ambience: float)
signal save_checkpoint_requested
signal load_checkpoint_requested
signal title_requested
const LanguageSelector=preload("res://presentation/language_selector.gd")
var music: HSlider
var effects: HSlider
var ambience: HSlider
var save_button: Button
var load_button: Button
var _tooltips: Dictionary={}
var _numbers: Array[Label]=[]
func _ready() -> void:
	theme=Theme.new();theme.default_font=preload("res://presentation/localized_font.gd").current()
	mouse_filter=Control.MOUSE_FILTER_STOP
	var style:=StyleBoxFlat.new()
	style.bg_color=Color(0.025,0.065,0.085,0.96)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(18)
	add_theme_stylebox_override("panel",style)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",10);add_child(box)
	var selector=LanguageSelector.new();box.add_child(selector);selector.owner=self;selector.unique_name_in_owner=true
	music=_volume_row(box,"music")
	effects=_volume_row(box,"sound")
	ambience=_volume_row(box,"tree")
	var row:=HBoxContainer.new();row.alignment=BoxContainer.ALIGNMENT_CENTER;row.add_theme_constant_override("separation",10);box.add_child(row)
	save_button=_button(row,"save");load_button=_button(row,"restore")
	save_button.pressed.connect(func():save_checkpoint_requested.emit())
	load_button.pressed.connect(func():load_checkpoint_requested.emit())
	var home=_button(row,"camp");_tooltips[home]="保存並回起始頁"
	home.pressed.connect(func():title_requested.emit())
	if OS.has_feature("web"):
		var guide_button:=_button(row,"book")
		guide_button.name="PlayerGuide"
		_tooltips[guide_button]="玩家圖文指南"
		guide_button.pressed.connect(preload("res://presentation/web_player_guide.gd").open)
	music.value_changed.connect(_volume_changed)
	effects.value_changed.connect(_volume_changed)
	ambience.value_changed.connect(_volume_changed)
	set_levels(0.4,0.8,0.6)
	get_node("/root/GameLanguage").changed.connect(_refresh_language)
	_refresh_language()
func _volume_row(box: VBoxContainer, key: String) -> HSlider:
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);box.add_child(row)
	var icon:=TextureRect.new();icon.texture=Icons.get_icon(key);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size=Vector2(34,48);row.add_child(icon)
	var slider:=HSlider.new();slider.min_value=0;slider.max_value=100;slider.step=1;slider.custom_minimum_size=Vector2(200,48);slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(slider)
	var number:=Label.new();number.custom_minimum_size=Vector2(42,48);number.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;row.add_child(number);_numbers.append(number)
	return slider
func _button(row: HBoxContainer,key: String) -> Button:
	var button:=Button.new();button.icon=Icons.get_icon(key);button.expand_icon=true;button.add_theme_constant_override("icon_max_width",28);button.custom_minimum_size=Vector2(64,52);button.focus_mode=Control.FOCUS_NONE;row.add_child(button)
	return button
func _volume_changed(_value: float) -> void:
	_show_levels()
	volume_changed.emit(music.value/100,effects.value/100,ambience.value/100)
func set_levels(music_level: float,effects_level: float,ambience_level: float) -> void:
	music.set_value_no_signal(music_level*100)
	effects.set_value_no_signal(effects_level*100)
	ambience.set_value_no_signal(ambience_level*100)
	_show_levels()
func _show_levels() -> void:
	for index in range(_numbers.size()):
		_numbers[index].text=str(int([music,effects,ambience][index].value))
func record_status(available: bool,saved: bool,failed: bool=false) -> void:
	load_button.disabled=not available
	save_button.icon=Icons.get_icon("save_retry" if failed else "check" if saved else "save")
	save_button.modulate=Color("efb28f") if failed else Color("b6e2cd")

func _refresh_language() -> void:
	for control in _tooltips:control.tooltip_text=tr(_tooltips[control])
