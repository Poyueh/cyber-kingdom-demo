#!/usr/bin/env python3
"""Measure every shipped v002 audio asset: levels, format, length and loop seams.

Runs offline. Voice screening lives in tools/check_audio_voice_v002.py because it
needs the ElevenLabs API.

Usage: python3 tools/verify_audio_v002.py [--json <path>]
"""
import argparse, json, re, subprocess, sys, wave
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import audio_v002_manifest as M

RATE = 44100
ROOT = Path(__file__).resolve().parent.parent
SFX_PEAK_DB = -6.0
PEAK_TOLERANCE = 0.6
AMBIENCE_LUFS = -30.0
MUSIC_LUFS = -16.0
LUFS_TOLERANCE = 1.5
SEAM_RATIO_LIMIT = 3.0


def decode(path: Path) -> tuple[np.ndarray, int, int]:
    if path.suffix == ".wav":
        with wave.open(str(path), "rb") as handle:
            channels, rate, frames = handle.getnchannels(), handle.getframerate(), handle.getnframes()
            raw = np.frombuffer(handle.readframes(frames), dtype="<i2").astype(np.float32) / 32768.0
        return (raw.reshape(-1, channels) if channels > 1 else raw), rate, channels
    probe = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "stream=channels,sample_rate",
         "-of", "json", str(path)], check=True, capture_output=True)
    stream = json.loads(probe.stdout)["streams"][0]
    channels, rate = int(stream["channels"]), int(stream["sample_rate"])
    result = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", str(path), "-f", "f32le", "-ac", str(channels), "-"],
        check=True, capture_output=True)
    raw = np.frombuffer(result.stdout, dtype="<f4")
    return (raw.reshape(-1, channels) if channels > 1 else raw), rate, channels


def loudness(path: Path) -> float | None:
    result = subprocess.run(
        ["ffmpeg", "-v", "info", "-i", str(path), "-filter:a", "ebur128=framelog=quiet",
         "-f", "null", "-"], capture_output=True)
    found = re.search(r"I:\s*(-?\d+(?:\.\d+)?)\s*LUFS", result.stderr.decode("utf-8", "replace"))
    return float(found.group(1)) if found else None


def seam_ratio(mono: np.ndarray) -> float:
    """How far the wrap step stands out from the file's own sample-to-sample motion.

    A crossfaded loop wraps onto consecutive source samples, so the step should sit
    inside the normal range. A ratio well above 1 means an audible click.
    """
    if len(mono) < 4:
        return 0.0
    step = abs(float(mono[0]) - float(mono[-1]))
    normal = float(np.percentile(np.abs(np.diff(mono)), 99))
    return step / normal if normal > 0 else 0.0


def planned() -> dict:
    items = {}
    for name, base, _v, _r, target, loop, _p in M.sfx_files():
        items[name] = {"category": "sfx", "path": ROOT / f"art/audio/campaign-v002/{name}.wav",
                       "base": base, "target_seconds": target, "loop": loop, "channels": 1}
    for name, _zh, seconds, _p in M.AMBIENCE:
        items[name] = {"category": "ambience", "path": ROOT / f"art/audio/ambience-v002/{name}.ogg",
                       "base": name, "target_seconds": seconds, "loop": True, "channels": 1}
    for name, _zh, ms, loop, _p in M.MUSIC:
        items[name] = {"category": "music", "path": ROOT / f"art/audio/music-v002/{name}.ogg",
                       "base": name, "target_seconds": ms / 1000.0, "loop": loop, "channels": 2}
    return items


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", default="docs/reports/campaign-audio-v002/measurements.json")
    arguments = parser.parse_args()

    rows, problems = {}, []
    for name, plan in sorted(planned().items()):
        path = plan["path"]
        if not path.exists():
            problems.append(f"{name}: missing {path.relative_to(ROOT)}")
            continue
        samples, rate, channels = decode(path)
        mono = samples if samples.ndim == 1 else samples.mean(axis=1)
        peak = float(np.abs(samples).max())
        peak_db = 20 * np.log10(peak) if peak > 0 else -120.0
        rms = float(np.sqrt(np.mean(mono ** 2)))
        clipped = int((np.abs(samples) >= 0.999).sum())
        seconds = len(mono) / rate
        row = {"category": plan["category"], "seconds": round(seconds, 3), "rate": rate,
               "channels": channels, "peak_db": round(peak_db, 2),
               "rms_db": round(20 * np.log10(rms) if rms > 0 else -120.0, 2),
               "clipped_samples": clipped, "loop": plan["loop"], "bytes": path.stat().st_size}
        if plan["category"] in ("ambience", "music"):
            row["lufs"] = loudness(path)
        if plan["loop"]:
            row["loop_seam_ratio"] = round(seam_ratio(mono), 2)
        rows[name] = row

        if rate != RATE:
            problems.append(f"{name}: sample rate {rate}, expected {RATE}")
        if channels != plan["channels"]:
            problems.append(f"{name}: {channels} channels, expected {plan['channels']}")
        if clipped:
            problems.append(f"{name}: {clipped} clipped samples")
        if rms <= 0 or 20 * np.log10(rms) < -55:
            problems.append(f"{name}: near silent, RMS {row['rms_db']} dBFS")
        if plan["category"] == "sfx":
            if abs(peak_db - SFX_PEAK_DB) > PEAK_TOLERANCE:
                problems.append(f"{name}: peak {peak_db:.2f} dBFS, expected {SFX_PEAK_DB:+.1f}")
            if seconds > plan["target_seconds"] + 0.35:
                problems.append(f"{name}: {seconds:.2f}s, longer than the planned {plan['target_seconds']:.2f}s")
        else:
            wanted = AMBIENCE_LUFS if plan["category"] == "ambience" else MUSIC_LUFS
            measured = row.get("lufs")
            if measured is None:
                problems.append(f"{name}: loudness could not be measured")
            elif abs(measured - wanted) > LUFS_TOLERANCE:
                problems.append(f"{name}: {measured:.1f} LUFS, expected {wanted:+.0f} +/- {LUFS_TOLERANCE}")
            if peak_db > -4.0:
                problems.append(f"{name}: peak {peak_db:.2f} dBFS leaves no headroom")
        if plan["loop"] and row.get("loop_seam_ratio", 0.0) > SEAM_RATIO_LIMIT:
            problems.append(f"{name}: loop seam step {row['loop_seam_ratio']}x the normal sample motion")

    out = Path(arguments.json)
    if not out.is_absolute():
        out = ROOT / out
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps({"files": rows, "problems": problems},
                              ensure_ascii=False, indent=1, sort_keys=True))

    print(f"measured {len(rows)} files -> {out.relative_to(ROOT)}")
    for category, unit in (("sfx", "peak dBFS"), ("ambience", "LUFS"), ("music", "LUFS")):
        group = [row for row in rows.values() if row["category"] == category]
        if not group:
            continue
        values = ([row["peak_db"] for row in group] if category == "sfx"
                  else [row["lufs"] for row in group if row.get("lufs") is not None])
        seams = [row["loop_seam_ratio"] for row in group if "loop_seam_ratio" in row]
        line = f"  {category:9s} n={len(group):3d}  {unit} {min(values):+.1f}..{max(values):+.1f}"
        if seams:
            line += f"  worst loop seam {max(seams):.2f}x"
        print(line)
    print(f"problems: {len(problems)}")
    for problem in problems:
        print(f"  {problem}")
    return 1 if problems else 0


if __name__ == "__main__":
    raise SystemExit(main())
