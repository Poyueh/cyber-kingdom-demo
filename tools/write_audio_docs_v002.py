#!/usr/bin/env python3
"""Write the v002 audio provenance files and the reviewable prompt catalogue.

Everything here is derived from tools/audio_v002_manifest.py and the measurement
report, so the documents cannot drift from what was actually generated.

Usage: python3 tools/write_audio_docs_v002.py
"""
import hashlib, json, sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import audio_v002_manifest as M

ROOT = Path(__file__).resolve().parent.parent
MEASURE = ROOT / "docs/reports/campaign-audio-v002/measurements.json"
VOICE = ROOT / "docs/reports/campaign-audio-v002/voice-screen.json"
CATALOGUE = ROOT / "docs/design/campaign-audio-v002-catalogue.md"
DIRS = {"sfx": ROOT / "art/audio/campaign-v002",
        "ambience": ROOT / "art/audio/ambience-v002",
        "music": ROOT / "art/audio/music-v002"}
SOURCE = {"sfx": "ElevenLabs Text to Sound Effects (eleven_text_to_sound_v2)",
          "ambience": "ElevenLabs Text to Sound Effects (eleven_text_to_sound_v2)",
          "music": "ElevenLabs Music (eleven_music_v1)"}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def entries() -> dict:
    rows = {}
    for name, base, variant, request_seconds, target, loop, prompt in M.sfx_files():
        zh = next(item[1] for item in M.SFX if item[0] == base)
        rows[name] = {"category": "sfx", "use": zh, "prompt": M.sfx_prompt(prompt),
                      "request_seconds": request_seconds, "design_seconds": target,
                      "variant": variant + 1, "loop": loop,
                      "file": f"art/audio/campaign-v002/{name}.wav"}
    for name, zh, seconds, prompt in M.AMBIENCE:
        rows[name] = {"category": "ambience", "use": zh, "prompt": M.ambience_prompt(prompt),
                      "request_seconds": seconds, "loop": True,
                      "file": f"art/audio/ambience-v002/{name}.ogg"}
    for name, zh, milliseconds, loop, prompt in M.MUSIC:
        rows[name] = {"category": "music", "use": zh, "prompt": M.music_prompt(prompt),
                      "request_seconds": milliseconds / 1000.0, "loop": loop,
                      "file": f"art/audio/music-v002/{name}.ogg"}
    return rows


def main() -> int:
    measurements = json.loads(MEASURE.read_text())["files"] if MEASURE.exists() else {}
    voice = json.loads(VOICE.read_text()) if VOICE.exists() else {"files": {}}
    rows = entries()

    for category, directory in DIRS.items():
        payload = {}
        for name, row in rows.items():
            if row["category"] != category:
                continue
            path = ROOT / row["file"]
            record = dict(row)
            record["source"] = SOURCE[category]
            record["measured"] = measurements.get(name, {})
            screen = voice["files"].get(name, {})
            record["voice_screen"] = {"model": voice.get("model"),
                                      "transcribed_words": screen.get("word_count"),
                                      "transcript": screen.get("text")}
            if path.exists():
                record["sha256"] = digest(path)
            payload[name] = record
        directory.mkdir(parents=True, exist_ok=True)
        (directory / "provenance.json").write_text(
            json.dumps({"set": "cyber-kingdom audio v002", "written": date.today().isoformat(),
                        "note": "Generated from prompts; no recordings, samples or third-party audio.",
                        "files": payload}, ensure_ascii=False, indent=1, sort_keys=True))

    lines = ["# 音效與音樂 v002 素材目錄（含完整生成 prompt）", "",
             f"> 由 `tools/write_audio_docs_v002.py` 依 `tools/audio_v002_manifest.py` 產生，"
             f"更新日期 {date.today().isoformat()}。要改任何一條就改 manifest 再重跑，不要手改本檔。", "",
             "全部素材以 ElevenLabs 依下列 prompt 生成，沒有任何錄音、取樣或第三方音源。",
             "音效與環境音用 Text to Sound Effects，音樂用 Music；共用前綴與負面詞見第一節。", ""]

    lines += ["## 共用 prompt 片段", "",
              "音效與環境音、音樂各自在下表的 prompt 後面（或前面）串上這些固定句，實際送出的完整字串記在各目錄的 `provenance.json`。", "",
              "| 用途 | 內容 |", "| --- | --- |",
              f"| 音效共同後綴 | {M.SFX_BASE} |",
              f"| 音效負面詞 | {M.SFX_NEGATIVE} |",
              f"| 環境音共同後綴 | {M.AMBIENCE_BASE} |",
              f"| 音樂共同後綴 | {M.MUSIC_BASE} |", ""]

    titles = {"sfx": "音效", "ambience": "環境音循環", "music": "音樂"}
    for category in ("sfx", "ambience", "music"):
        group = {name: row for name, row in rows.items() if row["category"] == category}
        lines += [f"## {titles[category]}（{len(group)} 個檔）", "",
                  "| 檔名 | 用途 | 長度 | 音量 | prompt（未含共用後綴） |",
                  "| --- | --- | --- | --- | --- |"]
        for name in sorted(group):
            row, measured = group[name], measurements.get(name, {})
            seconds = measured.get("seconds")
            length = f"{seconds:.2f} s" if seconds else "-"
            if category == "sfx":
                level = f"峰值 {measured.get('peak_db', '-')} dBFS"
            else:
                level = f"{measured.get('lufs', '-')} LUFS"
            core = row["prompt"]
            for tail in (M.SFX_BASE, M.SFX_NEGATIVE, M.AMBIENCE_BASE, M.MUSIC_BASE):
                core = core.replace(tail, "")
            core = core.strip().rstrip(".").strip()
            loop = " · 循環" if row.get("loop") else ""
            lines.append(f"| `{name}` | {row['use']}{loop} | {length} | {level} | {core} |")
        lines.append("")

    CATALOGUE.write_text("\n".join(lines))
    print(f"wrote {CATALOGUE.relative_to(ROOT)} and {len(DIRS)} provenance files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
