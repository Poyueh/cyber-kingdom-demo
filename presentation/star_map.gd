extends CanvasLayer
## Full-screen cosmic atlas with inspect-before-launch and a read-only menu entry.
signal destination_selected(id: int)
signal closed
const Chart=preload("res://presentation/star_route_chart.gd")
const Scenery=preload("res://presentation/planet_scenery.gd")
const NAMES: Array[String]=["planet.forest","planet.desert","planet.frost","planet.swamp","planet.volcanic","planet.storm","planet.void"]
const DESCRIPTIONS: Array[String]=["planet.forest_info","planet.desert_info","planet.frost_info","planet.swamp_info","planet.volcanic_info","planet.storm_info","planet.void_info"]
const DRAGONS: Array[String]=["planet.dragon_forest","planet.dragon_desert","planet.dragon_frost","planet.dragon_swamp","planet.dragon_volcanic","planet.dragon_storm","planet.dragon_void"]
var _panel: PanelContainer
var _title: Label
var _detail: Label
var _legend: Label
var _name: Label
var _dragon: Label
var _description: Label
var _preview: TextureRect
var _milestones: Control
var _chart: Chart
var _buttons: Array[Button]=[]
var _back: Button
var _launch: Button
var _journey: RefCounted
var _sim: RefCounted
var _read_only: bool=false
var _selected: int=0
func _ready() -> void:
 layer=80
 var shade: ColorRect=ColorRect.new();shade.color=Color("030b16ed");shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 var sky: ShaderMaterial=ShaderMaterial.new();sky.shader=preload("res://presentation/cosmic_sky.gdshader");sky.set_shader_parameter("nebula_strength",preload("res://data/cosmic_interface.tres").nebula_strength);shade.material=sky
 var center: MarginContainer=MarginContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side: String in ["left","top","right","bottom"]:center.add_theme_constant_override("margin_"+side,12)
 add_child(center)
 _panel=PanelContainer.new();center.add_child(_panel)
 _panel.theme=preload("res://presentation/refuge_theme.gd").make()
 var skin: StyleBoxFlat=preload("res://presentation/refuge_theme.gd").plate(Color("0c192824"),Color("82795f"),16)
 _panel.add_theme_stylebox_override("panel",skin)
 _panel.set_meta("cosmic",true)
 preload("res://presentation/refuge_theme.gd").decorate(_panel)
 var box: VBoxContainer=VBoxContainer.new();box.add_theme_constant_override("separation",8);_panel.add_child(box)
 _title=_label(box,24);_title.add_theme_color_override("font_color",Color("ead5a1"))
 _legend=_label(box,13);_legend.add_theme_color_override("font_color",Color("9db4c4"))
 var row: HBoxContainer=HBoxContainer.new();row.add_theme_constant_override("separation",14);row.size_flags_vertical=Control.SIZE_EXPAND_FILL;box.add_child(row)
 _chart=Chart.new();row.add_child(_chart);_chart.selected.connect(select_planet);_buttons=_chart.buttons
 var scroll: ScrollContainer=ScrollContainer.new();scroll.custom_minimum_size=Vector2(254,0);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;row.add_child(scroll)
 var card: VBoxContainer=VBoxContainer.new();card.custom_minimum_size=Vector2(240,0);card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_theme_constant_override("separation",7);scroll.add_child(card)
 _preview=TextureRect.new();_preview.custom_minimum_size=Vector2(240,42);_preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;_preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;card.add_child(_preview)
 _name=_label(card,20);_dragon=_label(card,14);_dragon.add_theme_color_override("font_color",Color("cfb98d"))
 _description=_label(card,14,true);_description.custom_minimum_size=Vector2(230,54)
 _milestones=preload("res://presentation/planet_milestones.gd").new();card.add_child(_milestones)
 _detail=_label(card,13,true);_detail.custom_minimum_size=Vector2(230,44);_detail.add_theme_color_override("font_color",Color("96ccca"))
 var controls: HBoxContainer=HBoxContainer.new();controls.add_theme_constant_override("separation",12);box.add_child(controls)
 _back=_button(controls);_back.pressed.connect(func():closed.emit())
 _launch=_button(controls);_launch.pressed.connect(func():
  if not _launch.disabled:destination_selected.emit(_selected))
 hide()
