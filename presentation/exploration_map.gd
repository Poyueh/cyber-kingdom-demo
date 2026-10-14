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
var _legend_row: HFlowContainer
var settlement_panel: HBoxContainer
var settlement_tab: Button
var frontier_tab: Button
var _growth: Dictionary={}
var _growth_mode: bool=false
var _safe: Rect2
const LEGEND: Array[String]=["營火","寶箱","特殊部件","地獄之門"]
func _ready() -> void:
 theme=preload("res://presentation/refuge_theme.gd").make()
 mouse_filter=Control.MOUSE_FILTER_STOP
 # Wrapped labels settle after container layout; refit when their minimum shrinks.
 minimum_size_changed.connect(func():
  if _safe.has_area():call_deferred("fit",_safe))
 var style: StyleBoxFlat=preload("res://presentation/refuge_theme.gd").plate(Color("10212a"),Color("82795f"),22)
 add_theme_stylebox_override("panel",style)
 preload("res://presentation/refuge_theme.gd").decorate(self)
 var box:=VBoxContainer.new();box.add_theme_constant_override("separation",10);add_child(box)
 var header:=HBoxContainer.new();box.add_child(header)
 _title=Label.new();_title.add_theme_font_size_override("font_size",preload("res://data/scene_finish.tres").heading_size);_title.add_theme_color_override("font_color",Color("ead4a7"));_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(_title)
 frontier_tab=Button.new();frontier_tab.icon=Icons.get_icon("map");frontier_tab.custom_minimum_size=Vector2(48,48);header.add_child(frontier_tab);frontier_tab.pressed.connect(_show_frontier)
 settlement_tab=Button.new();settlement_tab.name="SettlementTab";settlement_tab.icon=Icons.get_icon("camp");settlement_tab.custom_minimum_size=Vector2(48,48);header.add_child(settlement_tab);settlement_tab.pressed.connect(_show_settlement)
 _hint=Label.new();_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_hint.add_theme_font_size_override("font_size",preload("res://data/scene_finish.tres").caption_size);_hint.add_theme_color_override("font_color",Color("9bb6b3"));box.add_child(_hint)
 _chart=preload("res://presentation/exploration_chart.gd").new();box.add_child(_chart)
 _chart.region_selected.connect(func(key: String):_detail.text=tr(key))
 settlement_panel=preload("res://presentation/settlement_stage_panel.gd").new();box.add_child(settlement_panel);settlement_panel.hide()
 settlement_panel.stage_selected.connect(_stage_selected)
 var row:=HFlowContainer.new();box.add_child(row);_legend_row=row
 for i: int in range(LEGEND.size()):
  var entry:=HBoxContainer.new();row.add_child(entry)
  var icon:=TextureRect.new();icon.texture=Icons.get_icon(["camp","chest","gear","rift"][i]);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.custom_minimum_size=Vector2(24,24);entry.add_child(icon)
  var label:=Label.new();entry.add_child(label);_legend.append(label)
 _detail=Label.new();_detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_detail.add_theme_font_size_override("font_size",preload("res://data/scene_finish.tres").body_size);_detail.add_theme_color_override("font_color",Color("dcc8a1"));box.add_child(_detail)
 _close=Button.new();_close.custom_minimum_size.y=48;_close.pressed.connect(func():closed.emit());box.add_child(_close)

 hide()
func present(sim: RefCounted, knight_x: float) -> void:
 theme.default_font=preload("res://presentation/localized_font.gd").current()
 _title.text=tr("邊境探索圖")
 _hint.text=tr("金色箭頭是你的位置。點選地形或節點查看；虛線仍未探索。")
 _detail.text=tr("深入荒野，讀取遺跡線索，解開封印取得部件。")
 _close.text=tr("返回選單")
 for i: int in range(LEGEND.size()):_legend[i].text=tr(LEGEND[i])+"   "
 _chart.present(Survey.read(sim,knight_x))
 _growth=preload("res://application/settlement_progress.gd").read(sim)
 settlement_tab.visible=not _growth.stages.is_empty()
 frontier_tab.tooltip_text=tr("settlement.map")
 settlement_tab.tooltip_text=tr("settlement.history")
 settlement_panel.present(_growth)
 _show_frontier()
 show()
func fit(safe: Rect2) -> void:
 _safe=safe
 size=Vector2(minf(780,safe.size.x-24),0)
 position=safe.get_center()-size*0.5

func _show_frontier() -> void:
 _growth_mode=false;settlement_panel.hide();_chart.show();_legend_row.show()
 _title.text=tr("邊境探索圖")
 _hint.text=tr("金色箭頭是你的位置。點選地形或節點查看；虛線仍未探索。")
 _detail.text=tr("深入荒野，讀取遺跡線索，解開封印取得部件。")
 frontier_tab.modulate=Color("e4cc96");settlement_tab.modulate=Color("a5b7b8")
 if _safe.has_area():call_deferred("fit",_safe)

func _show_settlement() -> void:
 if _growth.stages.is_empty():return
 _growth_mode=true;_chart.hide();_legend_row.hide();settlement_panel.show()
 _title.text=tr("settlement.history")
 _hint.text=tr("settlement.history_hint")
 settlement_panel.select(clampi(_growth.level-1,0,2))
 settlement_tab.modulate=Color("e4cc96");frontier_tab.modulate=Color("a5b7b8")
 if _safe.has_area():call_deferred("fit",_safe)

func _stage_selected(key: String, unlocked: bool) -> void:
 if _growth_mode:_detail.text=tr(key) if unlocked else tr("settlement.requirement")
