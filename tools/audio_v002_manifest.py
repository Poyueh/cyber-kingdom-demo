#!/usr/bin/env python3
"""Single source of truth for the v002 audio set: every prompt, duration and target.

Generation, post-processing, verification and the provenance documents all read this file.
Edit here, never in the generated outputs.
"""

SFX_BASE = ("Stylized retro pixel-art action game sound effect, clean and punchy, "
            "dry with minimal reverb, no music, no voice, no speech, mono-compatible.")
SFX_NEGATIVE = ("No chiptune, no 8-bit bleeps, no orchestral swell, no vocals, no lyrics, "
                "no long reverb tail, no cinematic trailer hit.")
AMBIENCE_BASE = "Seamless looping game ambience bed, natural and continuous, no music, no voice, no speech."
MUSIC_BASE = ("Instrumental only. Pixel-art indie game soundtrack, sparse and atmospheric, "
              "melancholic, medieval fantasy meets subtle synth, bells and plucked strings "
              "over soft analog pads, lo-fi warmth. No vocals, no singing, no choir, no spoken word.")

# (key, zh_use, request_seconds, target_seconds, variants, loop, prompt)
SFX = [
 # --- 4.1 Knight combat ---
 ("slash1","第一刀斜向拔切，站定出刀",0.7,0.35,3,False,
  "Quick steel sword draw-cut slicing diagonally through air, sharp bright whoosh with a thin metallic ring at the start, tight and fast, medieval longsword"),
 ("slash2","第二刀反手回斬，踏進",0.7,0.35,3,False,
  "Backhand sword sweep whoosh, slightly lower pitch than a draw cut, wider arc, brief leather-and-armor rustle underneath, fast recovery"),
 ("slash3","第三刀跨步穿刺，收招",0.8,0.45,3,False,
  "Lunging sword thrust, focused narrow air-cut whoosh ending in a short steel shimmer, heavier footfall of a metal prosthetic leg planting on dirt"),
 ("hit","一般命中敵人",0.6,0.3,3,False,
  "Sword blade striking a magical creature, crunchy mid-frequency impact with a short crystalline crack, satisfying and punchy, no gore"),
 ("heavy","重擊命中",0.7,0.4,1,False,
  "Heavy sword impact with deep low thud and a splintering crystal shatter layer, strong transient, brief sub-bass punch"),
 ("hurt","騎士受傷，生命或龍晶損失",0.8,0.45,1,False,
  "Armored knight taking a hit, metal plate clang mixed with a short glassy crystal crack and a small servo stutter, impact only"),
 ("shield","護盾吸收，生命未降",0.6,0.35,1,False,
  "Teal energy shield deflecting a blow, quick electric shimmer with a soft resonant hum, glassy and cool, deflection rather than damage"),
 ("dash","義肢充能衝刺",0.7,0.4,1,False,
  "Mechanical prosthetic leg burst dash, quick hydraulic hiss then a short electric capacitor discharge zap, forward-moving air rush"),
 ("charge_empty","充能不足，動作未發動",0.5,0.25,1,False,
  "Depleted capacitor click, dry electric tick followed by a tiny failing fizzle, small and unsatisfying, indicates no power"),
 ("crystal_drop","受擊掉出龍晶（出袋）",0.9,0.6,1,False,
  "Several small glowing crystals spilling out of a leather pouch and scattering on dirt, glassy tinkling with a soft pouch flap, loss and scatter"),
 ("sword_drop","空袋受擊掉劍",1.0,0.7,1,False,
  "Steel longsword knocked from a hand, clattering and bouncing once on stone ground then settling, heavy metallic ring, ominous"),
 ("sword_recover","撿回劍",0.7,0.45,1,False,
  "Picking a sword up from the ground and gripping it, short steel scrape and a confident metallic ring as the blade rises, restored"),
 ("death","騎士倒地死亡",1.4,1.1,1,False,
  "Armored knight collapsing to the ground, heavy plate armor thud, prosthetic servos powering down with a descending whine, crystal core light fading with a soft resonant decay"),
 ("footstep","跑步腳步，金屬義肢踩土",0.5,0.18,3,False,
  "Single footstep of a metal prosthetic boot on packed dirt and grass, short and crisp, faint servo click, no reverb"),
 ("footstep_slow","慢移腳步",0.5,0.24,3,False,
  "Single careful footstep of a heavy armored boot on dirt, softer and slower than a run, slight leather creak"),
 ("horse_gallop","龍晶戰馬奔馳循環",2.0,2.0,1,True,
  "Mechanical crystal-powered warhorse galloping loop, rhythmic metal hooves on dirt with a low crystalline engine hum, steady four-beat cycle, seamless loop"),
 ("mount","上馬",0.9,0.65,1,False,
  "Knight mounting a mechanical warhorse, armor shifting, saddle clunk, and a rising crystal engine hum settling into idle"),

 # --- 4.2 Crystals and economy ---
 ("pickup","龍晶飛入背包",0.5,0.22,3,False,
  "Small glowing crystal shard flying into a leather pouch, quick ascending glassy chime with a soft leather tap at the end, light and rewarding"),
 ("pay","投入一顆龍晶到格子",0.6,0.3,1,False,
  "Placing a glowing crystal into a metal socket, short glass-on-steel click followed by a brief teal energy hum engaging, deliberate and precise"),
 ("slot_complete","投滿格，互動執行",0.9,0.55,1,False,
  "A row of crystal sockets completing, quick rising three-note glassy arpeggio resolving into a warm resonant confirmation, magical machinery locking in"),
 ("slot_refund","未填滿逾時退回",0.8,0.45,1,False,
  "Crystals being released from sockets and dropping back to the ground, descending glassy tinkle with a soft mechanical unlatch, gentle disappointment"),
 ("throw","拋晶",0.6,0.32,1,False,
  "Tossing a small crystal through the air, quick swish with a faint shimmering trail, light and airy"),
 ("crystal_land","龍晶落地彈跳",0.5,0.3,3,False,
  "Small hard crystal landing on dirt and bouncing once, short glassy tick and a muted thud, tiny"),
 ("chest","寶箱開啟噴出龍晶",1.2,0.9,1,False,
  "Old iron-banded wooden chest bursting open, wood creak and metal latch snap, then a shower of glowing crystals spraying outward with bright glassy sparkle"),
 ("heal","付晶治療",0.9,0.65,1,False,
  "Healing energy flowing from a crystal into an armored body, warm ascending resonant hum with soft servo re-engaging sounds, restoration"),
 ("module_pickup","拾取機械部件",0.6,0.32,1,False,
  "Picking up a small mechanical component, metallic clink and a short servo chirp, compact gadget"),
 ("module_equip","改造所裝備部件",1.0,0.75,1,False,
  "Attaching a mechanical module to armored prosthetic back mounts, two metal latches clicking in sequence then a hydraulic seal hiss and a brief power-up hum"),
 ("module_store","部件收納",0.6,0.32,1,False,
  "Placing a mechanical part into a padded storage rack, soft metal clunk and a fabric rustle, quiet and tidy"),
 ("handoff","工匠把採集龍晶交給騎士",0.7,0.45,1,False,
  "A handful of crystals passed from one leather pouch into another, gentle glassy cascade with two soft pouch taps, friendly exchange"),

 # --- 4.3 Refuge, residents, defenses ---
 ("recruit","流浪者加入",1.0,0.75,1,False,
  "A wanderer joining the refuge, warm short two-note bell motif with a faint crystal shimmer, hopeful and humble"),
 ("build","施工完成",1.0,0.75,1,False,
  "Wooden and steel structure finishing construction, final hammer strike on a beam, timber settling, and a brief teal energy conduit powering on"),
 ("upgrade","聚落升級",1.5,1.2,1,False,
  "A settlement growing to a new tier, deep stone shift and rising mechanical machinery, then a resonant crystal reactor tone blooming outward, ceremonial and grounded"),
 ("ignition","拔劍點火建國",2.0,1.6,1,False,
  "Sword raised and plunged into a campfire, sharp steel ring, sparks crackling, flames roaring up, then a deep resonant crystal hum awakening"),
 ("tool_pickup","居民取器具就職",0.7,0.42,1,False,
  "Resident grabbing a work tool from a wooden rack, wooden handle knock and a short leather strap tightening, purposeful"),
 ("work_chop","工匠伐木",0.6,0.32,3,False,
  "Single axe chop into a living tree trunk, dry woody thock with a little bark splinter, close and clear"),
 ("work_mine","工匠採礦",0.6,0.32,3,False,
  "Pickaxe striking crystal-bearing rock, stone crack with a bright glassy overtone, single strike"),
 ("work_hammer","施工敲擊",0.5,0.28,3,False,
  "Hammer striking a wooden beam with an iron nail, single sharp knock, construction"),
 ("work_harvest","農夫收割採果採藥",0.6,0.32,3,False,
  "Sickle cutting through crop stalks and leaves, soft swish and rustle, single stroke"),
 ("bow_shot","獵人與弓兵放箭",0.6,0.32,1,False,
  "Wooden longbow releasing an arrow, string twang and a fast feathered whistle, short"),
 ("arrow_hit","箭矢命中",0.5,0.22,1,False,
  "Arrow striking a magical creature, quick thock with a small crystal crack, small impact"),
 ("tower_laser","護民塔龍晶射線",0.8,0.55,1,False,
  "Crystal-powered defense tower firing a teal energy beam, sharp charged zap with a brief resonant sustain, futuristic but grounded in a stone tower"),
 ("wall_hit","城牆受擊",0.6,0.38,3,False,
  "Wooden palisade wall being struck by a creature, heavy timber thud and creak, planks rattling"),
 ("wall_break","城牆倒塌",1.4,1.1,1,False,
  "Wooden and stone barricade collapsing, cracking beams, tumbling stones, and a dying crystal conduit fizzle, alarming"),
 ("wall_repair","城牆修復完成",0.8,0.55,1,False,
  "Wall being repaired, quick hammer taps and a beam sliding into place with a wooden clunk, reassuring"),
 ("core_hit","營火核心受擊警示",0.9,0.65,1,False,
  "The heart of a refuge taking damage, deep crystal reactor impact with a low pulsing alarm throb and flames flaring, urgent"),
 ("resident_hit","居民受擊退回流浪者",0.8,0.5,1,False,
  "A villager struck and dropping their tool, wooden tool clattering to the ground, short and small, no voice"),
 ("farewell","龍晶殘影告別離場",0.9,0.65,1,False,
  "A faint presence leaving, soft descending crystal shimmer fading into wind, gentle and melancholic"),

 # --- 4.4 Enemies and the dragon ---
 ("portal_spawn","地獄之門湧出敵人",1.1,0.85,1,False,
  "A magical portal spitting out a creature, low magenta energy surge with a wet tearing rip and a short rising distortion, unsettling"),
 ("enemy_telegraph","敵人攻擊預警",0.7,0.45,1,False,
  "Creature winding up an attack, rising crystalline growl with a short swell, clear warning cue, no words"),
 ("enemy_attack","敵人揮擊",0.6,0.32,3,False,
  "Clawed creature swiping, fast heavy whoosh with a scraping edge, aggressive"),
 ("enemy_death","小怪倒下消散",1.0,0.75,1,False,
  "Magical creature collapsing and dissolving into crystal dust, brief body thud then a fizzing glassy disintegration fading upward"),
 ("enemy_grab","小怪抱走龍晶撤退",0.7,0.45,1,False,
  "Creature snatching a glowing crystal and fleeing, quick grab rustle, a muffled glassy chime, and scurrying steps moving away"),
 ("gatekeeper_appear","守門者出現",1.6,1.3,1,False,
  "A large armored guardian creature emerging, heavy stone-grinding steps and a deep resonant crystal roar, imposing, no words"),
 ("dragon_arrival","最終巨龍降臨",3.0,2.6,1,False,
  "Colossal dragon descending from the sky, massive slow wingbeats pushing air, ground-shaking landing thud, and a deep layered roar with crystalline magical resonance"),
 ("dragon_wing","巨龍振翅循環",2.0,2.0,1,True,
  "Giant leathery dragon wings beating slowly, deep air whoomp per beat, seamless two-beat loop"),
 ("dragon_fire","巨龍吐火",1.8,1.5,1,False,
  "Dragon breathing a torrent of magical fire, sharp ignition burst then a roaring sustained flame jet with a crackling crystal-charged undertone, decaying at the end"),
 ("dragon_hurt","巨龍受擊",0.9,0.65,1,False,
  "Dragon taking a sword hit, deep pained roar with a cracking scale impact, heavy, animal not human"),
 ("dragon_death","巨龍倒下",3.5,3.0,1,False,
  "Colossal dragon collapsing, long groaning roar falling in pitch, massive body impact on the ground, then a slow crystal resonance dissolving into silence"),

 # --- 4.5 Day, night and campaign progress ---
 ("night","入夜",1.6,1.2,1,False,
  "Nightfall in a haunted frontier, low wind swell with a distant unsettling crystal drone and a single deep bell, foreboding"),
 ("dawn","日出，顯示天數",1.8,1.5,1,False,
  "Dawn breaking after a survived night, warm rising pad with a soft bright bell and a few distant birds, relief, short"),
 ("raid_warning","日落前夜襲方向預告",1.1,0.85,1,False,
  "Warning horn from a wooden watchtower, short low horn blast with a slight crystal shimmer, alert but not panicked"),
 ("seal_progress","封印累積循環",2.5,2.5,1,True,
  "Magical seal charging loop, slow pulsing crystal hum rising in intensity with soft rune-like glassy ticks, seamless loop, building anticipation"),
 ("seal","封印完成",1.8,1.5,1,False,
  "Ancient portal sealing shut, heavy stone grinding closed, a deep magical lock thud, then a bright crystalline resolve chord, final"),
 ("kingdom","王國建立里程碑",2.4,2.0,1,False,
  "Kingdom founded milestone, three ascending bell tones with a warm resonant crystal chord blooming, ceremonial and grounded"),
 ("victory","通關勝利短句",3.4,3.0,1,False,
  "Short victory fanfare for a small pixel-art kingdom, bright bell and warm crystal motif over a soft pad, triumphant yet humble, ends cleanly, instrumental"),
 ("defeat","敗北短句",3.4,3.0,1,False,
  "Short defeat motif, slow descending bell phrase over a fading cold pad with a dying mechanical hum, mournful, ends cleanly, instrumental"),

 # --- 4.6 UI ---
 ("ui_pause","開啟暫停",0.5,0.28,1,False,
  "Soft mechanical user interface open, gentle metal latch click with a short teal shimmer, clean"),
 ("ui_resume","關閉暫停繼續遊戲",0.5,0.28,1,False,
  "Soft mechanical user interface close, reverse latch click, quick and clean"),
 ("ui_select","選單移動與滑桿刻度",0.5,0.12,1,False,
  "Tiny crystal tick for menu navigation, very short bright glassy click"),
 ("ui_confirm","確認、新旅程、載入",0.6,0.38,1,False,
  "Menu confirm, short two-tone glassy chime with a light metal tap, positive"),
 ("ui_save","手動存檔完成",0.8,0.55,1,False,
  "Saving progress, a crystal set into a stone slot with a satisfying lock click and a brief warm hum, secure"),
 ("ui_mute","切換靜音恢復",0.5,0.22,1,False,
  "Audio toggle on, soft ascending glassy blip, minimal"),
]

