# 音效與音樂 v002 素材目錄（含完整生成 prompt）

> 由 `tools/write_audio_docs_v002.py` 依 `tools/audio_v002_manifest.py` 產生，更新日期 2026-09-23。要改任何一條就改 manifest 再重跑，不要手改本檔。

全部素材以 ElevenLabs 依下列 prompt 生成，沒有任何錄音、取樣或第三方音源。
音效與環境音用 Text to Sound Effects，音樂用 Music；共用前綴與負面詞見第一節。

## 共用 prompt 片段

音效與環境音、音樂各自在下表的 prompt 後面（或前面）串上這些固定句，實際送出的完整字串記在各目錄的 `provenance.json`。

| 用途 | 內容 |
| --- | --- |
| 音效共同後綴 | Stylized retro pixel-art action game sound effect, clean and punchy, dry with minimal reverb, no music, no voice, no speech, mono-compatible. |
| 音效負面詞 | No chiptune, no 8-bit bleeps, no orchestral swell, no vocals, no lyrics, no long reverb tail, no cinematic trailer hit. |
| 環境音共同後綴 | Seamless looping game ambience bed, natural and continuous, no music, no voice, no speech. |
| 音樂共同後綴 | Instrumental only. Pixel-art indie game soundtrack, sparse and atmospheric, melancholic, medieval fantasy meets subtle synth, bells and plucked strings over soft analog pads, lo-fi warmth. No vocals, no singing, no choir, no spoken word. |

## 音效（103 個檔）

