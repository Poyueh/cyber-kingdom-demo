extends Control
signal interaction_requested
signal orders_toggled(open: bool)
signal order_requested(target: String, amount: int)
signal retry_requested
signal guidance_toggled
signal title_requested
var action_button: Button
var wallet: Label
var stamina: ProgressBar
var caption: Label
var interaction: Label
var orders_button: Button
var retry_button: Button
var guide_button: Button
var title_button: Button
var panel: PanelContainer
var rows: Dictionary={}
var row_buttons: Dictionary={}
var _bindings: Array[Dictionary]=[]
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 theme=preload("res://presentation/refuge_theme.gd").make()
 action_button=_button(self,"core.pay",func()->void:interaction_requested.emit())
 wallet=_label(self,18);stamina=ProgressBar.new();stamina.show_percentage=false;stamina.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(stamina)
 caption=_label(self,16);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 interaction=_label(self,16);interaction.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;interaction.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 orders_button=_button(self,"core.orders",func()->void:panel.visible=not panel.visible;orders_toggled.emit(panel.visible))
 guide_button=_button(self,"core.skip",func()->void:guidance_toggled.emit())
 retry_button=_button(self,"core.retry",func()->void:retry_requested.emit())
 title_button=_button(self,"core.title",func()->void:title_requested.emit())
 panel=PanelContainer.new();add_child(panel);panel.hide()
 panel.add_theme_stylebox_override("panel",preload("res://presentation/refuge_theme.gd").plate(Color("0b1925f5"),Color("a38e65"),16))
 var body: VBoxContainer=VBoxContainer.new();body.add_theme_constant_override("separation",8);panel.add_child(body)
 var heading: Label=_label(body,20);heading.text=tr("core.orders")
 for target: String in ["wall_left","wall","beacon","core_tower_right"]:
  var row: HBoxContainer=HBoxContainer.new();body.add_child(row)
  var label: Label=_label(row,16);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;rows[target]=label
  var minus: Button=_button(row,"−",func()->void:order_requested.emit(target,-1))
  var plus: Button=_button(row,"+",func()->void:order_requested.emit(target,1))
  minus.custom_minimum_size=Vector2(48,48);plus.custom_minimum_size=Vector2(48,48)
  row_buttons[target]=[minus,plus]
 _button(body,"core.close",func()->void:panel.hide();orders_toggled.emit(false))
func _label(parent: Node, size: int) -> Label:
 var label: Label=Label.new();label.mouse_filter=Control.MOUSE_FILTER_IGNORE;label.add_theme_font_size_override("font_size",preload("res://presentation/refuge_theme.gd").type_size(size));parent.add_child(label);return label
func _button(parent: Node, key: String, callback: Callable) -> Button:
 var button: Button=Button.new();button.text=tr(key);button.custom_minimum_size=Vector2(92,44);button.focus_mode=Control.FOCUS_NONE
 button.add_theme_font_size_override("font_size",16);button.pressed.connect(callback);parent.add_child(button);_bindings.append({"button":button,"key":key});return button
func present(sim: RefCounted, safe: Rect2, paused: bool, choice: Dictionary, terminal_ready: bool) -> void:
 visible=sim.core_loop.enabled
 if not visible:return
 if not paused:panel.hide()
 for binding: Dictionary in _bindings:binding.button.text=tr(binding.key)
 var core: RefCounted=sim.core_loop
 wallet.text=tr("core.wallet %d")%sim.pouch.amount;wallet.position=safe.position+Vector2(92,22)
 stamina.position=safe.position+Vector2(92,52);stamina.size=Vector2(120,8)
 stamina.max_value=sim.hero.stats.max_stamina;stamina.value=sim.hero.stamina;stamina.visible=sim.hero.stamina<sim.hero.stats.max_stamina
 orders_button.position=safe.position+Vector2(18,72);orders_button.visible=core.income>0 and sim.is_running() and (not paused or panel.visible)
 guide_button.position=safe.position+Vector2(18,122);guide_button.visible=sim.is_running() and core.stage<3 and not paused
 guide_button.text=tr("core.show" if core.skipped else "core.skip")
 retry_button.position=safe.position+Vector2(18,172);retry_button.visible=terminal_ready and (paused or not sim.is_running()) and not panel.visible
 retry_button.text=tr("core.retry" if core.checkpoint_index>0 else "core.restart")
 title_button.position=safe.position+Vector2(18,222);title_button.visible=terminal_ready and not sim.is_running()
 caption.position=Vector2(safe.get_center().x-220,safe.position.y+20);caption.size=Vector2(minf(440,safe.size.x-280),74)
 caption.text=tr(core.hint(sim));caption.visible=not paused and (not core.skipped or core.stage>=2) and (sim.is_running() or core.stage==5)
 if sim.mission.outcome=="defeat" and terminal_ready:
  caption.visible=true;caption.text=tr("core.defeat_fire" if sim.mission.defeat_reason=="core" else "core.defeat_knight")
 interaction.position=Vector2(safe.get_center().x-190,safe.end.y-150);interaction.size=Vector2(380,72)
 interaction.visible=not paused and sim.is_running() and not choice.id.is_empty()
 action_button.position=Vector2(safe.get_center().x-100,safe.end.y-58);action_button.size=Vector2(200,44)
 action_button.visible=interaction.visible;action_button.disabled=not choice.enabled
 action_button.text=tr("core.pay" if choice.cost>0 else "core.interact")
 if interaction.visible:
  var key: String="core.use."+str(choice.id)
  interaction.text=tr(key)
  if choice.cost>0:interaction.text+="\n"+tr("core.price %d %d")%[choice.paid,choice.cost]
  if choice.id=="mark":interaction.text+=" · "+tr("core.yield %d")%sim.frontier.nodes[choice.node_index].crystals
  if not choice.enabled:interaction.text+="\n"+tr(_reason(sim,choice))
 panel.position=Vector2(safe.get_center().x-220,safe.get_center().y-160);panel.size=Vector2(440,320)
 if panel.visible:
  caption.hide();interaction.hide();action_button.hide()
  for target: String in rows:
   var assigned: int=core.orders.targets.count(target)
   var arrived: int=core.orders.arrived(sim,target,core.arrival_radius)
   rows[target].text=tr("core.post."+target)+"\n"+tr("core.count %d %d")%[assigned,arrived]
   row_buttons[target][0].disabled=assigned==0
   row_buttons[target][1].disabled=not core.orders.usable(sim,target) or (target in ["beacon","core_tower_right"] and assigned>=1)
func exclusion_rects() -> Array[Rect2]:
 var result: Array[Rect2]=[]
 if not visible:return result
 for button: Button in [orders_button,guide_button,retry_button,title_button,action_button]:
  if button.visible:result.append(button.get_global_rect())
 if panel.visible:result.append(panel.get_global_rect())
 return result

func _reason(sim: RefCounted, choice: Dictionary) -> String:
 if choice.reason=="core.need_engineer":return choice.reason
 if choice.cost>0 and sim.pouch.amount==0:return "core.empty"
 if choice.id=="mark":return "core.working"
 if choice.id in ["workshop","hunt_tools"]:return "core.stock"
 if choice.id=="trail_cache":return "trail.guarded"
 if choice.id in ["wall","wall_left","tower"]:return "core.building"
 return "core.wait"
