extends PanelContainer
signal module_selected(id: String)
signal closed
const IDS: Array[String]=["arc","lance"]
const TITLES: Array[String]=["雷弧震盪","穿甲雷槍"]
const DETAILS: Array[String]=["震退附近敵人；消耗體力，冷卻 %d 秒。","向前方射出穿甲能量；消耗體力，冷卻 %d 秒。"]
var _title: Label
var _hint: Label
var _buttons: Array[Button]=[]
var _close: Button
func _ready() -> void:
 theme=Theme.new()
 theme.default_font=preload("res://presentation/localized_font.gd").current()
 var skin: StyleBoxFlat=StyleBoxFlat.new()
 skin.bg_color=Color("0d1f2bef");skin.border_color=Color("559f9e");skin.set_border_width_all(2);skin.set_content_margin_all(14)
 add_theme_stylebox_override("panel",skin)
 var box: VBoxContainer=VBoxContainer.new();box.add_theme_constant_override("separation",10);add_child(box)
 _title=Label.new();_title.add_theme_font_size_override("font_size",22);box.add_child(_title)
 for index in range(2):
  var button: Button=Button.new();button.alignment=HORIZONTAL_ALIGNMENT_LEFT
  button.custom_minimum_size=Vector2(0,88);button.add_theme_font_size_override("font_size",16)
  button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  button.icon=preload("res://presentation/ui_icons.gd").get_icon("gear" if index==0 else "sword")
  button.add_theme_constant_override("icon_max_width",26);button.expand_icon=true
  button.pressed.connect(func():module_selected.emit(IDS[index]))
  box.add_child(button);_buttons.append(button)
 _hint=Label.new();_hint.custom_minimum_size=Vector2(280,40);_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_hint.add_theme_font_size_override("font_size",14);box.add_child(_hint)
 _close=Button.new();_close.pressed.connect(func():closed.emit());box.add_child(_close)
 hide()
func present(modules: RefCounted, touch: bool) -> void:
 theme.default_font=preload("res://presentation/localized_font.gd").current()
 _title.text=tr("特殊部件選配")
 for i in range(2):
  var owned: bool=modules.stored.has(IDS[i])
  _buttons[i].disabled=not owned
  _buttons[i].text=("✓ " if modules.equipped==IDS[i] else "")+tr(TITLES[i])+"
"+(tr(DETAILS[i]) % roundi(float(modules.specs[i].cooldown)/30.0) if owned else tr("探索取得，帶回此處安裝"))
 _hint.text=tr("雙指向上滑使用已裝部件") if touch else tr("按 K 使用已裝部件；F 開啟選配")
 _close.text=tr("返回旅程")
