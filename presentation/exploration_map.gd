extends PanelContainer
signal closed
const Survey=preload("res://application/exploration_survey.gd")
const Icons=preload("res://presentation/ui_icons.gd")
var _title: Label
var _hint: Label
var _detail: Label
var _chart: Control
var _close: Button
var _legend: Array[Label]=[]
var _safe: Rect2
const LEGEND: Array[String]=["營火","寶箱","特殊部件","地獄之門"]
func _ready() -> void:
 theme=Theme.new();theme.default_font=preload("res://presentation/localized_font.gd").current()
 mouse_filter=Control.MOUSE_FILTER_STOP
 # Wrapped labels settle after container layout; refit when their minimum shrinks.
 minimum_size_changed.connect(func():
  if _safe.has_area():call_deferred("fit",_safe))
 var style:=StyleBoxFlat.new();style.bg_color=Color("101e28");style.border_color=Color("55837c");style.set_border_width_all(2);style.set_content_margin_all(18);add_theme_stylebox_override("panel",style)
 var box:=VBoxContainer.new();box.add_theme_constant_override("separation",10);add_child(box)
 _title=Label.new();_title.add_theme_font_size_override("font_size",24);box.add_child(_title)
 _hint=Label.new();_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(_hint)
 _chart=preload("res://presentation/exploration_chart.gd").new();box.add_child(_chart)
 _chart.region_selected.connect(func(key: String):_detail.text=tr(key))
 var row:=HFlowContainer.new();box.add_child(row)
 for i: int in range(LEGEND.size()):
  var entry:=HBoxContainer.new();row.add_child(entry)
  var icon:=TextureRect.new();icon.texture=Icons.get_icon(["camp","chest","gear","rift"][i]);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.custom_minimum_size=Vector2(24,24);entry.add_child(icon)
  var label:=Label.new();entry.add_child(label);_legend.append(label)
 _detail=Label.new();_detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(_detail)
 _close=Button.new();_close.custom_minimum_size.y=48;_close.pressed.connect(func():closed.emit());box.add_child(_close)
 hide()
func present(sim: RefCounted, knight_x: float) -> void:
 theme.default_font=preload("res://presentation/localized_font.gd").current()
 _title.text=tr("邊境探索圖")
 _hint.text=tr("金色箭頭是你的位置。點選地區或圖示查看；斜線區域仍未探索。")
 _detail.text=tr("地面青色符光指向尚未取得的寶箱或部件，領取後會熄滅。")
 _close.text=tr("返回選單")
 for i: int in range(LEGEND.size()):_legend[i].text=tr(LEGEND[i])+"   "
 _chart.present(Survey.read(sim,knight_x))
 show()
func fit(safe: Rect2) -> void:
 _safe=safe
 size=Vector2(minf(780,safe.size.x-24),0)
 position=safe.get_center()-size*0.5
