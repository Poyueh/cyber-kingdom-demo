# 戰役音效與音樂 v002 全面重製計畫（已完成）

> 狀態：全部完成（2026-09-23）。P0 生成 116 個素材，P1 到 P5 已接進遊戲，72 種音效全部有觸發點。
> 現行規格見 `campaign-audio-v002.md`，逐條 prompt 見 `campaign-audio-v002-catalogue.md`，生成與驗收見 `docs/reports/campaign-audio-v002/README.md`。
> v001 的 16 個合成短音與 1 首合成循環曲全部視為佔位，本輪整批替換。
> 本文是「要生哪些聲音、用什麼 prompt 生、生完怎麼接」的總表；技術規格、接線與測試分階段列在末段。

## 1. 目標與邊界

- 用 AI 音訊生成工具（音效：文字轉音效；音樂：文字轉音樂）重新製作全部音效與配樂，取代 `tools/generate_campaign_sounds.py` 與 `generate_frontier_music.py` 的數學合成產物。
- 補齊 v001 沒有聲音的核心事件：龍晶出袋、掉劍／撿劍、營火受擊警示、巨龍降臨與吐火、傳送門湧怪、部件拾取／裝備、投滿格完成、日出、夜襲預告、封印累積。
- 新增環境音層（白天荒地、夜晚、營火、晶脈、遺跡）與 UI 音效。
- 配樂從單一循環改為「狀態切換」：起始頁、白天探索、營地、夜晚守備、夜襲、巨龍決戰，加上勝利／敗北／日出短樂句。
- 不改：戰鬥數值、付款時機、存檔格式、domain／application 分層。音訊仍全部在 presentation，偏好檔在 infrastructure。
- 不做：語音、旁白、人聲歌詞。不做 8-bit chiptune（已否定的 8-bit 風格同樣不適用於聲音）。

## 2. 聲音風格定義（所有 prompt 的共同基底）

畫風是「Kingdom 品質的中等細緻像素 + 霓虹古城」：黑鋼機械支架、青綠龍晶反應爐、洋紅符文投影，底下仍是石城、森林、巨龍與劍。聲音要對得上這三層：

| 層 | 畫面對應 | 聲音素材語彙 |
| --- | --- | --- |
| 中古有機層 | 石城、木牆、營火、森林、居民工具 | 木頭、石頭、皮革、火焰、風、鳥、蟲、鐘、弦樂、木管 |
| 龍晶魔法層 | 青綠龍晶、符文、封印、殘影 | 玻璃質晶體、清亮泛音、共鳴 sine、緩慢 pad、微微失諧的鐘聲 |
| 黑鋼機械層 | 義肢、鎧甲、護民塔、反應爐、戰馬 | 伺服馬達、液壓、鋼板、低頻嗡鳴、電容放電 |

共同規則，寫進每個 prompt 的結尾：

- 英文 prompt 基底句：`stylized retro pixel-art action game sound, clean and punchy, dry with minimal reverb, no music, no voice, mono-compatible`
- 音效要「短、乾、辨識度高」，手機喇叭也聽得出來；避免電影級大混響與長尾。
- 音樂要「空曠、憂鬱、克制」，Kingdom 式的靜謐，不要史詩管弦大合奏，不要人聲。
- 敵人與巨龍是「魔法生物 + 非人」，不用真實動物錄音感，要有龍晶共鳴感。
- 騎士所有動作帶一點金屬義肢感，但劍是真劍，刃聲要乾淨。

英文負面詞（工具支援時附上）：`no chiptune, no 8-bit bleeps, no orchestral epic swell, no vocals, no lyrics, no reverb tail, no cinematic trailer hit`

## 3. 技術規格

| 項目 | 音效 | 環境音 | 音樂 |
| --- | --- | --- | --- |
| 格式 | WAV 16-bit mono | OGG Vorbis mono | OGG Vorbis stereo |
| 取樣率 | 44,100 Hz | 44,100 Hz | 44,100 Hz |
| 長度 | 0.1–1.5 s（短樂句除外） | 20–40 s 無縫循環 | 60–150 s 無縫循環；短樂句 5–20 s |
| 音量 | 峰值 -6 dBFS，再由程式 volume_db 控 | -30 LUFS，峰值上限 -9 dBFS | -16 LUFS，峰值上限 -6 dBFS |

