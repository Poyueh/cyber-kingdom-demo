# 音效與音樂 v002 生成與驗收報告

日期 2026-09-23。本輪只做素材生成與檢查（計畫的 P0），**尚未接進遊戲**：目前遊戲執行時仍播放 v001 的舊素材。接線是下一輪 P1／P2 的工作，依計畫要等音色獲得認可才動。

## 產出

| 類別 | 檔數 | 位置 | 格式 | 容量 |
| --- | --- | --- | --- | --- |
| 音效 | 100 | `art/audio/campaign-v002/` | WAV 16-bit mono 44.1 kHz | 4.5 MB |
| 環境音循環 | 7 | `art/audio/ambience-v002/` | OGG Vorbis mono 44.1 kHz | 1.1 MB |
| 音樂 | 9 | `art/audio/music-v002/` | OGG Vorbis stereo 44.1 kHz | 13 MB |

音效的 100 個檔來自 72 條設計項目，其中 14 條高頻率重播的聲音（揮劍、命中、腳步、拾取、伐木、採礦、敲擊、收割、敵人揮擊、城牆受擊、龍晶落地）各生 3 個變體，避免連續播放時聽起來像機關槍。

全部素材由 ElevenLabs 依 prompt 生成，沒有錄音、取樣或第三方音源。每個檔的完整 prompt、請求參數、SHA-256 與量測值記在各素材目錄的 `provenance.json`；人類可讀的對照表在 `docs/design/campaign-audio-v002-catalogue.md`。

## 試聽

- `audition-sfx.mp3`：100 個音效依序播放，約 111 秒。
- `audition-ambience.mp3`：7 段環境音，約 142 秒。
- `audition-music.mp3`：9 首音樂各取前 25 秒，約 198 秒。
- `audition-index.json`：每個素材在試聽檔中的起始秒數，聽到不對的可以直接對回檔名。

## 音量檢查（實測，全部通過）

| 類別 | 標準 | 實測 |
| --- | --- | --- |
| 音效 | 峰值 -6.0 dBFS | 100 個檔全部 -6.00 dBFS |
| 環境音 | -30 LUFS 感知響度 | -30.9 至 -30.0 LUFS |
| 音樂 | -16 LUFS 感知響度 | -16.8 至 -15.9 LUFS |

另外檢查並全部通過：取樣率 44.1 kHz、聲道數、零削波樣本、沒有近乎無聲的檔、音效長度不超過設計值、循環素材的接點沒有跳變。完整數據在 `measurements.json`，重跑指令 `python3 tools/verify_audio_v002.py`。

環境音與音樂改用感知響度而非峰值對齊，因為像營火這種稀疏爆裂的素材峰值拉到位時整體會太小聲。第一版用峰值對齊時營火只有 -44 LUFS，幾乎聽不見。

## 人聲檢查（無人聲，附對照驗證）

需求是全器樂音樂與無人聲音效。用兩個獨立方法檢查：

1. **逐檔語音辨識**。116 個檔全部送 ElevenLabs Scribe 辨識，**辨識出的字詞數全部為 0**。為了證明這個檢查有鑑別力，另外用「女聲主唱、完整英文歌詞」的 prompt 生了一段對照樣本，同一個辨識器抓出 26 個字的完整歌詞。對照組與結果記在 `voice-screen-control.json` 與 `voice-screen.json`，重跑指令 `python3 tools/check_audio_voice_v002.py`。
2. **頻譜目視比對**。`spectrogram-control-with-vocals.png` 是已知含人聲的對照圖，可看到人聲特有的音節分段與會擺動的諧波堆疊。`spectrogram-music.png` 與 `spectrogram-ambience.png` 把我們的素材排在同一張對照，沒有出現該特徵；環境音都是連續的寬頻紋理。

限制要說清楚：語音辨識抓的是「字」，無詞的哼唱或唱詩班式的 ooh／aah 有可能漏掉；頻譜目視也無法百分之百區分帶顫音的獨奏樂器與人聲。**最終仍以實際試聽為準。**

過程中曾寫過一版用訊號特徵猜人聲的啟發式評分，用對照組一驗就發現它把真人聲評為 0.562、卻把我們的純器樂曲評到 0.74，完全沒有鑑別力，已刪除不採用。

## 生成過程中修正的問題

- **提示詞長度上限 450 字元**。第一版加密環境音描述後超標被 API 退件，改用較短的環境音共用後綴，並在 manifest 加入長度檢查，超標直接報錯而不是靜默截斷。
- **環境音太稀疏**。營火、森林、夜晚三段第一次生成後大半時間近乎無聲，改用強調「連續、不間斷」的 prompt 重生。
- **本機 ffmpeg 沒有 libvorbis**。改用 `oggenc`（vorbis-tools）編碼 OGG，Godot 才能把它當可無縫循環的串流匯入。

## 重現方式

```bash
export ELEVENLABS_API_KEY=...
python3 tools/generate_audio_v002.py --raw-dir <暫存目錄>
python3 tools/process_audio_v002.py --raw-dir <暫存目錄>   # 需要 numpy、ffmpeg、oggenc
python3 tools/verify_audio_v002.py
python3 tools/check_audio_voice_v002.py
python3 tools/write_audio_docs_v002.py
```

原始未處理的回應留在暫存目錄，沒有進版控；prompt 與 SHA-256 已足以重現與追溯。

## 下一步

1. 使用者與 PO 依試聽檔確認音色，逐條回報要改的項目。
2. 要改的就改 `tools/audio_v002_manifest.py` 的 prompt，刪掉該檔的暫存原始檔後重跑上面五個指令。
3. 音色定案後才進 P1：新增音訊 bus、播放器換讀 v002、音樂狀態機；接著 P2 補接目前沒有聲音的事件。細節見 `docs/design/campaign-audio-v002-plan.md`。
