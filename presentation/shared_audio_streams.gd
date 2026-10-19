extends RefCounted
## One stream instance per file and loop setting for the whole run.
## Web exports play streams as samples: each new AudioStream instance is decoded into a full
## WebAudio buffer (about 40 MB for a two-minute track) that the engine cannot release.
## Reloading or duplicating a track therefore grows memory until a phone browser reloads the
## page. Sharing one instance registers every file only once.
static var _streams: Dictionary = {}

static func shared(path: String, loop: bool) -> AudioStream:
	var key := path + ("|loop" if loop else "|once")
	if _streams.has(key): return _streams[key]
	if not ResourceLoader.exists(path): return null
	var stream: AudioStream = load(path)
	if stream is AudioStreamOggVorbis:
		stream = stream.duplicate()
		stream.loop = loop
	elif stream is AudioStreamWAV and loop:
		stream = stream.duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = stream.data.size() / 2
	_streams[key] = stream
	return stream