實作時的修正：環境音與音樂改用感知響度（LUFS）對齊而非峰值。稀疏的爆裂型素材（營火）峰值拉到位時整體會太小聲，第一版只有 -44 LUFS。另外 ElevenLabs 的音效 prompt 有 450 字元上限，環境音改用較短的共用後綴，manifest 會擋超標。
| 命名 | `art/audio/campaign-v002/<kind>.wav` | `art/audio/ambience-v002/<name>.ogg` | `art/audio/music-v002/<name>.ogg` |
| 來源紀錄 | 每個目錄一份 `provenance.json`：工具、模型版本、完整 prompt、生成日期、裁剪／正規化參數 | 同 | 同 |

- 需要「多變體」的音效（腳步、揮劍、命中、工具）每種生 3 個，接線時隨機輪播，避免機關槍感。
- 生成後統一後處理：去頭尾靜音、淡入 2 ms 淡出 10 ms、正規化。後處理腳本放 `tools/normalize_audio.py`（僅裁剪與增益，不合成）。
- 新增 Godot bus layout `default_bus_layout.tres`：Master → Music / SFX / Ambience / UI。音量偏好從兩條（音樂／音效）擴成三條（音樂／音效／環境），UI 跟 SFX 走同一條偏好。

## 4. 音效清單與 prompt

格式說明：`檔名` — 中文用途 · 建議長度 · 接線狀態（既有＝v001 已有此事件觀察；新＝要在觀察器加對應；變體＝生 3 個）。
每條 prompt 結尾請自行補上第 2 節的基底句與負面詞，這裡不重複。

### 4.1 騎士戰鬥

- `slash1.wav` — 第一刀斜向拔切，站定出刀 · 0.3 s · 既有 · 變體
  Prompt: `Quick steel sword draw-cut slicing diagonally through air, sharp bright whoosh with a thin metallic ring at the start, tight and fast, medieval longsword`
- `slash2.wav` — 第二刀反手回斬，踏進 · 0.3 s · 既有 · 變體
  Prompt: `Backhand sword sweep whoosh, slightly lower pitch than a draw cut, wider arc, brief leather-and-armor rustle underneath, fast recovery`
- `slash3.wav` — 第三刀跨步穿刺，收招 · 0.4 s · 既有 · 變體
  Prompt: `Lunging sword thrust, focused narrow air-cut whoosh ending in a short steel shimmer, heavier footfall of a metal prosthetic leg planting on dirt`
- `hit.wav` — 一般命中敵人 · 0.25 s · 既有 · 變體
  Prompt: `Sword blade striking a magical creature, crunchy mid-frequency impact with a short crystalline crack, satisfying and punchy, no gore`
- `heavy.wav` — 重擊命中（第三刀、營火核心受擊借用需分開，見 4.3） · 0.35 s · 既有
  Prompt: `Heavy sword impact with deep low thud and a splintering crystal shatter layer, strong transient, brief sub-bass punch`
- `hurt.wav` — 騎士受傷、龍晶或生命損失 · 0.4 s · 既有
  Prompt: `Armored knight taking a hit, metal plate clang mixed with a short glassy crystal crack and a small servo stutter, painful but not screaming`
- `shield.wav` — 護盾吸收，生命未降 · 0.3 s · 新（v001 與 hurt 共用，拆開）
  Prompt: `Teal energy shield deflecting a blow, quick electric shimmer with a soft resonant hum, glassy and cool, deflection rather than damage`
- `dash.wav` — 義肢充能衝刺 · 0.35 s · 既有
  Prompt: `Mechanical prosthetic leg burst dash, quick hydraulic hiss then a short electric capacitor discharge zap, forward-moving air rush`
- `charge_empty.wav` — 體力／充能不足，動作未發動 · 0.2 s · 新
  Prompt: `Depleted capacitor click, dry electric tick followed by a tiny failing fizzle, small and unsatisfying, indicates no power`
