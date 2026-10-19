# 第140課：Web 版的音訊會變成「解壓後的樣本」

手機網頁玩到一半自動重整，通常不是程式呼叫了 reload，而是瀏覽器記憶體用光，系統把分頁砍掉再重開。這次的原因在音樂播放器。

## Godot Web 的樣本播放

到專案設定看 `audio/general/default_playback_type.web`，預設是 **Sample**：網頁版沒有執行緒時，Godot 把每個要播的 AudioStream 整段解壓，交給瀏覽器的 WebAudio 當作一段緩衝來播。兩分鐘的 44.1 kHz 立體聲音樂，解壓後大約 40 MB。

重點是「每個 AudioStream 實例」都算一次：
- `load(path)` 如果原本那份已被釋放，會回傳新的實例。
- `stream.duplicate()` 一定是新的實例。

而這版 Godot 只提供 `AudioServer.register_stream_as_sample()`，沒有解除註冊的 API。舊實例的緩衝留在瀏覽器裡，新的又再解壓一份。

## 量測，而不是猜

我做了兩個只有音樂播放器的小網頁，用 `FinalizationRegistry` 監看瀏覽器建立和回收的 AudioBuffer：

| 切換 50 次 | 舊做法（逐出後重載＋duplicate） | 新做法（共用實例） |
|---|---|---|
| 尚未回收的音訊 | 1252 MB，持續上升 | 約 270 MB，持平 |
| JS 記憶體 | 1470 MB，持續上升 | 約 352 MB，持平 |

原生版跑 30 分鐘、8 個日夜，記憶體一直是 280 MB 左右——問題只在 Web 才看得到，所以一定要在瀏覽器裡量。

## 修法：整個執行期間只建立一份

`presentation/shared_audio_streams.gd` 用 `static var` 保存「檔案＋是否循環」對應的那一份實例：

```gdscript
static var _streams: Dictionary = {}

static func shared(path: String, loop: bool) -> AudioStream:
	var key := path + ("|loop" if loop else "|once")
	if _streams.has(key): return _streams[key]
	...
```

`static var` 屬於腳本本身，不屬於某個節點，所以換場景、重建播放器都會拿到同一份。音樂、環境音、循環音效都改從這裡取。`preload()` 的常數本來就只有一份，音效不用改。

規範也寫進 `docs/agents/gdscript-standards.md`：執行中不要 `duplicate()` 或重新 `load()` 音訊串流。
