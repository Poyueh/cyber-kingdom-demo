extends CanvasLayer
## Brief entry dissolve and planet name; never a permanent numeric HUD.
var _shade: ColorRect
var _label: Label
var _tween: Tween
func _ready() -> void:
 layer=90
 _shade=ColorRect.new();_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_shade.color=Color("071019");_shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(_shade)
 _label=Label.new();_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER);_label.position=Vector2(-300,-60);_label.size=Vector2(600,120);_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 _label.add_theme_font_override("font",preload("res://presentation/localized_font.gd").current());_label.add_theme_font_size_override("font_size",30);_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(_label);hide()
func show_arrival(id: int) -> void:
 if _tween!=null:_tween.kill()
 show_notice(tr(preload("res://presentation/star_map.gd").NAMES[id]),tr("planet.arrival"))
func show_notice(title: String, subtitle: String) -> void:
 if _tween!=null:_tween.kill()
 _label.text=title+"\n"+subtitle
 _shade.modulate.a=1;_label.modulate.a=1;show()
 _tween=create_tween();_tween.tween_property(_shade,"modulate:a",0.0,1.3);_tween.tween_interval(1.2);_tween.tween_property(_label,"modulate:a",0.0,1.0);_tween.tween_callback(hide)