- `crystal_drop.wav` — 受擊掉出龍晶（出袋） · 0.5 s · 新（觀察 CrystalPouch 受擊後新增的掉落晶體；`crystal_sink` 是入袋吸收效果，不是出袋）
  Prompt: `Several small glowing crystals spilling out of a leather pouch and scattering on dirt, glassy tinkling with a soft pouch flap, loss and scatter`
- `sword_drop.wav` — 空袋受擊掉劍 · 0.6 s · 新
  Prompt: `Steel longsword knocked from a hand, clattering and bouncing once on stone ground then settling, heavy metallic ring, ominous`
- `sword_recover.wav` — 撿回劍 · 0.4 s · 新（事件 `sword_recovered`）
  Prompt: `Picking a sword up from the ground and gripping it, short steel scrape and a confident metallic ring as the blade rises, restored`
- `death.wav` — 騎士倒地死亡 · 1.0 s · 新（目前只有 defeat 樂句）
  Prompt: `Armored knight collapsing to the ground, heavy plate armor thud, prosthetic servos powering down with a descending whine, crystal core light fading with a soft resonant decay`
- `footstep.wav` — 跑步腳步，金屬義肢踩土 · 0.15 s · 新 · 變體
  Prompt: `Single footstep of a metal prosthetic boot on packed dirt and grass, short and crisp, faint servo click, no reverb`
- `footstep_slow.wav` — 慢移腳步 · 0.2 s · 新 · 變體
  Prompt: `Single careful footstep of a heavy armored boot on dirt, softer and slower than a run, slight leather creak`
- `horse_gallop.wav` — 龍晶戰馬奔馳循環 · 1.2 s 循環 · 新（騎乘）
  Prompt: `Mechanical crystal-powered warhorse galloping loop, rhythmic metal hooves on dirt with a low crystalline engine hum, four-beat cycle, seamless loop`
- `mount.wav` — 上馬一次 · 0.6 s · 新
  Prompt: `Knight mounting a mechanical warhorse, armor shifting, saddle clunk, and a rising crystal engine hum settling into idle`

### 4.2 龍晶與經濟

- `pickup.wav` — 龍晶飛入背包 · 0.2 s · 既有 · 變體（事件 `crystal_pickup`；`crystal_sink` 是同一次入袋的吸收殘影，不另發聲）
  Prompt: `Small glowing crystal shard flying into a leather pouch, quick ascending glassy chime with a soft leather tap at the end, light and rewarding`
- `pay.wav` — 投入一顆龍晶到格子 · 0.25 s · 既有
  Prompt: `Placing a glowing crystal into a metal socket, short glass-on-steel click followed by a brief teal energy hum engaging, deliberate and precise`
- `slot_complete.wav` — 投滿格，互動執行 · 0.5 s · 新
  Prompt: `A row of crystal sockets completing, quick rising three-note glassy arpeggio resolving into a warm resonant confirmation, magical machinery locking in`
- `slot_refund.wav` — 未填滿逾時退回 · 0.4 s · 新
  Prompt: `Crystals being released from sockets and dropping back to the ground, descending glassy tinkle with a soft mechanical unlatch, gentle disappointment`
- `throw.wav` — 拋晶 · 0.3 s · 新（Q／下滑丟晶）
  Prompt: `Tossing a small crystal through the air, quick swish with a faint shimmering trail, light and airy`
- `crystal_land.wav` — 龍晶落地彈跳 · 0.3 s · 新 · 變體
  Prompt: `Small hard crystal landing on dirt and bouncing once, short glassy tick and a muted thud, tiny`
- `chest.wav` — 寶箱開啟噴出龍晶 · 0.8 s · 既有（事件 `chest_burst`）
  Prompt: `Old iron-banded wooden chest bursting open, wood creak and metal latch snap, then a shower of glowing crystals spraying outward with bright glassy sparkle`
- `heal.wav` — 付晶治療 · 0.6 s · 新
  Prompt: `Healing energy flowing from a crystal into an armored body, warm ascending resonant hum with soft servo re-engaging sounds, restoration`
- `module_pickup.wav` — 拾取機械部件 · 0.3 s · 新
  Prompt: `Picking up a small mechanical component, metallic clink and a short servo chirp, compact gadget`
