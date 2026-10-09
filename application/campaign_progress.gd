extends RefCounted
const Store=preload("res://application/ports/campaign_store.gd")
const Voyage=preload("res://application/star_voyage.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
var store: Store
var codec:=Codec.new()
var status:="new"
var last_error:=""
var last_archive:=""
func _init(adapter: Store) -> void:
	store=adapter
func open() -> Dictionary:
	var result:=store.read()
	if result.status=="missing":
		status="new"
		return {}
	if result.status=="ready":
		var restored: Dictionary=Voyage.restore(result.data) if result.data is Dictionary and result.data.has("format") else codec.restore(result.data)
		if not restored.is_empty():
			status="saved"
			last_error=""
			return restored
	status="protected"
	last_error=store.last_error if result.status!="ready" else (codec.last_error if not codec.last_error.is_empty() else "Invalid or unsupported three-world checkpoint; original retained.")
	return {}
func save(sim, config: Dictionary, body: Dictionary, journey: RefCounted=null) -> bool:
	if status=="protected":return false
	var packet: Dictionary=codec.capture(sim,config,body) if journey==null else journey.capture(sim,body)
	var verified: Dictionary=codec.restore(packet) if journey==null else Voyage.restore(packet)
	if verified.is_empty():
		status="error"
		last_error=codec.last_error
		return false
	if not store.write(packet):
		status="error"
		last_error=store.last_error
		return false
	status="saved"
	last_error=""
	return true
## Only an explicit fresh-start action unlocks an incompatible save.
func archive() -> bool:
	if not store.archive():
		if status!="protected":status="error"
		last_error=store.last_error
		return false
	last_archive=store.last_archive
	status="new"
	last_error=""
	return true
