extends CanvasLayer
## Modal, touch-sized route chooser. Only completed rockets can open this screen.
signal destination_selected(id: int)
signal closed
const NAMES: Array[String]=["planet.forest","planet.desert","planet.frost"]
const DESCRIPTIONS: Array[String]=["planet.forest_info","planet.desert_info","planet.frost_info"]
const COLORS: Array[Color]=[Color("6fa58e"),Color("dbad67"),Color("88d8ef")]
const PREVIEWS=[preload("res://data/cyber_frontier_art.tres").woodland,preload("res://art/planets/v001/desert-sky.png"),preload("res://art/planets/v001/frost-sky.png")]
var _panel: PanelContainer
var _title: Label
var _detail: Label
var _buttons: Array[Button]=[]
var _names: Array[Label]=[]
var _infos: Array[Label]=[]
var _back: Button
func _ready() -> void:
 layer=80
 var shade: ColorRect=ColorRect.new();shade.color=Color("050e19ed");shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 var center: CenterContainer=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(center)
 _panel=PanelContainer.new();center.add_child(_panel)
 _panel.theme=Theme.new();_panel.theme.default_font=preload("res://presentation/localized_font.gd").current()
 var skin: StyleBoxFlat=StyleBoxFlat.new();skin.bg_color=Color("0e2131");skin.border_color=Color("678b94");skin.set_border_width_all(2);skin.set_content_margin_all(18);skin.set_corner_radius_all(10)
 _panel.add_theme_stylebox_override("panel",skin)
 var box: VBoxContainer=VBoxContainer.new();box.add_theme_constant_override("separation",12);_panel.add_child(box)
 _title=Label.new();_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;_title.add_theme_font_size_override("font_size",23);box.add_child(_title)
 var cards: HBoxContainer=HBoxContainer.new();cards.add_theme_constant_override("separation",12);box.add_child(cards)
 for id: int in range(3):
  var card: VBoxContainer=VBoxContainer.new();card.custom_minimum_size=Vector2(180,0);card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cards.add_child(card)
  var image: TextureRect=TextureRect.new();image.texture=PREVIEWS[id];image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;image.custom_minimum_size=Vector2(180,90);card.add_child(image)
  var label: Label=Label.new();label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.modulate=COLORS[id];label.add_theme_font_size_override("font_size",19);card.add_child(label);_names.append(label)
  var info: Label=Label.new();info.text=tr(DESCRIPTIONS[id]);info.custom_minimum_size=Vector2(180,56);info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;info.add_theme_font_size_override("font_size",13);card.add_child(info);_infos.append(info)
  var button: Button=Button.new();button.custom_minimum_size=Vector2(180,48);button.pressed.connect(func():destination_selected.emit(id));card.add_child(button);_buttons.append(button)
 _detail=Label.new();_detail.custom_minimum_size=Vector2(560,42);_detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_detail.add_theme_font_size_override("font_size",13);box.add_child(_detail)
 _back=Button.new();_back.custom_minimum_size=Vector2(0,42);_back.pressed.connect(func():closed.emit());box.add_child(_back)
 hide()
func present(journey: RefCounted, sim: RefCounted) -> void:
 _panel.theme.default_font=preload("res://presentation/localized_font.gd").current()
 _title.text=tr("planet.atlas")+"   ·   %d / 3"%journey.core_count(sim)
 for id: int in range(3):
  _infos[id].text=tr(DESCRIPTIONS[id])
  var visited: bool=id==journey.current or not journey.planets[id].is_empty()
  var cleared: bool=sim.planet.core_claimed if id==journey.current else (visited and journey.planets[id].planet.core_claimed)
  _names[id].text=tr(NAMES[id])+("  ◇" if cleared else "")
  _buttons[id].disabled=id==journey.current
  _buttons[id].text=tr("planet.here" if id==journey.current else ("planet.return" if visited else "planet.explore"))
 _detail.text=tr("planet.travel_hint")
 _back.text=tr("返回旅程")
 show()
func show_error() -> void:_detail.text=tr("planet.save_error")
func _unhandled_key_input(event: InputEvent) -> void:
 if visible and event.is_action_pressed("ui_cancel"):
  closed.emit();get_viewport().set_input_as_handled()