- `module_equip.wav` — 改造所裝備部件 · 0.7 s · 新
  Prompt: `Attaching a mechanical module to armored prosthetic back mounts, two metal latches clicking in sequence then a hydraulic seal hiss and a brief power-up hum`
- `module_store.wav` — 部件收納 · 0.3 s · 新
  Prompt: `Placing a mechanical part into a padded storage rack, soft metal clunk and a fabric rustle, quiet and tidy`
- `handoff.wav` — 工匠把採集龍晶交給騎士 · 0.4 s · 新
  Prompt: `A handful of crystals passed from one leather pouch into another, gentle glassy cascade with two soft pouch taps, friendly exchange`

### 4.3 避難所、居民、防線

- `recruit.wav` — 流浪者加入 · 0.7 s · 既有（事件 `recruited`）
  Prompt: `A wanderer joining the refuge, warm short two-note bell motif with a faint crystal shimmer, hopeful and humble`
- `build.wav` — 施工完成 · 0.7 s · 既有（事件 `construction_done`）
  Prompt: `Wooden and steel structure finishing construction, final hammer strike on a beam, timber settling, and a brief teal energy conduit powering on`
- `upgrade.wav` — 聚落升級（王城一→二→三級） · 1.2 s · 新（v001 與 build 共用，拆開）
  Prompt: `A settlement growing to a new tier, deep stone shift and rising mechanical machinery, then a resonant crystal reactor tone blooming outward, ceremonial and grounded`
- `ignition.wav` — 拔劍點火建國（開局） · 1.5 s · 新（事件 `camp_ignition`，v001 借用 seal）
  Prompt: `Sword raised and plunged into a campfire, sharp steel ring, sparks crackling, flames roaring up, then a deep resonant crystal hum awakening as the refuge is founded`
- `tool_pickup.wav` — 居民取器具就職 · 0.4 s · 新
  Prompt: `Resident grabbing a work tool from a wooden rack, wooden handle knock and a short leather strap tightening, purposeful`
- `work_chop.wav` — 工匠伐木 · 0.3 s · 新 · 變體 · 遠處衰減
  Prompt: `Single axe chop into a living tree trunk, dry woody thock with a little bark splinter, distant-friendly`
- `work_mine.wav` — 工匠採礦 · 0.3 s · 新 · 變體 · 遠處衰減
  Prompt: `Pickaxe striking crystal-bearing rock, stone crack with a bright glassy overtone, single strike`
- `work_hammer.wav` — 施工敲擊 · 0.25 s · 新 · 變體 · 遠處衰減
  Prompt: `Hammer striking a wooden beam with an iron nail, single sharp knock, construction`
- `work_harvest.wav` — 農夫收割／採果／採藥 · 0.3 s · 新 · 變體
  Prompt: `Sickle cutting through crop stalks and leaves, soft swish and rustle, single stroke`
- `bow_shot.wav` — 獵人／弓兵放箭 · 0.3 s · 新（事件 `bolt`、`tower_arrow`）
  Prompt: `Wooden longbow releasing an arrow, string twang and a fast feathered whistle, short`
- `arrow_hit.wav` — 箭矢命中 · 0.2 s · 新
  Prompt: `Arrow striking a magical creature, quick thock with a small crystal crack, small impact`
- `tower_laser.wav` — 護民塔龍晶射線 · 0.5 s · 新（v001 借用 dash）
  Prompt: `Crystal-powered defense tower firing a teal energy beam, sharp charged zap with a brief resonant sustain, futuristic but grounded in a stone tower`
- `wall_hit.wav` — 城牆受擊 · 0.35 s · 新 · 變體
  Prompt: `Wooden palisade wall being struck by a creature, heavy timber thud and creak, planks rattling`
- `wall_break.wav` — 城牆倒塌 · 1.0 s · 新
  Prompt: `Wooden and stone barricade collapsing, cracking beams, tumbling stones, and a dying crystal conduit fizzle, alarming`
- `wall_repair.wav` — 城牆修復完成 · 0.5 s · 新
  Prompt: `Wall being repaired, quick hammer taps and a beam sliding into place with a wooden clunk, reassuring`
