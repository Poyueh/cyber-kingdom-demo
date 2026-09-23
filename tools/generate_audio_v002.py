#!/usr/bin/env python3
"""Generate the v002 audio set with the ElevenLabs API.

Reads every prompt from tools/audio_v002_manifest.py, writes raw responses plus a
provenance record. Re-running skips files that already exist, so a failed batch resumes.

Usage: ELEVENLABS_API_KEY=... python3 tools/generate_audio_v002.py --raw-dir <dir> [--only sfx|ambience|music]
"""
import argparse, hashlib, json, os, sys, threading, time, urllib.error, urllib.request
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import audio_v002_manifest as M

SFX_URL = "https://api.elevenlabs.io/v1/sound-generation?output_format=pcm_44100"
MUSIC_URL = "https://api.elevenlabs.io/v1/music?output_format=mp3_44100_192"
SFX_MODEL = "eleven_text_to_sound_v2"
MUSIC_MODEL = "eleven_music_v1"
PROMPT_INFLUENCE = 0.55
_lock = threading.Lock()


def _post(url: str, body: dict, key: str, attempts: int = 4) -> bytes:
    data = json.dumps(body).encode()
    for attempt in range(attempts):
        request = urllib.request.Request(
            url, data=data, headers={"xi-api-key": key, "Content-Type": "application/json"})
        try:
            return urllib.request.urlopen(request, timeout=600).read()
        except urllib.error.HTTPError as error:
            detail = error.read()[:300].decode("utf-8", "replace")
            if error.code in (429, 500, 502, 503, 504) and attempt < attempts - 1:
                time.sleep(4 * (attempt + 1))
                continue
            raise RuntimeError(f"HTTP {error.code} {detail}") from None
        except (urllib.error.URLError, TimeoutError):
            if attempt < attempts - 1:
                time.sleep(4 * (attempt + 1))
                continue
            raise
    raise RuntimeError("unreachable")


def _record(raw_dir: Path, name: str, entry: dict) -> None:
    with _lock:
        path = raw_dir / "provenance-raw.json"
        current = json.loads(path.read_text()) if path.exists() else {}
        current[name] = entry
        path.write_text(json.dumps(current, ensure_ascii=False, indent=1, sort_keys=True))


def generate_sfx(raw_dir: Path, key: str, item) -> str:
    name, _base, variant, request_seconds, _target, loop, prompt = item
    out = raw_dir / f"{name}.pcm"
    if out.exists() and out.stat().st_size > 0:
        return f"skip {name}"
    text = M.sfx_prompt(prompt)
    body = {"text": text, "duration_seconds": round(request_seconds, 2),
            "prompt_influence": PROMPT_INFLUENCE, "loop": loop}
    audio = _post(SFX_URL, body, key)
    out.write_bytes(audio)
    _record(raw_dir, name, {
        "category": "sfx", "model": SFX_MODEL, "prompt": text, "variant": variant + 1,
        "request_seconds": request_seconds, "loop": loop, "prompt_influence": PROMPT_INFLUENCE,
        "raw_format": "pcm_s16le_44100_stereo", "bytes": len(audio),
        "sha256": hashlib.sha256(audio).hexdigest(),
        "generated_utc": datetime.now(timezone.utc).isoformat(timespec="seconds")})
    return f"ok   {name} ({len(audio)} bytes)"


def generate_ambience(raw_dir: Path, key: str, item) -> str:
    name, _zh, seconds, prompt = item
    out = raw_dir / f"{name}.pcm"
    if out.exists() and out.stat().st_size > 0:
        return f"skip {name}"
    text = M.ambience_prompt(prompt)
    body = {"text": text, "duration_seconds": round(seconds, 2),
            "prompt_influence": PROMPT_INFLUENCE, "loop": True}
    audio = _post(SFX_URL, body, key)
    out.write_bytes(audio)
    _record(raw_dir, name, {
        "category": "ambience", "model": SFX_MODEL, "prompt": text,
        "request_seconds": seconds, "loop": True, "prompt_influence": PROMPT_INFLUENCE,
        "raw_format": "pcm_s16le_44100_stereo", "bytes": len(audio),
        "sha256": hashlib.sha256(audio).hexdigest(),
        "generated_utc": datetime.now(timezone.utc).isoformat(timespec="seconds")})
    return f"ok   {name} ({len(audio)} bytes)"


def generate_music(raw_dir: Path, key: str, item) -> str:
    name, _zh, milliseconds, loop, prompt = item
    out = raw_dir / f"{name}.mp3"
    if out.exists() and out.stat().st_size > 0:
        return f"skip {name}"
    text = M.music_prompt(prompt)
    body = {"prompt": text, "music_length_ms": milliseconds}
    audio = _post(MUSIC_URL, body, key)
    out.write_bytes(audio)
    _record(raw_dir, name, {
        "category": "music", "model": MUSIC_MODEL, "prompt": text,
        "request_ms": milliseconds, "loop": loop, "raw_format": "mp3_44100_192",
        "bytes": len(audio), "sha256": hashlib.sha256(audio).hexdigest(),
        "generated_utc": datetime.now(timezone.utc).isoformat(timespec="seconds")})
    return f"ok   {name} ({len(audio)} bytes)"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--raw-dir", required=True)
    parser.add_argument("--only", choices=["sfx", "ambience", "music"])
    parser.add_argument("--workers", type=int, default=3)
    arguments = parser.parse_args()
    key = os.environ.get("ELEVENLABS_API_KEY")
    if not key:
        print("ELEVENLABS_API_KEY is not set", file=sys.stderr)
        return 2
    raw_dir = Path(arguments.raw_dir)
    raw_dir.mkdir(parents=True, exist_ok=True)

    jobs = []
    if arguments.only in (None, "sfx"):
        jobs += [(generate_sfx, item) for item in M.sfx_files()]
    if arguments.only in (None, "ambience"):
        jobs += [(generate_ambience, item) for item in M.AMBIENCE]
    if arguments.only in (None, "music"):
        jobs += [(generate_music, item) for item in M.MUSIC]

    failures = []
    with ThreadPoolExecutor(max_workers=arguments.workers) as pool:
        futures = {pool.submit(function, raw_dir, key, item): item for function, item in jobs}
        for future in futures:
            item = futures[future]
            try:
                print(future.result(), flush=True)
            except Exception as error:
                failures.append((item[0], str(error)))
                print(f"FAIL {item[0]}: {error}", flush=True)
    print(f"\n{len(jobs) - len(failures)}/{len(jobs)} generated, {len(failures)} failed")
    for name, error in failures:
        print(f"  {name}: {error}")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
