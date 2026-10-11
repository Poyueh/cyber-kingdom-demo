extends VBoxContainer
signal confirmed(pace: int)
signal cancelled
const Icons = preload("res://presentation/ui_icons.gd")
@export var catalog: Resource=preload("res://data/journey_paces.tres")
var selected: int=0
var choices: Array[Button]=[]
var description: Label
var note: Label
var confirm: Button
var back: Button

func _ready() -> void:
	assert(catalog.valid())
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	alignment=BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation",10)
	var row: HBoxContainer=HBoxContainer.new()
	row.add_theme_constant_override("separation",6);add_child(row)
	for option: Resource in catalog.options:
		var button: Button=_button(row,48)
		button.name="Pace%d"%option.pace_id
		button.icon=Icons.get_icon(option.icon)
		button.add_theme_constant_override("icon_max_width",22)
		button.expand_icon=true
		button.toggle_mode=true
		button.pressed.connect(func() -> void:select(option.pace_id))
		choices.append(button)
	description=_label(15,Color("dfd9bd"))
	description.custom_minimum_size.y=72
	note=_label(13,Color("9db6b7"))
	note.custom_minimum_size.y=54
	confirm=_button(self,46);confirm.name="BeginJourney"
	confirm.pressed.connect(func() -> void:confirmed.emit(selected))
	back=_button(self,34);back.pressed.connect(func() -> void:cancelled.emit())
	refresh()

func _button(parent: Node, height: float) -> Button:
	var button: Button=Button.new()
	button.custom_minimum_size=Vector2(0,height)
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size",15)
	var plate: StyleBoxFlat=StyleBoxFlat.new()
	plate.bg_color=Color("19383e");plate.border_color=Color("4c7271")
	plate.set_border_width_all(1);plate.set_content_margin_all(6)
	button.add_theme_stylebox_override("normal",plate)
	var active: StyleBoxFlat=plate.duplicate()
	active.bg_color=Color("365557");active.border_color=Color("dfc588")
	button.add_theme_stylebox_override("pressed",active)
	button.add_theme_stylebox_override("hover",active)
	parent.add_child(button)
	return button

func _label(font_size: int, color: Color) -> Label:
	var label: Label=Label.new()
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	add_child(label)
	return label

func select(id: int) -> void:
	if catalog.find(id)==null:return
	selected=id
	refresh()

func refresh() -> void:
	if not is_node_ready():return
	for index: int in range(choices.size()):
		var option: Resource=catalog.options[index]
		choices[index].text=tr(option.title_key)
		choices[index].set_pressed_no_signal(option.pace_id==selected)
	description.text=tr(catalog.find(selected).description_key)
	note.text=tr("journey.note")
	confirm.text=tr("journey.begin")
	back.text=tr("返回")