- `core_hit.wav` — 營火核心受擊警示 · 0.6 s · 新（事件 `core_hit`，v001 借用 heavy）
  Prompt: `The heart of the refuge taking damage, deep crystal reactor impact with a low pulsing alarm throb and flames flaring, urgent, felt in the chest`
- `resident_hit.wav` — 居民受擊退回流浪者 · 0.5 s · 新
  Prompt: `A villager struck and dropping their tool, short gasp-like breath (no words), wooden tool clattering to the ground, sad and small`
- `farewell.wav` — 龍晶殘影完成引導後告別離場 · 0.6 s · 新（事件 `farewell`，來自 spirit_guidance）
  Prompt: `A faint presence leaving, soft descending crystal shimmer fading into wind, gentle and melancholic`

### 4.4 敵人與巨龍

- `portal_spawn.wav` — 地獄之門湧出敵人 · 0.8 s · 新（事件 `portal_spawn`）
  Prompt: `A magical portal spitting out a creature, low magenta energy surge with a wet tearing rip and a short rising distortion, unsettling`
- `enemy_telegraph.wav` — 敵人攻擊預警 · 0.4 s · 新
  Prompt: `Creature winding up an attack, rising guttural crystalline growl with a short inhale-like swell, warning cue, clearly readable`
- `enemy_attack.wav` — 敵人揮擊 · 0.3 s · 新 · 變體
  Prompt: `Clawed creature swiping, fast heavy whoosh with a scraping edge, aggressive`
- `enemy_death.wav` — 小怪倒下消散 · 0.7 s · 新
  Prompt: `Magical creature collapsing and dissolving into crystal dust, brief body thud then a fizzing glassy disintegration fading upward`
- `enemy_grab.wav` — 小怪抱走一顆龍晶撤退 · 0.4 s · 新
  Prompt: `Creature snatching a glowing crystal and fleeing, quick grab rustle, a muffled glassy chime, and scurrying steps moving away`
- `gatekeeper_appear.wav` — 守門者出現 · 1.2 s · 新
  Prompt: `A large armored guardian creature emerging, heavy stone-grinding steps, deep resonant crystal roar, imposing but not cinematic`
- `dragon_arrival.wav` — 最終巨龍降臨 · 2.5 s · 新（事件 `dragon_arrival`）
  Prompt: `Colossal dragon descending from the sky, massive slow wingbeats pushing air, ground-shaking landing thud, and a deep layered roar with a crystalline magical resonance, the last boss arrives`
- `dragon_wing.wav` — 巨龍振翅循環 · 1.5 s 循環 · 新
  Prompt: `Giant leathery dragon wings beating slowly, deep air whoomp per beat, seamless two-beat loop`
- `dragon_fire.wav` — 巨龍吐火 · 1.5 s · 新（事件 `dragon_fire`）
  Prompt: `Dragon breathing a torrent of magical fire, sharp ignition burst then a roaring sustained flame jet with a crackling crystal-charged undertone, decaying at the end`
- `dragon_hurt.wav` — 巨龍受擊 · 0.6 s · 新
  Prompt: `Dragon taking a sword hit, deep pained roar with a cracking scale impact, heavy`
- `dragon_death.wav` — 巨龍倒下 · 3.0 s · 新
  Prompt: `Colossal dragon collapsing, long groaning roar falling in pitch, massive body impact on the ground, then a slow crystal resonance dissolving into silence`

### 4.5 日夜與戰役進度

- `night.wav` — 入夜 · 1.2 s · 既有
  Prompt: `Nightfall in a haunted frontier, low wind swell with a distant unsettling crystal drone and a single deep bell, foreboding`
- `dawn.wav` — 日出，顯示天數 · 1.5 s · 新
  Prompt: `Dawn breaking after a survived night, warm rising pad with a soft bright bell and a few distant birds, relief, short`
- `raid_warning.wav` — 日落前 30 秒方向預告 · 0.8 s · 新
  Prompt: `Warning horn from a wooden watchtower, short low horn blast with a slight crystal shimmer, alert but not panicked`
