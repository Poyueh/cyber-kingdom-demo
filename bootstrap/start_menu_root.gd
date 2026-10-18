extends Control
const Catalog=preload("res://infrastructure/campaign_catalog.gd")
const Store=preload("res://infrastructure/json_campaign_store.gd")
const Record=preload("res://application/campaign_record.gd")
const Progress=preload("res://application/campaign_progress.gd")
const AudioPreferences=preload("res://infrastructure/audio_preferences.gd")
const TitleAudio=preload("res://presentation/title_audio.gd")
@export var campaigns_directory: String="user://campaigns"
@export var legacy_path: String="user://campaign_v1.json"
@export var audio_preferences_path: String="user://audio.cfg"
var catalog: RefCounted
var rows: Array[Dictionary]=[]
var _launching:=false
var audio: Node
var _prologue: Control
var _ambience_level: float=0.6
@onready var view=$Menu
func _ready() -> void:
	if preload("res://infrastructure/distribution.gd").demo():
		campaigns_directory="user://forest_demo_campaigns";legacy_path=""
	catalog=Catalog.new(campaigns_directory,legacy_path)
	audio=TitleAudio.new()
	audio.name="TitleAudio"
	add_child(audio)
	var levels: Dictionary=AudioPreferences.LEVELS.duplicate()
	levels.muted=false
	if not audio_preferences_path.is_empty():
		levels=AudioPreferences.new(audio_preferences_path).read()
	audio.apply(levels)
	_ambience_level=float(levels.ambience)
	view.new_game_requested.connect(start_new_game)
	view.core_game_requested.connect(func()->void:start_new_game(0,true))
	view.records_requested.connect(show_records)
	view.record_selected.connect(select_record)
	view.prologue_requested.connect(show_prologue)
	if not get_tree().has_meta("campaign_prologue_seen"):
		get_tree().set_meta("campaign_prologue_seen",true)
		show_prologue()

func show_prologue() -> void:
	if is_instance_valid(_prologue) or _launching:return
	view.hide();audio.suspended=true
	_prologue=preload("res://presentation/campaign_prologue.gd").new()
	_prologue.stage=preload("res://bootstrap/prologue_stage.gd").new()
	var levels: Dictionary={"music":audio.music.volume,"effects":audio.effects_volume,"ambience":_ambience_level,"muted":not audio.enabled}
	_prologue.stage.sound_levels=levels
	add_child(_prologue)
	_prologue.completed.connect(func() -> void:
		_prologue=null
		audio.suspended=false
		view.reveal())

func show_records() -> void:
	audio.click("ui_select")
	rows.clear()
	for entry in catalog.entries():
		var row: Dictionary=entry.duplicate()
		row.merge(Record.describe(Store.new(entry.path)))
		if preload("res://infrastructure/distribution.gd").demo() and not row.get("core",false) and not row.get("forest_demo",false):continue
		row.date=Time.get_datetime_string_from_unix_time(entry.updated).replace("T"," ")+" UTC"
		rows.append(row)
	view.show_records(rows)

func start_new_game(pace: int=0, core: bool=false) -> void:
	if _launching:return
	# The Demo starts the contained full forest; the old two-night trial is kept only for its saves.
	if preload("res://infrastructure/distribution.gd").demo():core=false
	if preload("res://data/journey_paces.tres").find(pace)==null:return
	audio.click("ui_confirm")
	var path: String=catalog.allocate()
	if path.is_empty():view.show_error(catalog.last_error);return
	_launch(path,int(randi()%1000000000),pace,core)

func select_record(index: int) -> void:
	if _launching or index<0 or index>=rows.size():return
	audio.click("ui_confirm")
	var row: Dictionary=rows[index]
	# Re-read on selection; listing never grants permission to overwrite damaged saves.
	var progress=Progress.new(Store.new(row.path))
	var restored: Dictionary=progress.open()
	if restored.is_empty() or not preload("res://infrastructure/distribution.gd").accepts(restored):view.show_error("紀錄無法讀取，原檔已保留。請重新選擇。 ");return
	var path: String=row.path
	if row.manual:
		path=catalog.allocate()
		if path.is_empty():view.show_error(catalog.last_error);return
		var fork=Progress.new(Store.new(path));fork.open()
		if not fork.save(restored.session,restored.config,restored.body,restored.get("journey")):
			view.show_error("無法另存檢查點，原紀錄未變更。請稍後重試。 ");return
	_launch(path)

func _launch(path: String, seed_value: int=-1, pace: int=0, core: bool=false) -> void:
	_launching=true
	get_tree().set_meta("campaign_launch",{"path":path,"seed":seed_value,"pace":pace,"core":core})
	get_tree().call_deferred("change_scene_to_file","res://scenes/frontier.tscn")