func _label(parent: Node, font_size: int, wrap: bool=false) -> Label:
 var label: Label=Label.new();label.add_theme_font_size_override("font_size",preload("res://presentation/refuge_theme.gd").type_size(font_size))
 if wrap:label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 parent.add_child(label);return label
func _button(parent: Node) -> Button:
 var button: Button=Button.new();button.custom_minimum_size=Vector2(0,48);button.size_flags_horizontal=Control.SIZE_EXPAND_FILL

 parent.add_child(button);return button
func present(journey: RefCounted, sim: RefCounted, read_only: bool=false) -> void:
 _journey=journey;_sim=sim;_read_only=read_only
 _panel.theme.default_font=preload("res://presentation/localized_font.gd").current()
 _title.text=tr("planet.atlas")+"   ·   ◇ %d / 7"%journey.core_count(sim)
 _legend.text=tr("planet.legend")
 _chart.present(journey,sim,NAMES)
 _back.text=tr("返回選單" if read_only else "返回旅程")
 select_planet(journey.current)
 show()
func select_planet(id: int) -> void:
 _selected=id;_chart.selection=id;_chart.queue_redraw()
 _milestones.present(preload("res://application/voyage_progress.gd").read(_journey,_sim,id))
 _name.text=tr(NAMES[id]);_name.modulate=Chart.COLORS[id]
 _dragon.text=tr(DRAGONS[id]);_description.text=tr(DESCRIPTIONS[id])
 var config: Dictionary=_journey.configs[id]
 _description.text+="\n"+tr("planet.gates %d")%(int(config.get("rift_left_count",1))+int(config.get("rift_right_count",1)))
 _preview.texture=preload("res://data/cyber_frontier_art.tres").woodland if id==0 else Scenery.SKIES[id-1]
 var available: bool=_journey.accessible(id,_sim)
 var visited: bool=id==_journey.current or not _journey.planets[id].is_empty()
 _launch.disabled=_read_only or id==_journey.current or not available
 _launch.text=tr("planet.here" if id==_journey.current else "planet.return" if visited else "planet.explore")
 if not available:
  var required: PackedStringArray=[]
  for source: int in range(7):
   if _journey.required_mask(id)&(1<<source) and not _journey.has_core(source,_sim):required.append(tr(NAMES[source]))
  _detail.text=tr("planet.needs_core")+"\n"+" · ".join(required)
 elif _read_only:_detail.text=tr("planet.chart_only")
 elif _journey.has_core(id,_sim):_detail.text=tr("planet.liberated")
 else:_detail.text=tr("planet.travel_hint")
func show_error() -> void:_detail.text=tr("planet.save_error")
func _unhandled_key_input(event: InputEvent) -> void:
 if not visible:return
 if event.is_action_pressed("ui_cancel"):closed.emit();get_viewport().set_input_as_handled()
 else:
  for action: String in ["ui_left","ui_right","ui_up","ui_down"]:
   if not event.is_action_pressed(action):continue
   var direction: Vector2={"ui_left":Vector2.LEFT,"ui_right":Vector2.RIGHT,"ui_up":Vector2.UP,"ui_down":Vector2.DOWN}[action]
   var nearest: int=_selected;var score: float=INF
   for id: int in range(7):
    var offset: Vector2=_chart._point(id)-_chart._point(_selected)
    if offset.dot(direction)<=0:continue
    var candidate: float=offset.length()+absf(offset.cross(direction))*2
    if candidate<score:nearest=id;score=candidate
   select_planet(nearest);get_viewport().set_input_as_handled();return