- `seal_progress.wav` — 封印累積循環（8 秒） · 2.0 s 循環 · 新
  Prompt: `Magical seal charging loop, slow pulsing crystal hum rising in intensity with soft rune-like glassy ticks, seamless loop, building anticipation`
- `seal.wav` — 封印完成 · 1.5 s · 既有
  Prompt: `Ancient portal sealing shut, heavy stone grinding closed, a deep magical lock thud, then a bright crystalline resolve chord, triumphant and final`
- `kingdom.wav` — 王國建立里程碑 · 2.0 s · 新（可選）
  Prompt: `Kingdom founded milestone, three ascending bell tones with a warm resonant crystal chord blooming, ceremonial, grounded`
- `victory.wav` — 通關勝利短句 · 3.0 s · 既有
  Prompt: `Victory fanfare for a small pixel-art kingdom, short bright bell and brass-like crystal motif over a warm pad, triumphant yet humble, ends cleanly`
- `defeat.wav` — 敗北短句 · 3.0 s · 既有
  Prompt: `Defeat motif, slow descending bell phrase over a fading cold pad with a dying mechanical hum, mournful, ends cleanly`

### 4.6 UI

- `ui_pause.wav` — 開啟暫停 · 0.25 s · 新
  Prompt: `Soft mechanical UI open, gentle metal latch click with a short teal shimmer, clean`
- `ui_resume.wav` — 關閉暫停／繼續 · 0.25 s · 新
  Prompt: `Soft mechanical UI close, reverse latch click, quick and clean`
- `ui_select.wav` — 選單移動／滑桿刻度 · 0.1 s · 新
  Prompt: `Tiny crystal tick for menu navigation, very short bright glassy click`
- `ui_confirm.wav` — 確認／新旅程／載入 · 0.35 s · 新
  Prompt: `Menu confirm, short two-tone glassy chime with a light metal tap, positive`
- `ui_save.wav` — 手動存檔完成 · 0.5 s · 新
  Prompt: `Saving progress, a crystal being set into a stone slot with a satisfying lock click and a brief warm hum, secure`
- `ui_mute.wav` — 切換靜音（靜音時不播，恢復時播） · 0.2 s · 新
  Prompt: `Audio toggle on, soft ascending glassy blip, minimal`

### 4.7 環境音循環（Ambience bus，隨鏡頭位置與日夜淡入淡出）

- `amb_day.ogg` — 白天荒地 · 30 s 循環 · 新
  Prompt: `Open frontier wilderness by day, steady soft wind through dry grass, a few sparse distant birds, very faint far-off crystal hum, calm and lonely, seamless loop, no music`
- `amb_night.ogg` — 夜晚 · 30 s 循環 · 新
  Prompt: `Haunted frontier at night, low cold wind, sparse crickets, occasional distant creature murmur and a barely audible deep dragon breath far away, tense stillness, seamless loop, no music`
- `amb_campfire.ogg` — 營火，定位在營火 · 20 s 循環 · 新
  Prompt: `Campfire crackling close up, wood pops and soft flame hiss, with a subtle warm crystal reactor hum underneath, cozy, seamless loop`
- `amb_city.ogg` — 二級以上營地反應爐與導管 · 30 s 循環 · 新
  Prompt: `Small refuge settlement ambience, low crystal reactor hum with soft energy conduit flow, occasional wooden creak and distant tool tap, lived-in, seamless loop`
- `amb_forest.ogg` — 森林 · 30 s 循環 · 新
  Prompt: `Dense frontier forest, leaves rustling in wind, birds and insects, creaking branches, seamless loop, no music`
- `amb_crystal.ogg` — 晶脈 · 20 s 循環 · 新
  Prompt: `Exposed dragon crystal vein, glassy resonant drone with slow shimmering overtones and tiny crystalline ticks, otherworldly, seamless loop`
- `amb_ruins.ogg` — 遺跡與地獄之門附近 · 30 s 循環 · 新
  Prompt: `Ancient stone ruins with a dormant magical portal, hollow wind through stone, low magenta energy throb, faint rune whispers without words, uneasy, seamless loop`

## 5. 音樂清單與 prompt