| 檔名 | 用途 | 長度 | 音量 | prompt（未含共用後綴） |
| --- | --- | --- | --- | --- |
| `arrow_hit` | 箭矢命中 | 0.07 s | 峰值 -6.0 dBFS | Arrow striking a magical creature, quick thock with a small crystal crack, small impact |
| `bow_shot` | 獵人與弓兵放箭 | 0.17 s | 峰值 -6.0 dBFS | Wooden longbow releasing an arrow, string twang and a fast feathered whistle, short |
| `build` | 施工完成 | 0.66 s | 峰值 -6.0 dBFS | Wooden and steel structure finishing construction, final hammer strike on a beam, timber settling, and a brief teal energy conduit powering on |
| `charge_empty` | 充能不足，動作未發動 | 0.25 s | 峰值 -6.0 dBFS | Depleted capacitor click, dry electric tick followed by a tiny failing fizzle, small and unsatisfying, indicates no power |
| `chest` | 寶箱開啟噴出龍晶 | 0.55 s | 峰值 -6.0 dBFS | Old iron-banded wooden chest bursting open, wood creak and metal latch snap, then a shower of glowing crystals spraying outward with bright glassy sparkle |
| `core_hit` | 營火核心受擊警示 | 0.65 s | 峰值 -6.0 dBFS | The heart of a refuge taking damage, deep crystal reactor impact with a low pulsing alarm throb and flames flaring, urgent |
| `crystal_drop` | 受擊掉出龍晶（出袋） | 0.60 s | 峰值 -6.0 dBFS | Several small glowing crystals spilling out of a leather pouch and scattering on dirt, glassy tinkling with a soft pouch flap, loss and scatter |
| `crystal_land_1` | 龍晶落地彈跳 | 0.21 s | 峰值 -6.0 dBFS | Small hard crystal landing on dirt and bouncing once, short glassy tick and a muted thud, tiny |
| `crystal_land_2` | 龍晶落地彈跳 | 0.27 s | 峰值 -6.0 dBFS | Small hard crystal landing on dirt and bouncing once, short glassy tick and a muted thud, tiny |
| `crystal_land_3` | 龍晶落地彈跳 | 0.30 s | 峰值 -6.0 dBFS | Small hard crystal landing on dirt and bouncing once, short glassy tick and a muted thud, tiny |
| `dash` | 義肢充能衝刺 | 0.36 s | 峰值 -6.0 dBFS | Mechanical prosthetic leg burst dash, quick hydraulic hiss then a short electric capacitor discharge zap, forward-moving air rush |
| `dawn` | 日出，顯示天數 | 1.31 s | 峰值 -6.0 dBFS | Dawn breaking after a survived night, warm rising pad with a soft bright bell and a few distant birds, relief, short |
| `death` | 騎士倒地死亡 | 0.90 s | 峰值 -6.0 dBFS | Armored knight collapsing to the ground, heavy plate armor thud, prosthetic servos powering down with a descending whine, crystal core light fading with a soft resonant decay |
| `defeat` | 敗北短句 | 2.05 s | 峰值 -6.0 dBFS | Short defeat motif, slow descending bell phrase over a fading cold pad with a dying mechanical hum, mournful, ends cleanly, instrumental |
| `dragon_arrival` | 最終巨龍降臨 | 2.35 s | 峰值 -6.0 dBFS | Colossal dragon descending from the sky, massive slow wingbeats pushing air, ground-shaking landing thud, and a deep layered roar with crystalline magical resonance |
| `dragon_death` | 巨龍倒下 | 2.15 s | 峰值 -6.0 dBFS | Colossal dragon collapsing, long groaning roar falling in pitch, massive body impact on the ground, then a slow crystal resonance dissolving into silence |
| `dragon_fire` | 巨龍吐火 | 0.98 s | 峰值 -6.0 dBFS | Dragon breathing a torrent of magical fire, sharp ignition burst then a roaring sustained flame jet with a crackling crystal-charged undertone, decaying at the end |
| `dragon_hurt` | 巨龍受擊 | 0.43 s | 峰值 -6.0 dBFS | Dragon taking a sword hit, deep pained roar with a cracking scale impact, heavy, animal not human |
| `dragon_wing` | 巨龍振翅循環 · 循環 | 2.00 s | 峰值 -6.0 dBFS | Giant leathery dragon wings beating slowly, deep air whoomp per beat, seamless two-beat loop |
| `enemy_attack_1` | 敵人揮擊 | 0.32 s | 峰值 -6.0 dBFS | Clawed creature swiping, fast heavy whoosh with a scraping edge, aggressive |
| `enemy_attack_2` | 敵人揮擊 | 0.32 s | 峰值 -6.0 dBFS | Clawed creature swiping, fast heavy whoosh with a scraping edge, aggressive |
| `enemy_attack_3` | 敵人揮擊 | 0.32 s | 峰值 -6.0 dBFS | Clawed creature swiping, fast heavy whoosh with a scraping edge, aggressive |
| `enemy_death` | 小怪倒下消散 | 0.55 s | 峰值 -6.0 dBFS | Magical creature collapsing and dissolving into crystal dust, brief body thud then a fizzing glassy disintegration fading upward |
| `enemy_grab` | 小怪抱走龍晶撤退 | 0.45 s | 峰值 -6.0 dBFS | Creature snatching a glowing crystal and fleeing, quick grab rustle, a muffled glassy chime, and scurrying steps moving away |
| `enemy_telegraph` | 敵人攻擊預警 | 0.45 s | 峰值 -6.0 dBFS | Creature winding up an attack, rising crystalline growl with a short swell, clear warning cue, no words |
| `farewell` | 龍晶殘影告別離場 | 0.65 s | 峰值 -6.0 dBFS | A faint presence leaving, soft descending crystal shimmer fading into wind, gentle and melancholic |
| `footstep_1` | 跑步腳步，金屬義肢踩土 | 0.18 s | 峰值 -6.0 dBFS | Single footstep of a metal prosthetic boot on packed dirt and grass, short and crisp, faint servo click, no reverb |
| `footstep_2` | 跑步腳步，金屬義肢踩土 | 0.18 s | 峰值 -6.0 dBFS | Single footstep of a metal prosthetic boot on packed dirt and grass, short and crisp, faint servo click, no reverb |
| `footstep_3` | 跑步腳步，金屬義肢踩土 | 0.18 s | 峰值 -6.0 dBFS | Single footstep of a metal prosthetic boot on packed dirt and grass, short and crisp, faint servo click, no reverb |
| `footstep_slow_1` | 慢移腳步 | 0.24 s | 峰值 -6.0 dBFS | Single careful footstep of a heavy armored boot on dirt, softer and slower than a run, slight leather creak |
| `footstep_slow_2` | 慢移腳步 | 0.24 s | 峰值 -6.0 dBFS | Single careful footstep of a heavy armored boot on dirt, softer and slower than a run, slight leather creak |
| `footstep_slow_3` | 慢移腳步 | 0.24 s | 峰值 -6.0 dBFS | Single careful footstep of a heavy armored boot on dirt, softer and slower than a run, slight leather creak |
| `gatekeeper_appear` | 守門者出現 | 0.40 s | 峰值 -6.0 dBFS | A large armored guardian creature emerging, heavy stone-grinding steps and a deep resonant crystal roar, imposing, no words |
| `handoff` | 工匠把採集龍晶交給騎士 | 0.45 s | 峰值 -6.0 dBFS | A handful of crystals passed from one leather pouch into another, gentle glassy cascade with two soft pouch taps, friendly exchange |
| `heal` | 付晶治療 | 0.65 s | 峰值 -6.0 dBFS | Healing energy flowing from a crystal into an armored body, warm ascending resonant hum with soft servo re-engaging sounds, restoration |
| `heavy` | 重擊命中 | 0.38 s | 峰值 -6.0 dBFS | Heavy sword impact with deep low thud and a splintering crystal shatter layer, strong transient, brief sub-bass punch |
| `hit_1` | 一般命中敵人 | 0.30 s | 峰值 -6.0 dBFS | Sword blade striking a magical creature, crunchy mid-frequency impact with a short crystalline crack, satisfying and punchy, no gore |
| `hit_2` | 一般命中敵人 | 0.30 s | 峰值 -6.0 dBFS | Sword blade striking a magical creature, crunchy mid-frequency impact with a short crystalline crack, satisfying and punchy, no gore |
| `hit_3` | 一般命中敵人 | 0.30 s | 峰值 -6.0 dBFS | Sword blade striking a magical creature, crunchy mid-frequency impact with a short crystalline crack, satisfying and punchy, no gore |
| `horse_gallop` | 龍晶戰馬奔馳循環 · 循環 | 2.00 s | 峰值 -6.0 dBFS | Mechanical crystal-powered warhorse galloping loop, rhythmic metal hooves on dirt with a low crystalline engine hum, steady four-beat cycle, seamless loop |
| `hurt` | 騎士受傷，生命或龍晶損失 | 0.41 s | 峰值 -6.0 dBFS | Armored knight taking a hit, metal plate clang mixed with a short glassy crystal crack and a small servo stutter, impact only |
| `ignition` | 拔劍點火建國 | 0.91 s | 峰值 -6.0 dBFS | Sword raised and plunged into a campfire, sharp steel ring, sparks crackling, flames roaring up, then a deep resonant crystal hum awakening |
| `jump` | 騎士起跳 | 0.20 s | 峰值 -6.0 dBFS | Armored knight jumping off the ground, quick hydraulic push from a prosthetic leg with a short cloth and armor rustle, upward and light |
| `kingdom` | 王國建立里程碑 | 1.07 s | 峰值 -6.0 dBFS | Kingdom founded milestone, three ascending bell tones with a warm resonant crystal chord blooming, ceremonial and grounded |
| `land_1` | 騎士落地 | 0.28 s | 峰值 -6.0 dBFS | Armored knight landing on packed dirt, solid double thud of boots with a metallic armor settle and a small servo absorb, weighty but not heavy |
| `land_2` | 騎士落地 | 0.42 s | 峰值 -6.0 dBFS | Armored knight landing on packed dirt, solid double thud of boots with a metallic armor settle and a small servo absorb, weighty but not heavy |
| `module_equip` | 改造所裝備部件 | 0.71 s | 峰值 -6.0 dBFS | Attaching a mechanical module to armored prosthetic back mounts, two metal latches clicking in sequence then a hydraulic seal hiss and a brief power-up hum |
| `module_pickup` | 拾取機械部件 | 0.32 s | 峰值 -6.0 dBFS | Picking up a small mechanical component, metallic clink and a short servo chirp, compact gadget |
| `module_store` | 部件收納 | 0.27 s | 峰值 -6.0 dBFS | Placing a mechanical part into a padded storage rack, soft metal clunk and a fabric rustle, quiet and tidy |
| `mount` | 上馬 | 0.62 s | 峰值 -6.0 dBFS | Knight mounting a mechanical warhorse, armor shifting, saddle clunk, and a rising crystal engine hum settling into idle |
| `night` | 入夜 | 0.72 s | 峰值 -6.0 dBFS | Nightfall in a haunted frontier, low wind swell with a distant unsettling crystal drone and a single deep bell, foreboding |
| `pay` | 投入一顆龍晶到格子 | 0.18 s | 峰值 -6.0 dBFS | Placing a glowing crystal into a metal socket, short glass-on-steel click followed by a brief teal energy hum engaging, deliberate and precise |
| `pickup_1` | 龍晶飛入背包 | 0.22 s | 峰值 -6.0 dBFS | Small glowing crystal shard flying into a leather pouch, quick ascending glassy chime with a soft leather tap at the end, light and rewarding |
| `pickup_2` | 龍晶飛入背包 | 0.22 s | 峰值 -6.0 dBFS | Small glowing crystal shard flying into a leather pouch, quick ascending glassy chime with a soft leather tap at the end, light and rewarding |
| `pickup_3` | 龍晶飛入背包 | 0.22 s | 峰值 -6.0 dBFS | Small glowing crystal shard flying into a leather pouch, quick ascending glassy chime with a soft leather tap at the end, light and rewarding |
| `portal_spawn` | 地獄之門湧出敵人 | 0.57 s | 峰值 -6.0 dBFS | A magical portal spitting out a creature, low magenta energy surge with a wet tearing rip and a short rising distortion, unsettling |
| `raid_warning` | 日落前夜襲方向預告 | 0.85 s | 峰值 -6.0 dBFS | Warning horn from a wooden watchtower, short low horn blast with a slight crystal shimmer, alert but not panicked |
| `recruit` | 流浪者加入 | 0.49 s | 峰值 -6.0 dBFS | A wanderer joining the refuge, warm short two-note bell motif with a faint crystal shimmer, hopeful and humble |
| `resident_hit` | 居民受擊退回流浪者 | 0.08 s | 峰值 -6.0 dBFS | A villager struck and dropping their tool, wooden tool clattering to the ground, short and small, no voice |
| `seal` | 封印完成 | 1.06 s | 峰值 -6.0 dBFS | Ancient portal sealing shut, heavy stone grinding closed, a deep magical lock thud, then a bright crystalline resolve chord, final |
| `seal_progress` | 封印累積循環 · 循環 | 2.36 s | 峰值 -6.0 dBFS | Magical seal charging loop, slow pulsing crystal hum rising in intensity with soft rune-like glassy ticks, seamless loop, building anticipation |
| `shield` | 護盾吸收，生命未降 | 0.35 s | 峰值 -6.0 dBFS | Teal energy shield deflecting a blow, quick electric shimmer with a soft resonant hum, glassy and cool, deflection rather than damage |
| `slash1_1` | 第一刀斜向拔切，站定出刀 | 0.35 s | 峰值 -6.0 dBFS | Quick steel sword draw-cut slicing diagonally through air, sharp bright whoosh with a thin metallic ring at the start, tight and fast, medieval longsword |
| `slash1_2` | 第一刀斜向拔切，站定出刀 | 0.35 s | 峰值 -6.0 dBFS | Quick steel sword draw-cut slicing diagonally through air, sharp bright whoosh with a thin metallic ring at the start, tight and fast, medieval longsword |
| `slash1_3` | 第一刀斜向拔切，站定出刀 | 0.35 s | 峰值 -6.0 dBFS | Quick steel sword draw-cut slicing diagonally through air, sharp bright whoosh with a thin metallic ring at the start, tight and fast, medieval longsword |
| `slash2_1` | 第二刀反手回斬，踏進 | 0.26 s | 峰值 -6.0 dBFS | Backhand sword sweep whoosh, slightly lower pitch than a draw cut, wider arc, brief leather-and-armor rustle underneath, fast recovery |
| `slash2_2` | 第二刀反手回斬，踏進 | 0.15 s | 峰值 -6.0 dBFS | Backhand sword sweep whoosh, slightly lower pitch than a draw cut, wider arc, brief leather-and-armor rustle underneath, fast recovery |
| `slash2_3` | 第二刀反手回斬，踏進 | 0.30 s | 峰值 -6.0 dBFS | Backhand sword sweep whoosh, slightly lower pitch than a draw cut, wider arc, brief leather-and-armor rustle underneath, fast recovery |
| `slash3_1` | 第三刀跨步穿刺，收招 | 0.36 s | 峰值 -6.0 dBFS | Lunging sword thrust, focused narrow air-cut whoosh ending in a short steel shimmer, heavier footfall of a metal prosthetic leg planting on dirt |
| `slash3_2` | 第三刀跨步穿刺，收招 | 0.40 s | 峰值 -6.0 dBFS | Lunging sword thrust, focused narrow air-cut whoosh ending in a short steel shimmer, heavier footfall of a metal prosthetic leg planting on dirt |
| `slash3_3` | 第三刀跨步穿刺，收招 | 0.26 s | 峰值 -6.0 dBFS | Lunging sword thrust, focused narrow air-cut whoosh ending in a short steel shimmer, heavier footfall of a metal prosthetic leg planting on dirt |
| `slot_complete` | 投滿格，互動執行 | 0.55 s | 峰值 -6.0 dBFS | A row of crystal sockets completing, quick rising three-note glassy arpeggio resolving into a warm resonant confirmation, magical machinery locking in |
| `slot_refund` | 未填滿逾時退回 | 0.45 s | 峰值 -6.0 dBFS | Crystals being released from sockets and dropping back to the ground, descending glassy tinkle with a soft mechanical unlatch, gentle disappointment |
| `sword_drop` | 空袋受擊掉劍 | 0.70 s | 峰值 -6.0 dBFS | Steel longsword knocked from a hand, clattering and bouncing once on stone ground then settling, heavy metallic ring, ominous |
| `sword_recover` | 撿回劍 | 0.35 s | 峰值 -6.0 dBFS | Picking a sword up from the ground and gripping it, short steel scrape and a confident metallic ring as the blade rises, restored |
| `throw` | 拋晶 | 0.32 s | 峰值 -6.0 dBFS | Tossing a small crystal through the air, quick swish with a faint shimmering trail, light and airy |
| `tool_pickup` | 居民取器具就職 | 0.23 s | 峰值 -6.0 dBFS | Resident grabbing a work tool from a wooden rack, wooden handle knock and a short leather strap tightening, purposeful |
| `tower_laser` | 護民塔龍晶射線 | 0.12 s | 峰值 -6.0 dBFS | Crystal-powered defense tower firing a teal energy beam, sharp charged zap with a brief resonant sustain, futuristic but grounded in a stone tower |
| `ui_confirm` | 確認、新旅程、載入 | 0.01 s | 峰值 -6.0 dBFS | Menu confirm, short two-tone glassy chime with a light metal tap, positive |
| `ui_mute` | 切換靜音恢復 | 0.21 s | 峰值 -6.0 dBFS | Audio toggle on, soft ascending glassy blip, minimal |
| `ui_pause` | 開啟暫停 | 0.20 s | 峰值 -6.0 dBFS | Soft mechanical user interface open, gentle metal latch click with a short teal shimmer, clean |
| `ui_resume` | 關閉暫停繼續遊戲 | 0.28 s | 峰值 -6.0 dBFS | Soft mechanical user interface close, reverse latch click, quick and clean |
| `ui_save` | 手動存檔完成 | 0.40 s | 峰值 -6.0 dBFS | Saving progress, a crystal set into a stone slot with a satisfying lock click and a brief warm hum, secure |
| `ui_select` | 選單移動與滑桿刻度 | 0.12 s | 峰值 -6.0 dBFS | Tiny crystal tick for menu navigation, very short bright glassy click |
| `upgrade` | 聚落升級 | 0.94 s | 峰值 -6.0 dBFS | A settlement growing to a new tier, deep stone shift and rising mechanical machinery, then a resonant crystal reactor tone blooming outward, ceremonial and grounded |
| `victory` | 通關勝利短句 | 1.36 s | 峰值 -6.0 dBFS | Short victory fanfare for a small pixel-art kingdom, bright bell and warm crystal motif over a soft pad, triumphant yet humble, ends cleanly, instrumental |
| `wall_break` | 城牆倒塌 | 0.83 s | 峰值 -6.0 dBFS | Wooden and stone barricade collapsing, cracking beams, tumbling stones, and a dying crystal conduit fizzle, alarming |
| `wall_hit_1` | 城牆受擊 | 0.38 s | 峰值 -6.0 dBFS | Wooden palisade wall being struck by a creature, heavy timber thud and creak, planks rattling |
| `wall_hit_2` | 城牆受擊 | 0.38 s | 峰值 -6.0 dBFS | Wooden palisade wall being struck by a creature, heavy timber thud and creak, planks rattling |
| `wall_hit_3` | 城牆受擊 | 0.29 s | 峰值 -6.0 dBFS | Wooden palisade wall being struck by a creature, heavy timber thud and creak, planks rattling |
| `wall_repair` | 城牆修復完成 | 0.41 s | 峰值 -6.0 dBFS | Wall being repaired, quick hammer taps and a beam sliding into place with a wooden clunk, reassuring |
| `work_chop_1` | 工匠伐木 | 0.32 s | 峰值 -6.0 dBFS | Single axe chop into a living tree trunk, dry woody thock with a little bark splinter, close and clear |
| `work_chop_2` | 工匠伐木 | 0.20 s | 峰值 -6.0 dBFS | Single axe chop into a living tree trunk, dry woody thock with a little bark splinter, close and clear |
| `work_chop_3` | 工匠伐木 | 0.14 s | 峰值 -6.0 dBFS | Single axe chop into a living tree trunk, dry woody thock with a little bark splinter, close and clear |
| `work_hammer_1` | 施工敲擊 | 0.05 s | 峰值 -6.0 dBFS | Hammer striking a wooden beam with an iron nail, single sharp knock, construction |
| `work_hammer_2` | 施工敲擊 | 0.28 s | 峰值 -6.0 dBFS | Hammer striking a wooden beam with an iron nail, single sharp knock, construction |
| `work_hammer_3` | 施工敲擊 | 0.24 s | 峰值 -6.0 dBFS | Hammer striking a wooden beam with an iron nail, single sharp knock, construction |
| `work_harvest_1` | 農夫收割採果採藥 | 0.32 s | 峰值 -6.0 dBFS | Sickle cutting through crop stalks and leaves, soft swish and rustle, single stroke |
| `work_harvest_2` | 農夫收割採果採藥 | 0.29 s | 峰值 -6.0 dBFS | Sickle cutting through crop stalks and leaves, soft swish and rustle, single stroke |
| `work_harvest_3` | 農夫收割採果採藥 | 0.32 s | 峰值 -6.0 dBFS | Sickle cutting through crop stalks and leaves, soft swish and rustle, single stroke |
| `work_mine_1` | 工匠採礦 | 0.32 s | 峰值 -6.0 dBFS | Pickaxe striking crystal-bearing rock, stone crack with a bright glassy overtone, single strike |
| `work_mine_2` | 工匠採礦 | 0.32 s | 峰值 -6.0 dBFS | Pickaxe striking crystal-bearing rock, stone crack with a bright glassy overtone, single strike |
| `work_mine_3` | 工匠採礦 | 0.32 s | 峰值 -6.0 dBFS | Pickaxe striking crystal-bearing rock, stone crack with a bright glassy overtone, single strike |