# (key, zh_use, seconds, prompt)
AMBIENCE = [
 ("amb_day","白天荒地",22.0,
  "Open frontier wilderness by day, continuous steady wind through dry grass, scattered distant birds throughout, a faint far-off crystal hum, calm and lonely, never silent"),
 ("amb_night","夜晚",22.0,
  "Haunted frontier at night, continuous low cold wind running throughout, steady cricket chorus, distant owl calls and a faint uneasy drone, always present and never silent, tense"),
 ("amb_campfire","營火近景",18.0,
  "Campfire burning close up, continuous steady flame roar and hiss with dense constant wood crackling and popping throughout, never silent, a subtle warm crystal reactor hum underneath, cozy"),
 ("amb_city","二級以上營地反應爐",22.0,
  "Small refuge settlement, continuous low crystal reactor hum with soft energy conduit flow, occasional wooden creak and distant tool tap, lived-in, never silent"),
 ("amb_forest","森林",22.0,
  "Dense frontier forest, continuous steady wind through thick foliage with constant leaf rustle, layered birdsong and a steady insect chorus throughout, never silent, creaking branches"),
 ("amb_crystal","晶脈",18.0,
  "Exposed crystal vein, continuous glassy resonant drone with slow shimmering overtones and tiny crystalline ticks, otherworldly, never silent"),
 ("amb_ruins","遺跡與地獄之門",22.0,
  "Ancient stone ruins with a dormant magical portal, continuous hollow wind through stone, steady low energy throb, uneasy, never silent"),
]