全部純器樂、可無縫循環。工具若是 Suno／Udio 類，把 prompt 放 style 欄並加 `[Instrumental]`；若是 Stable Audio 類，直接用描述。共同基底：`instrumental, pixel-art indie game soundtrack, sparse and atmospheric, melancholic, medieval fantasy meets subtle synth, bells and plucked strings with soft analog pads, lo-fi warmth, no vocals, seamless loop`

- `title.ogg` — 起始頁 · 90 s 循環 · 新
  Prompt: `Title theme for a lonely last refuge in a dragon-ruled world, slow minor-key bell melody over a soft synth pad, distant plucked lute, faint crystal shimmer, hopeful sadness, unhurried, 70 BPM`
- `day_explore.ogg` — 白天探索荒地／森林 · 120 s 循環 · 新
  Prompt: `Daytime exploration, gentle wandering theme, light plucked strings and a wooden flute over warm pads, sparse percussion of soft hand drum, curious and calm, minor to modal, 85 BPM`
- `day_refuge.ogg` — 白天在營地附近（建設、居民工作） · 120 s 循環 · 新
  Prompt: `Refuge by day, warm and industrious, plucked strings with a simple bell motif, soft rhythmic pulse like distant hammering, gentle synth undercurrent, community and quiet hope, 90 BPM`
- `night_watch.ogg` — 夜晚守備，敵人未到 · 120 s 循環 · 新
  Prompt: `Night watch on the walls, tense and sparse, low sustained synth drone, slow cold bell tolls, distant tremolo strings, minimal percussion heartbeat, dread building slowly, 70 BPM`
- `night_raid.ogg` — 夜襲交戰層（與 night_watch 同調同速，可疊加） · 120 s 循環 · 新
  Prompt: `Night raid combat layer in the same key and tempo as a slow tense night theme, driving low percussion, pulsing bass synth, urgent string ostinato, crystalline stabs, controlled intensity not epic, 70 BPM, designed to layer on top of a quieter theme`
- `dragon_boss.ogg` — 最終巨龍決戰 · 120 s 循環 · 新
  Prompt: `Final dragon battle, heavy but restrained, deep tribal drums, distorted low synth bass, soaring minor bell melody, dissonant crystal shimmer, relentless and desperate, 95 BPM`
- `victory_theme.ogg` — 勝利 · 20 s 不循環 · 新
  Prompt: `Victory piece, bright bell melody rising over a warm pad, gentle triumphant resolution, humble and earned, ends with a soft sustained chord`
- `defeat_theme.ogg` — 敗北 · 15 s 不循環 · 新
  Prompt: `Defeat piece, slow descending bell phrase over a cold fading pad, a dying mechanical hum, mournful, ends in near silence`
- `dawn_sting.ogg` — 日出短樂句 · 8 s 不循環 · 新
  Prompt: `Dawn stinger, a single warm rising bell phrase with soft pad swell and faint birdsong, relief after a long night, short`

音樂狀態機（實作時的切換規則）：

| 狀態 | 條件 | 曲目 | 切換方式 |
| --- | --- | --- | --- |
| 起始頁 | 尚未進入戰役 | title | 進戰役 1.5 s 淡出 |
| 白天探索 | 白天且距營火超過 900 世界單位 | day_explore | 2 s 交叉淡變 |
| 白天營地 | 白天且在營火 900 單位內 | day_refuge | 2 s 交叉淡變 |
| 夜晚守備 | 夜晚、場上無存活敵人 | night_watch | 3 s 交叉淡變 |
| 夜襲 | 夜晚且有存活敵人 | night_watch + night_raid 疊層 | raid 層 1 s 淡入、敵清空 3 s 淡出 |
| 巨龍 | dragon_arrival 後直到勝負 | dragon_boss | 停其他層、0.5 s 進 |
| 勝利／敗北 | outcome 改變 | victory_theme / defeat_theme | 停全部循環 |
| 日出 | 熬過一晚進入新一天 | dawn_sting 疊在當前循環上 | 一次 |

暫停時音樂降 -12 dB 並加低通濾波（Music bus 效果），不切曲；此規則取代 v001 的「暫停可預聽」。

## 6. 接線缺口對照（實作時逐條核對）