## 環境音循環（7 個檔）

| 檔名 | 用途 | 長度 | 音量 | prompt（未含共用後綴） |
| --- | --- | --- | --- | --- |
| `amb_campfire` | 營火近景 · 循環 | 16.50 s | -30.9 LUFS | Campfire burning close up, continuous steady flame roar and hiss with dense constant wood crackling and popping throughout, never silent, a subtle warm crystal reactor hum underneath, cozy |
| `amb_city` | 二級以上營地反應爐 · 循環 | 20.50 s | -30.0 LUFS | Small refuge settlement, continuous low crystal reactor hum with soft energy conduit flow, occasional wooden creak and distant tool tap, lived-in, never silent |
| `amb_crystal` | 晶脈 · 循環 | 16.50 s | -30.0 LUFS | Exposed crystal vein, continuous glassy resonant drone with slow shimmering overtones and tiny crystalline ticks, otherworldly, never silent |
| `amb_day` | 白天荒地 · 循環 | 20.50 s | -30.1 LUFS | Open frontier wilderness by day, continuous steady wind through dry grass, scattered distant birds throughout, a faint far-off crystal hum, calm and lonely, never silent |
| `amb_forest` | 森林 · 循環 | 20.50 s | -30.2 LUFS | Dense frontier forest, continuous steady wind through thick foliage with constant leaf rustle, layered birdsong and a steady insect chorus throughout, never silent, creaking branches |
| `amb_night` | 夜晚 · 循環 | 20.50 s | -30.1 LUFS | Haunted frontier at night, continuous low cold wind running throughout, steady cricket chorus, distant owl calls and a faint uneasy drone, always present and never silent, tense |
| `amb_ruins` | 遺跡與地獄之門 · 循環 | 20.50 s | -30.0 LUFS | Ancient stone ruins with a dormant magical portal, continuous hollow wind through stone, steady low energy throb, uneasy, never silent |

