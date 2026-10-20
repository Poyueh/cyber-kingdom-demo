extends Control
## Local-only audio A/B experiment. Not included in release archives.
const Audio = preload("res://presentation/campaign_audio.gd")
const Campaign = preload("res://application/campaign_session.gd")
const CUES = ["footstep", "work_chop", "bow_shot", "hit", "crystal_land", "wall_hit", "slash1", "pickup"]
var rack: Node
var sim: RefCounted
var status: Label
var running := false
var elapsed := 0.0
var calls := 0
var accepted := 0
var report_at := 0.0
var stopped := false
var mode := ""
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.position=Vector2(24,24);box.size=Vector2(900,470);add_child(box)
	status=Label.new();status.text="Local audio soak: 120 seconds, real game sound rack";box.add_child(status)
	for stream: bool in [false,true]:
		var button:=Button.new()
		button.text="Start STREAM EFFECTS" if stream else "Start SAMPLE EFFECTS (old Web path)"
		button.custom_minimum_size=Vector2(680,70)
		button.pressed.connect(begin.bind(stream))
		box.add_child(button)
	set_process(false)
func begin(stream: bool) -> void:
	if running:return
	mode="stream" if stream else "baseline"
	rack=Audio.new();add_child(rack)
	var playback: int=AudioServer.PLAYBACK_TYPE_STREAM if stream else AudioServer.PLAYBACK_TYPE_SAMPLE
	for voice in rack.voices:voice.playback_type=playback
	for voice in rack.ambience._players.values():voice.playback_type=playback
	for voice in rack.loops._players.values():voice.playback_type=playback
	rack.cue_requested.connect(func(_kind):accepted+=1)
	sim=Campaign.new({"seed":42,"immersive_loop":1})
	sim.frontier.city_level=3
	running=true;set_process(true)
func _process(delta: float) -> void:
	elapsed+=delta
	# One request each rendered frame; the actual rack cooldowns and six voices apply.
	if elapsed<120:
		rack.observe(delta,sim,sim.world.sites.hall,false)
		rack.request(CUES[calls%CUES.size()]);calls+=1
		sim.clock.is_night=int(elapsed/15)%2==1
		sim.workforce.elapsed+=delta
	elif not stopped:
		rack.stop();stopped=true
	if elapsed>=report_at:
		report_at+=5
		var row={"mode":mode,"elapsed":snappedf(elapsed,0.1),"requests":calls,"accepted":accepted,"objects":Performance.get_monitor(Performance.OBJECT_COUNT),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"godot_bytes":OS.get_static_memory_usage(),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"peak_db":AudioServer.get_bus_peak_volume_left_db(0,0),"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,"fps":Performance.get_monitor(Performance.TIME_FPS),"complete":elapsed>=125}
		status.text=JSON.stringify(row,"\n")
		print("AUDIO_SOAK ",JSON.stringify(row))
		if OS.has_feature("web"):JavaScriptBridge.eval("window.CKSoak.receive("+JSON.stringify(row)+")",true)
	if elapsed>=125:running=false;set_process(false)