| 事件來源 | v001 對應 | v002 對應 | 動作 |
| --- | --- | --- | --- |
| `camp_ignition` | seal | ignition | 改對應 |
| `core_hit` | heavy | core_hit | 改對應 |
| `tower_arrow` | slash1 | bow_shot | 改對應 |
| `tower_laser` | dash | tower_laser | 改對應 |
| `bolt` | 無 | bow_shot / arrow_hit | 新增 |
| `crystal_sink` | 無 | 無（與 crystal_pickup 同屬入袋，避免重複） | 不接 |
| 受擊掉晶（CrystalPouch 掉落） | 無 | crystal_drop | 新增 |
| `sword_recovered` | 無 | sword_recover | 新增 |
| `portal_spawn` | 無 | portal_spawn | 新增 |
| `dragon_arrival` / `dragon_fire` | 無 | 同名 | 新增 |
| `module_pickup` / `module_equipped` / `module_stored` | 無 | module_* | 新增 |
| `farewell` | 無 | farewell | 新增（殘影告別） |
| 護盾吸收 | hurt | shield | 拆開 |
| 聚落升級 | build | upgrade | 拆開 |
| 掉劍、死亡、投滿格、退回、拋晶、落地、治療、交晶 | 無 | 見 4.1／4.2 | 觀察器新增狀態比對 |
| 城牆受擊／倒塌／修復、居民受擊、取器具、工作敲擊 | 無 | 見 4.3 | 觀察器新增；工作音需定位衰減 |
| 敵人預警／揮擊／死亡／抱晶、守門者 | 無 | 見 4.4 | 觀察器新增 |
| 日出、夜襲預告、封印累積、王國建立 | 無 | 見 4.5 | 觀察器新增 |
| UI | 無 | 見 4.6 | HUD／選單訊號直接呼叫 UI bus |
| 環境音 | 無 | 見 4.7 | 新 `CampaignAmbience` 節點 |
| 音樂 | 單曲循環 | 狀態機 | 新 `CampaignMusic` 節點，從 CampaignAudio 拆出 |

## 7. 分階段實作（全部完成）

1. **P0 素材生成與試聽** — 完成。116 個素材生成、量測、人聲篩檢並附試聽檔。
2. **P1 bus 與播放器換血** — 完成。四條音訊軌、v002 素材與變體輪播、音樂狀態機、三軌音量偏好、暫停低通。
3. **P2 觀察器補事件** — 完成。原本借用別的聲音的四個事件已拆開，沒有聲音的事件全部接上。
4. **P3 環境音** — 完成。日夜底層加五個定位層，依區域與距離淡入淡出。
5. **P4 UI 與靜音偏好** — 完成。暫停、繼續、解除靜音、存檔、確認、選單移動；靜音狀態跨 App 啟動保留。
6. **P5 居民工作音** — 完成。四種工作敲擊與快慢腳步走重複節奏驅動，遠處不發聲。

`tests/test_audio_coverage.gd` 鎖住成果：待接清單為空，新素材沒有觸發點就紅燈。完整 `bash tools/check.sh` 通過 2,384 項斷言，另有原生錄音佐證實際發聲。

## 8. 待使用者決定

1. **生成工具**：音效預設用 ElevenLabs Sound Effects，音樂預設用 Suno 或 Stable Audio 2；若你有其他偏好或已有帳號，prompt 格式我再依工具微調。
2. **音樂人聲**：本計畫全器樂；若想要低吟無詞人聲（choir、hum）當作巨龍或夜晚色彩，告訴我，只影響 night_watch 與 dragon_boss 兩首。
3. **環境音層（4.7）與居民工作音（P5）**要不要這輪做：兩者最花播放槽與記憶體，可先只做 4.1–4.6 與音樂。
4. **格式**：是否接受從 22,050 Hz 升到 44,100 Hz（素材總量預估：音效約 4 MB、環境音約 3 MB、音樂約 12 MB OGG，仍遠低於美術資源）。
5. **Python 合成器**：v002 上線後刪除 `generate_campaign_sounds.py` 與 `generate_frontier_music.py`，或保留為歷史。依「不多做」原則我建議刪除並在 provenance 記錄。
