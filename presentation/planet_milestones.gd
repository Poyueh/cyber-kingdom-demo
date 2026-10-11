extends Control
## Menu-only, read-only account of this world's optional accomplishments.
const Icons = preload("res://presentation/ui_icons.gd")
var report: Dictionary = {}
var _rows: Array[HBoxContainer] = []
var _titles: Array[Label] = []
var _counts: Array[Label] = []
var _bars: Array[ProgressBar] = []
var _unknown: Label

func _ready() -> void:
	name = "Milestones"
	custom_minimum_size = Vector2(230,84)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_unknown = Label.new()
	_unknown.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_unknown.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_unknown.add_theme_font_size_override("font_size",13)
	add_child(_unknown)
	for index: int in range(3):
		var row: HBoxContainer = HBoxContainer.new()
		row.position = Vector2(0,index*28)
		row.size = Vector2(230,22)
		row.add_theme_constant_override("separation",8)
		add_child(row);_rows.append(row)
		var icon: TextureRect = TextureRect.new()
		icon.custom_minimum_size = Vector2(18,18)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var title: Label = Label.new()
		title.add_theme_font_size_override("font_size",13)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(title);_titles.append(title)
		var count: Label = Label.new()
		count.add_theme_font_size_override("font_size",13)
		row.add_child(count);_counts.append(count)
		var bar: ProgressBar = ProgressBar.new()
		bar.show_percentage = false
		bar.position = Vector2(26,index*28+22)
		bar.size = Vector2(204,2)
		var back: StyleBoxFlat = StyleBoxFlat.new();back.bg_color = Color("263b45")
		var fill: StyleBoxFlat = StyleBoxFlat.new();fill.bg_color = Color("95c8b1")
		bar.add_theme_stylebox_override("background",back);bar.add_theme_stylebox_override("fill",fill)
		add_child(bar);_bars.append(bar)

func present(value: Dictionary) -> void:
	report = value
	_unknown.visible = not report.known
	_unknown.text = tr("milestone.unvisited")
	for index: int in range(3):
		_rows[index].visible = report.known;_bars[index].visible = report.known
		if not report.known:continue
		var goal: Dictionary = report.goals[index]
		_rows[index].get_child(0).texture = Icons.get_icon(goal.icon)
		_titles[index].text = tr("milestone."+goal.id)
		_counts[index].text = "%d / %d"%[goal.count,goal.total]
		_rows[index].modulate = Color("ead5a1") if goal.complete else Color("b4ccd1")
		_bars[index].value = 100.0*goal.count/maxi(1,goal.total)
