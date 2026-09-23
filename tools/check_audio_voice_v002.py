#!/usr/bin/env python3
"""Screen the shipped v002 audio for unwanted voice by transcribing it.

The brief is instrumental music and wordless effects. Running speech-to-text over
every asset catches sung or spoken words: a validated control clip of deliberately
sung lyrics returns a full transcript, while the instrumental tracks return none.

Wordless humming can still slip past a transcriber, so the companion spectrograms
in docs/reports/campaign-audio-v002/ exist for a visual pass, and a human listen
remains the final word.

Usage: ELEVENLABS_API_KEY=... python3 tools/check_audio_voice_v002.py [--json <path>]
"""
import argparse, json, os, subprocess, sys, tempfile, threading, urllib.error, urllib.request, uuid
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import audio_v002_manifest as M

ROOT = Path(__file__).resolve().parent.parent
STT_URL = "https://api.elevenlabs.io/v1/speech-to-text"
STT_MODEL = "scribe_v1"
_print_lock = threading.Lock()


MIN_SECONDS = 1.2


def padded(path: Path) -> bytes:
    """The transcriber rejects very short clips, so pad them with trailing silence."""
    probe = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of",
         "default=nw=1:nk=1", str(path)], check=True, capture_output=True)
    seconds = float(probe.stdout.strip() or 0)
    if seconds >= MIN_SECONDS:
        return path.read_bytes()
    with tempfile.NamedTemporaryFile(suffix=".wav") as handle:
        subprocess.run(
            ["ffmpeg", "-v", "error", "-y", "-i", str(path), "-af",
             f"apad=whole_dur={MIN_SECONDS + 0.3}", handle.name],
            check=True, capture_output=True)
        return Path(handle.name).read_bytes()


def transcribe(path: Path, key: str) -> dict:
    boundary = uuid.uuid4().hex
    body = b""
    for field, value in (("model_id", STT_MODEL),):
        body += (f"--{boundary}\r\nContent-Disposition: form-data; "
                 f"name=\"{field}\"\r\n\r\n{value}\r\n").encode()
    body += (f"--{boundary}\r\nContent-Disposition: form-data; name=\"file\"; "
             f"filename=\"{path.name}\"\r\nContent-Type: application/octet-stream\r\n\r\n").encode()
    body += padded(path) + f"\r\n--{boundary}--\r\n".encode()
    request = urllib.request.Request(
        STT_URL, data=body,
        headers={"xi-api-key": key,
                 "Content-Type": f"multipart/form-data; boundary={boundary}"})
    try:
        payload = json.load(urllib.request.urlopen(request, timeout=300))
    except urllib.error.HTTPError as error:
        return {"error": f"HTTP {error.code} {error.read()[:160].decode('utf-8', 'replace')}"}
    words = [word for word in payload.get("words", []) if word.get("type") == "word"]
    return {"text": (payload.get("text") or "").strip(), "word_count": len(words),
            "words": [word.get("text", "") for word in words[:12]]}


def assets() -> list[tuple[str, str, Path]]:
    items = [(name, "sfx", ROOT / f"art/audio/campaign-v002/{name}.wav")
             for name, *_rest in M.sfx_files()]
    items += [(name, "ambience", ROOT / f"art/audio/ambience-v002/{name}.ogg")
              for name, *_rest in M.AMBIENCE]
    items += [(name, "music", ROOT / f"art/audio/music-v002/{name}.ogg")
              for name, *_rest in M.MUSIC]
    return items


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", default="docs/reports/campaign-audio-v002/voice-screen.json")
    parser.add_argument("--workers", type=int, default=4)
    arguments = parser.parse_args()
    key = os.environ.get("ELEVENLABS_API_KEY")
    if not key:
        print("ELEVENLABS_API_KEY is not set", file=sys.stderr)
        return 2

    rows = {}

    def run(item):
        name, category, path = item
        if not path.exists():
            return name, {"error": "missing file", "category": category}
        result = transcribe(path, key)
        result["category"] = category
        with _print_lock:
            flag = "WORDS" if result.get("word_count") else "     "
            print(f"  {flag} {name:20s} {result.get('text','')[:70]!r}", flush=True)
        return name, result

    with ThreadPoolExecutor(max_workers=arguments.workers) as pool:
        for name, result in pool.map(run, assets()):
            rows[name] = result

    suspects = sorted(name for name, row in rows.items() if row.get("word_count"))
    errors = sorted(name for name, row in rows.items() if row.get("error"))

    out = Path(arguments.json)
    if not out.is_absolute():
        out = ROOT / out
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps({"model": STT_MODEL, "files": rows, "suspects": suspects,
                               "errors": errors}, ensure_ascii=False, indent=1, sort_keys=True))

    print(f"\nscreened {len(rows)} files -> {out.relative_to(ROOT)}")
    print(f"files with transcribed words: {len(suspects)}")
    for name in suspects:
        print(f"  {name}: {rows[name]['text'][:100]!r}")
    print(f"transcription errors: {len(errors)}")
    for name in errors:
        print(f"  {name}: {rows[name]['error']}")
    return 1 if suspects or errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