# (key, zh_use, ms, loop, prompt)
MUSIC = [
 ("title","起始頁",90000,True,
  "Title theme for a lonely last refuge in a dragon-ruled world, slow minor-key bell melody over a soft synth pad, distant plucked lute, faint crystal shimmer, hopeful sadness, unhurried, 70 BPM"),
 ("day_explore","白天探索荒地與森林",120000,True,
  "Daytime exploration theme, gentle wandering feel, light plucked strings and a wooden flute over warm pads, sparse soft hand drum, curious and calm, modal minor, 85 BPM"),
 ("day_refuge","白天營地建設",120000,True,
  "Refuge by day, warm and industrious, plucked strings with a simple bell motif, soft rhythmic pulse like distant hammering, gentle synth undercurrent, community and quiet hope, 90 BPM"),
 ("night_watch","夜晚守備，敵人未到",120000,True,
  "Night watch on the walls, tense and sparse, low sustained synth drone, slow cold bell tolls, distant tremolo strings, minimal percussion heartbeat, dread building slowly, 70 BPM"),
 ("night_raid","夜襲交戰疊層",120000,True,
  "Night raid combat layer, driving low percussion, pulsing bass synth, urgent string ostinato, crystalline stabs, controlled intensity rather than epic, 70 BPM, designed to layer over a quieter night theme in the same key"),
 ("dragon_boss","最終巨龍決戰",120000,True,
  "Final dragon battle, heavy but restrained, deep tribal drums, distorted low synth bass, soaring minor bell melody, dissonant crystal shimmer, relentless and desperate, 95 BPM"),
 ("victory_theme","勝利",20000,False,
  "Victory piece, bright bell melody rising over a warm pad, gentle triumphant resolution, humble and earned, ends with a soft sustained chord"),
 ("defeat_theme","敗北",15000,False,
  "Defeat piece, slow descending bell phrase over a cold fading pad and a dying mechanical hum, mournful, ends in near silence"),
 ("dawn_sting","日出短樂句",10000,False,
  "Dawn stinger, a single warm rising bell phrase with soft pad swell and faint birdsong, relief after a long night, short"),
]

