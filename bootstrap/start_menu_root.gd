extends Control
const Catalog=preload("res://infrastructure/campaign_catalog.gd")
const Store=preload("res://infrastructure/json_campaign_store.gd")
const Record=preload("res://application/campaign_record.gd")
const Progress=preload("res://application/campaign_progress.gd")
@export var campaigns_directory: String="user://campaigns"
@export var legacy_path: String="user://campaign_v1.json"
var catalog: RefCounted
var rows: Array[Dictionary]=[]
var _launching:=false
@onready var view=$Menu
func _ready() -> void:
	catalog=Catalog.new(campaigns_directory,legacy_path)
	view.new_game_requested.connect(start_new_game)
	view.records_requested.connect(show_records)
	view.record_selected.connect(select_record)
	if not get_tree().has_meta("campaign_prologue_seen"):
		get_tree().set_meta("campaign_prologue_seen",true)
		view.hide()
		var prologue=preload("res://presentation/campaign_prologue.gd").new()
		add_child(prologue)
		prologue.completed.connect(func():view.show())

func show_records() -> void:
	rows.clear()
	for entry in catalog.entries():
		var row: Dictionary=entry.duplicate()
		row.merge(Record.describe(Store.new(entry.path)))
		row.date=Time.get_datetime_string_from_unix_time(entry.updated).replace("T"," ")+" UTC"
		rows.append(row)
	view.show_records(rows)

func start_new_game() -> void:
	if _launching:return
	var path: String=catalog.allocate()
	if path.is_empty():view.show_error(catalog.last_error);return
	_launch(path,int(randi()%1000000000))

func select_record(index: int) -> void:
	if _launching or index<0 or index>=rows.size():return
	var row: Dictionary=rows[index]
	# Re-read on selection; listing never grants permission to overwrite damaged saves.
	var progress=Progress.new(Store.new(row.path))
	var restored: Dictionary=progress.open()
	if restored.is_empty():view.show_error("紀錄無法讀取，原檔已保留。請重新選擇。 ");return
	var path: String=row.path
	if row.manual:
		path=catalog.allocate()
		if path.is_empty():view.show_error(catalog.last_error);return
		var fork=Progress.new(Store.new(path));fork.open()
		if not fork.save(restored.session,restored.config,restored.body):
			view.show_error("無法另存檢查點，原紀錄未變更。請稍後重試。 ");return
	_launch(path)

func _launch(path: String, seed_value: int=-1) -> void:
	_launching=true
	get_tree().set_meta("campaign_launch",{"path":path,"seed":seed_value})
	get_tree().call_deferred("change_scene_to_file","res://scenes/frontier.tscn")