## 音樂（10 個檔）

| 檔名 | 用途 | 長度 | 音量 | prompt（未含共用後綴） |
| --- | --- | --- | --- | --- |
| `dawn_sting` | 日出短樂句 | 7.80 s | -16.1 LUFS | Dawn stinger, a single warm rising bell phrase with soft pad swell and faint birdsong, relief after a long night, short |
| `day_explore` | 白天探索荒地與森林 · 循環 | 117.01 s | -16.2 LUFS | Daytime exploration theme, gentle wandering feel, light plucked strings and a wooden flute over warm pads, sparse soft hand drum, curious and calm, modal minor, 85 BPM |
| `day_refuge` | 白天營地建設 · 循環 | 118.51 s | -16.0 LUFS | Refuge by day, warm and industrious, plucked strings with a simple bell motif, soft rhythmic pulse like distant hammering, gentle synth undercurrent, community and quiet hope, 90 BPM |
| `defeat_theme` | 敗北 | 13.11 s | -15.9 LUFS | Defeat piece, slow descending bell phrase over a cold fading pad and a dying mechanical hum, mournful, ends in near silence |
| `dragon_boss` | 最終巨龍決戰 · 循環 | 118.42 s | -16.1 LUFS | Final dragon battle, heavy but restrained, deep tribal drums, distorted low synth bass, soaring minor bell melody, dissonant crystal shimmer, relentless and desperate, 95 BPM |
| `founding_theme` | 建國點火儀式 | 11.34 s | -16.1 LUFS | Founding stinger, a low resonant swell rising into a warm bell motif with plucked strings, the moment a refuge is born, hopeful and ceremonial, ends on a sustained chord |
| `night_raid` | 夜襲交戰疊層 · 循環 | 117.85 s | -16.8 LUFS | Night raid combat layer, driving low percussion, pulsing bass synth, urgent string ostinato, crystalline stabs, controlled intensity rather than epic, 70 BPM, designed to layer over a quieter night theme in the same key |
| `night_watch` | 夜晚守備，敵人未到 · 循環 | 118.01 s | -16.2 LUFS | Night watch on the walls, tense and sparse, low sustained synth drone, slow cold bell tolls, distant tremolo strings, minimal percussion heartbeat, dread building slowly, 70 BPM |
| `title` | 起始頁 · 循環 | 85.06 s | -16.0 LUFS | Title theme for a lonely last refuge in a dragon-ruled world, slow minor-key bell melody over a soft synth pad, distant plucked lute, faint crystal shimmer, hopeful sadness, unhurried, 70 BPM |
| `victory_theme` | 勝利 | 17.27 s | -16.0 LUFS | Victory piece, bright bell melody rising over a warm pad, gentle triumphant resolution, humble and earned, ends with a soft sustained chord |
