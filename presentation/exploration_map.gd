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
 var style:=StyleBoxFlat.new();style.bg_color=Color("10212a");style.border_color=Color("64776d");style.set_border_width_all(1);style.border_width_top=3;style.set_content_margin_all(22);style.shadow_color=Color(0,0,0,0.5);style.shadow_size=14;add_theme_stylebox_override("panel",style)
 var box:=VBoxContainer.new();box.add_theme_constant_override("separation",10);add_child(box)
 _title=Label.new();_title.add_theme_font_size_override("font_size",25);_title.add_theme_color_override("font_color",Color("ead4a7"));box.add_child(_title)
 _hint=Label.new();_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_hint.add_theme_font_size_override("font_size",14);_hint.add_theme_color_override("font_color",Color("9bb6b3"));box.add_child(_hint)
 _chart=preload("res://presentation/exploration_chart.gd").new();box.add_child(_chart)
 _chart.region_selected.connect(func(key: String):_detail.text=tr(key))
 var row:=HFlowContainer.new();box.add_child(row)
 for i: int in range(LEGEND.size()):
  var entry:=HBoxContainer.new();row.add_child(entry)
  var icon:=TextureRect.new();icon.texture=Icons.get_icon(["camp","chest","gear","rift"][i]);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.custom_minimum_size=Vector2(24,24);entry.add_child(icon)
  var label:=Label.new();entry.add_child(label);_legend.append(label)
 _detail=Label.new();_detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_detail.add_theme_font_size_override("font_size",15);_detail.add_theme_color_override("font_color",Color("dcc8a1"));box.add_child(_detail)
 _close=Button.new();_close.custom_minimum_size.y=48;_close.pressed.connect(func():closed.emit());box.add_child(_close)
 var button_style:=StyleBoxFlat.new();button_style.bg_color=Color("213e42");button_style.border_color=Color("66897e");button_style.set_border_width_all(1)
 _close.add_theme_stylebox_override("normal",button_style)
 var hover: StyleBoxFlat=button_style.duplicate();hover.bg_color=Color("305756");hover.border_color=Color("ddc58b");_close.add_theme_stylebox_override("hover",hover)
 hide()
func present(sim: RefCounted, knight_x: float) -> void:
 theme.default_font=preload("res://presentation/localized_font.gd").current()
 _title.text=tr("邊境探索圖")
 _hint.text=tr("金色箭頭是你的位置。點選地形或節點查看；虛線仍未探索。")
 _detail.text=tr("深入荒野，讀取遺跡線索，解開封印取得部件。")
 _close.text=tr("返回選單")
 for i: int in range(LEGEND.size()):_legend[i].text=tr(LEGEND[i])+"   "
 _chart.present(Survey.read(sim,knight_x))
 show()
func fit(safe: Rect2) -> void:
 _safe=safe
 size=Vector2(minf(780,safe.size.x-24),0)
 position=safe.get_center()-size*0.5
