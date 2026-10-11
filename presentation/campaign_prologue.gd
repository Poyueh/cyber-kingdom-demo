extends Control
## The isolated performance is disposable; title fade and narration stay presentation-only.
signal completed
const DIRECTION: Resource=preload("res://data/opening_direction.tres")
var stage: Node
var _elapsed: float=0.0
var _finished: bool=false
var _viewport: SubViewport
var _caption: Label
var _skip: Button
var opening_fade_seconds: float=DIRECTION.fade_in_seconds
var _fade: ColorRect
var _stage_started: bool=false
var _worlds: Control
var _brand: Label
var _top: ColorRect
var _bottom: ColorRect
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_STOP
 var screen: SubViewportContainer=SubViewportContainer.new()
 screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);screen.stretch=true
 screen.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(screen)
 _viewport=SubViewport.new();_viewport.size=Vector2i(960,540);_viewport.world_2d=World2D.new()
 _viewport.gui_disable_input=true;screen.add_child(_viewport)
 if stage!=null:
  stage.completed.connect(finish);_viewport.add_child(stage)
  stage.set_physics_process(false)
 _worlds=preload("res://presentation/opening_worlds.gd").new();add_child(_worlds)
 _worlds.starts=DIRECTION.shot_starts[1];_worlds.ends=DIRECTION.shot_starts[3];_worlds.hide()
 _top=_bar();_bottom=_bar()
 _caption=_label(22);_caption.add_theme_color_override("font_color",Color("eddfc4"))
 _brand=_label(42);_brand.text="CYBER KINGDOM"
 _brand.add_theme_color_override("font_color",Color("d9eee2"))
 _fade=_bar();_fade.color=Color.BLACK
 _fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 _skip=Button.new();_skip.text=tr("跳過前導");_skip.custom_minimum_size=Vector2(120,42);add_child(_skip)
 _skip.add_theme_font_override("font",preload("res://presentation/localized_font.gd").current())
 _skip.add_theme_font_size_override("font_size",14)
 var plate: StyleBoxFlat=StyleBoxFlat.new();plate.bg_color=Color(0.03,0.06,0.08,0.75)
 plate.set_content_margin_all(8);plate.border_color=Color("536b6b");plate.set_border_width_all(1)
 _skip.add_theme_stylebox_override("normal",plate)
 _skip.pressed.connect(finish)
 _layout();resized.connect(_layout)
func _bar() -> ColorRect:
 var bar: ColorRect=ColorRect.new();bar.color=Color("071018")
 bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(bar);return bar
func _label(font_size: int) -> Label:
 var label: Label=Label.new();label.modulate.a=0;label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 label.add_theme_font_override("font",preload("res://presentation/localized_font.gd").current())
 label.add_theme_font_size_override("font_size",font_size)
 label.add_theme_color_override("font_shadow_color",Color.BLACK)
 label.add_theme_constant_override("shadow_offset_y",2)
 label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 add_child(label);return label
func _layout() -> void:
 _top.size=Vector2(size.x,26)
 _bottom.position=Vector2(0,size.y-68);_bottom.size=Vector2(size.x,68)
 _caption.position=Vector2(size.x*0.08,size.y-55);_caption.size=Vector2(size.x*0.84,50)
 _brand.position=Vector2(size.x*0.06,size.y*0.14);_brand.size=Vector2(size.x*0.88,100)
 _skip.position=Vector2(maxf(0,size.x-140),15)
func _process(seconds: float) -> void:
 if _finished:return
 _elapsed+=seconds
 if stage==null and _elapsed>0.1:finish();return
 if not _stage_started:
  _fade.color.a=1.0-smoothstep(0.0,opening_fade_seconds,_elapsed)
  if _elapsed<opening_fade_seconds:return
  _stage_started=true;stage.set_physics_process(true)
 var time: float=stage.elapsed
 _worlds.present(time)
 var shot: int=0
 for index: int in range(DIRECTION.shot_starts.size()):
  if time>=DIRECTION.shot_starts[index]:shot=index
 var age: float=time-DIRECTION.shot_starts[shot]
 var end: float=DIRECTION.shot_starts[shot+1] if shot+1<DIRECTION.shot_starts.size() else DIRECTION.duration
 _caption.text=tr(DIRECTION.caption_keys[shot])
 _caption.modulate.a=smoothstep(0.3,0.8,age)*(1.0-smoothstep(end-0.55,end,time))
 _brand.modulate.a=smoothstep(DIRECTION.duration-3.3,DIRECTION.duration-2.3,time)
 var cut: float=(1.0-smoothstep(0.0,0.35,age))*0.65 if shot>0 else 0.0
 _fade.color.a=maxf(cut,smoothstep(DIRECTION.duration-DIRECTION.fade_out_seconds,DIRECTION.duration,time))
func finish() -> void:
 if _finished:return
 _finished=true
 if stage!=null:stage.set_physics_process(false)
 completed.emit();queue_free()
func _unhandled_input(event: InputEvent) -> void:
 if not event.is_echo() and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept")):
  get_viewport().set_input_as_handled();finish()
