extends Control
## Cinema presentation. Bootstrap supplies an isolated stage; this view owns no saves.
signal completed
var stage: Node
var _elapsed: float=0.0
var _finished: bool=false
var _viewport: SubViewport
var _caption: Label
var _skip: Button
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
 _caption=Label.new();add_child(_caption)
 _caption.add_theme_font_override("font",preload("res://presentation/localized_font.gd").current())
 _caption.add_theme_font_size_override("font_size",24)
 _caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 _caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 _skip=Button.new();_skip.text=tr("跳過前導");_skip.custom_minimum_size=Vector2(120,42);add_child(_skip)
 _skip.add_theme_font_override("font",preload("res://presentation/localized_font.gd").current())
 _skip.pressed.connect(finish)
 _layout();resized.connect(_layout)
func _layout() -> void:
 _caption.position=Vector2(size.x*0.08,size.y-72);_caption.size=Vector2(size.x*0.84,56)
 _skip.position=Vector2(maxf(0,size.x-140),15)
func _process(seconds: float) -> void:
 if _finished:return
 _elapsed+=seconds
 if stage==null and _elapsed>0.1:finish();return
 var time: float=stage.elapsed
 var text: String="最後一縷火光。" if time<10 else "守住它。" if time<18 else "直到黎明。"
 _caption.text=tr(text)
 var start: float=0 if time<10 else 10 if time<18 else 18
 _caption.modulate.a=smoothstep(1,2,time-start)
func finish() -> void:
 if _finished:return
 _finished=true
 if stage!=null:stage.set_physics_process(false)
 completed.emit();queue_free()
func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
  get_viewport().set_input_as_handled();finish()
