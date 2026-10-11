extends HBoxContainer
signal stage_selected(detail_key: String, unlocked: bool)
const Icons = preload("res://presentation/ui_icons.gd")
var cards: Array[Button] = []
var _titles: Array[Label] = []
var _states: Array[Label] = []
var _icons: Array[TextureRect] = []
var _stages: Array[Dictionary] = []
var _selected: int = 0

func _ready() -> void:
	custom_minimum_size = Vector2(280,190)
	add_theme_constant_override("separation",10)
	for index: int in range(3):
		var card: Button = Button.new()
		card.name = "SettlementStage%d" % (index+1)
		card.custom_minimum_size = Vector2(86,190)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.pressed.connect(func() -> void:select(index))
		add_child(card)
		cards.append(card)
		var box: VBoxContainer = VBoxContainer.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		box.offset_left=8;box.offset_right=-8;box.offset_top=20;box.offset_bottom=-12
		box.add_theme_constant_override("separation",12)
		card.add_child(box)
		var icon: TextureRect = TextureRect.new()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.custom_minimum_size = Vector2(40,40)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(icon);_icons.append(icon)
		var title: Label = _label(17)
		title.custom_minimum_size.y=48
		box.add_child(title);_titles.append(title)
		var state: Label = _label(13)
		box.add_child(state);_states.append(state)

func _label(font_size: int) -> Label:
	var label: Label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	return label

func present(data: Dictionary) -> void:
	_stages.assign(data.stages)
	for index: int in range(cards.size()):
		cards[index].visible = index < _stages.size()
		if index >= _stages.size():continue
		var stage: Dictionary = _stages[index]
		_icons[index].texture = Icons.get_icon(stage.icon)
		_icons[index].modulate = Color("a8e8cf") if stage.complete else Color("5e727a")
		_titles[index].text = tr(stage.title)
		_states[index].text = tr("settlement.ready" if stage.complete else "settlement.locked")
		_states[index].add_theme_color_override("font_color",Color("e0c58b") if stage.complete else Color("8e9d9d"))
	select(clampi(data.level-1,0,2))

func select(index: int) -> void:
	if index >= _stages.size():return
	_selected = index
	for other: int in range(cards.size()):
		var plate: StyleBoxFlat = StyleBoxFlat.new()
		plate.bg_color = Color("233b40") if other==index else Color("122831")
		plate.border_color = Color("e1c893") if other==index else Color("425c61")
		plate.set_border_width_all(1)
		plate.border_width_top=3 if other==index else 1
		cards[other].add_theme_stylebox_override("normal",plate)
		var hover: StyleBoxFlat = plate.duplicate()
		hover.bg_color=Color("2b494b")
		cards[other].add_theme_stylebox_override("hover",hover)
	stage_selected.emit(_stages[index].detail,_stages[index].complete)
