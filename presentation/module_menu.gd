extends PanelContainer
signal module_selected(id: String)
signal closed
const Style=preload("res://presentation/module_style.gd")
const Icons=preload("res://presentation/ui_icons.gd")
const IDS: Array[String]=Style.IDS
var _title: Label
var _hint: Label
var _progress: Label
var _buttons: Array[Button]=[]
var _close: Button
var _grid: GridContainer
var _scroll: ScrollContainer
var _selected_skin: StyleBoxFlat
var _locked_skin: StyleBoxFlat
func _skin(fill: Color, border: Color) -> StyleBoxFlat:
 var skin: StyleBoxFlat=StyleBoxFlat.new()
 skin.bg_color=fill;skin.border_color=border;skin.set_border_width_all(1);skin.set_content_margin_all(12)
 skin.set_corner_radius_all(4)
 return skin
func _ready() -> void:
 theme=Theme.new();theme.default_font=preload("res://presentation/localized_font.gd").current()
 add_theme_stylebox_override("panel",_skin(Color("0a1728f7"),Color("56747d")))
 _selected_skin=_skin(Color("183937"),Color("a5e5c4"));_locked_skin=_skin(Color("101e30"),Color("2c4052"))
 var box: VBoxContainer=VBoxContainer.new();box.add_theme_constant_override("separation",10);add_child(box)
 _title=Label.new();_title.add_theme_font_size_override("font_size",23);_title.add_theme_color_override("font_color",Color("f1dfb9"));box.add_child(_title)
 _progress=Label.new();_progress.add_theme_font_size_override("font_size",14);_progress.add_theme_color_override("font_color",Color("90b3ba"));box.add_child(_progress)
 _scroll=ScrollContainer.new();_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 _scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;box.add_child(_scroll)
 _grid=GridContainer.new();_grid.columns=2;_grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 _grid.add_theme_constant_override("h_separation",10);_grid.add_theme_constant_override("v_separation",10);_scroll.add_child(_grid)
 for id: String in IDS:
  var button: Button=Button.new();button.alignment=HORIZONTAL_ALIGNMENT_LEFT
  button.custom_minimum_size=Vector2(0,108);button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  button.add_theme_font_size_override("font_size",15);button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  button.icon=Icons.get_icon(Style.icon(id));button.add_theme_constant_override("icon_max_width",28);button.expand_icon=true
  button.add_theme_color_override("icon_normal_color",Style.tint(id));button.add_theme_color_override("icon_disabled_color",Style.tint(id).darkened(0.35))
  button.add_theme_color_override("font_disabled_color",Color("9faebb"))
  button.add_theme_stylebox_override("normal",_skin(Color("172c3b"),Color("3d5a66")))
  button.add_theme_stylebox_override("hover",_skin(Color("213e48"),Style.tint(id)))
  button.pressed.connect(func():module_selected.emit(id))
  _grid.add_child(button);_buttons.append(button)
 _hint=Label.new();_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_hint.add_theme_font_size_override("font_size",14);box.add_child(_hint)
 _close=Button.new();_close.custom_minimum_size.y=46;_close.pressed.connect(func():closed.emit());box.add_child(_close)
 hide()
func arrange(bounds: Rect2) -> void:
 size=Vector2(minf(800,bounds.size.x-32),minf(580,bounds.size.y-24))
 position=bounds.get_center()-size*0.5
 _grid.columns=2 if size.x>=580 else 1
func present(modules: RefCounted, touch: bool, crystals: int=0) -> void:
 theme.default_font=preload("res://presentation/localized_font.gd").current()
 _title.text=tr("module.collection %d/%d")%[modules.found.size(),modules.specs.size()]
 var ranks: Array[String]=[]
 for i: int in [1,4,8]:
  if i>modules.specs.size():continue
  ranks.append(("◆ " if modules.found.size()>=i else "◇ ")+tr("module.rank.%d"%i))
 _progress.text="     ·     ".join(ranks)
 for i: int in range(IDS.size()):
  var id: String=IDS[i]
  var spec: RefCounted=modules.spec_for(id)
  var button: Button=_buttons[i];button.visible=spec!=null
  if spec==null:continue
  var owned: bool=modules.stored.has(id)
  var equipped: bool=modules.equipped==id
  button.disabled=not owned or equipped or crystals<modules.swap_cost
  button.add_theme_stylebox_override("disabled",_selected_skin if equipped else _locked_skin)
  button.text=("◆ " if equipped else "")+tr(Style.title(id))+"  ·  "+tr(Style.role(id))+"\n"
  button.text+=tr(Style.detail(id)) if owned else tr("module.clue %s")%tr(Style.world(spec.planet))
  if owned:button.text+="\n"+(tr("module.equipped") if equipped else tr("更換消耗 %d 顆龍晶")%modules.swap_cost)+"  ·  "+tr("module.cooldown %d")%roundi(float(spec.cooldown)/30)
 _hint.text=tr("雙指向上滑使用已裝部件") if touch else tr("按 K 使用已裝部件；F 開啟選配")
 _hint.text+="\n"+tr("module.tradeoff")
 if crystals<modules.swap_cost:_hint.text+="  "+tr("龍晶不足，無法更換部件。")
 _close.text=tr("返回旅程")