SFX_PROMPT_LIMIT = 450


def sfx_prompt(prompt: str) -> str:
    return _checked(f"{prompt}. {SFX_BASE} {SFX_NEGATIVE}")


def ambience_prompt(prompt: str) -> str:
    return _checked(f"{prompt}. {AMBIENCE_BASE}")


def _checked(text: str) -> str:
    """The sound API rejects anything past 450 characters; fail loudly, never silently truncated."""
    if len(text) > SFX_PROMPT_LIMIT:
        raise ValueError(f"prompt is {len(text)} characters, over the {SFX_PROMPT_LIMIT} limit: {text[:60]}...")
    return text

def music_prompt(prompt: str) -> str:
    return f"{prompt}. {MUSIC_BASE}"

def sfx_files():
    """Yield (filename, key, variant_index, request_seconds, target_seconds, loop, prompt)."""
    for key, _zh, req, target, variants, loop, prompt in SFX:
        for index in range(variants):
            name = key if variants == 1 else f"{key}_{index+1}"
            yield name, key, index, req, target, loop, prompt

def totals():
    sfx = sum(item[4] for item in SFX)
    return {"sfx_entries": len(SFX), "sfx_files": sfx,
            "ambience": len(AMBIENCE), "music": len(MUSIC),
            "files": sfx + len(AMBIENCE) + len(MUSIC)}

if __name__ == "__main__":
    print(totals())
