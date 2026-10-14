extends OptionButton
const CHOICES=["auto","zh_TW","zh_CN","en"]
var language_service: Node
func _ready() -> void:
 name="LanguageSelector";unique_name_in_owner=true
 theme=preload("res://presentation/refuge_theme.gd").make()
 auto_translate_mode=Node.AUTO_TRANSLATE_MODE_DISABLED
 custom_minimum_size=Vector2(220,44)
 add_theme_font_size_override("font_size",preload("res://data/scene_finish.tres").body_size)
 for label in ["","繁體中文","简体中文","English"]:add_item(label)
 language_service=get_node("/root/GameLanguage")
 language_service.changed.connect(refresh)
 item_selected.connect(func(index):language_service.choose(CHOICES[index]))
 refresh()
func refresh() -> void:
 set_item_text(0,TranslationServer.translate("跟隨系統／平台"))
 select(CHOICES.find(language_service.preference))
 tooltip_text=TranslationServer.translate("語言設定未能保存；本次仍可使用，稍後重新選擇可重試。") if language_service.save_failed else TranslationServer.translate("語言")
