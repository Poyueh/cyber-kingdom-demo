#!/usr/bin/env python3
"""Trim, fade, normalise and convert the raw v002 audio into the shipped game assets.

No synthesis happens here: every sample comes from the raw ElevenLabs response.
Sound effects become mono 16-bit WAV, ambience and music become OGG. Looping
assets get a tail-to-head crossfade so they repeat without a seam.

Usage: python3 tools/process_audio_v002.py --raw-dir <dir> [--skip-existing]
"""
import argparse, json, re, subprocess, sys, tempfile, wave
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import audio_v002_manifest as M

RATE = 44100
ROOT = Path(__file__).resolve().parent.parent
SFX_DIR = ROOT / "art/audio/campaign-v002"
AMBIENCE_DIR = ROOT / "art/audio/ambience-v002"
MUSIC_DIR = ROOT / "art/audio/music-v002"
SFX_PEAK_DB = -6.0
AMBIENCE_LUFS = -30.0          # ambience is a bed under music and effects
AMBIENCE_CEILING_DB = -9.0
MUSIC_LUFS = -16.0
MUSIC_CEILING_DB = -6.0
LOOP_CROSSFADE = 1.5          # seconds folded from the tail back into the head
SILENCE_FLOOR = 10 ** (-45.0 / 20.0)


def read_pcm(path: Path) -> np.ndarray:
    raw = np.frombuffer(path.read_bytes(), dtype="<i2").astype(np.float32) / 32768.0
    return raw.reshape(-1, 2)


def decode_mp3(path: Path) -> np.ndarray:
    result = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", str(path), "-f", "f32le", "-ac", "2", "-ar", str(RATE), "-"],
        check=True, capture_output=True)
    return np.frombuffer(result.stdout, dtype="<f4").reshape(-1, 2)


def to_mono(samples: np.ndarray) -> np.ndarray:
    return samples.mean(axis=1)


def trim_silence(samples: np.ndarray, keep_tail: bool) -> np.ndarray:
    envelope = np.abs(samples if samples.ndim == 1 else samples.max(axis=1))
    window = max(1, RATE // 1000)
    smooth = np.convolve(envelope, np.ones(window) / window, mode="same")
    loud = np.nonzero(smooth > SILENCE_FLOOR)[0]
    if loud.size == 0:
        return samples
    start = max(0, loud[0] - window)
    stop = len(samples) if keep_tail else min(len(samples), loud[-1] + window * 4)
    return samples[start:stop]


def fit_length(samples: np.ndarray, seconds: float) -> np.ndarray:
    """Cut to the design length, but never cut a sound that is already shorter."""
    wanted = int(round(seconds * RATE))
    return samples[:wanted] if len(samples) > wanted else samples


def fade(samples: np.ndarray, in_ms: float, out_ms: float) -> np.ndarray:
    out = samples.astype(np.float32).copy()
    head = min(int(RATE * in_ms / 1000), len(out) // 2)
    tail = min(int(RATE * out_ms / 1000), len(out) // 2)
    if head:
        ramp = np.linspace(0.0, 1.0, head, dtype=np.float32)
        out[:head] = (out[:head].T * ramp).T if out.ndim > 1 else out[:head] * ramp
    if tail:
        ramp = np.linspace(1.0, 0.0, tail, dtype=np.float32)
        out[-tail:] = (out[-tail:].T * ramp).T if out.ndim > 1 else out[-tail:] * ramp
    return out


def seamless_loop(samples: np.ndarray, crossfade: float) -> np.ndarray:
    """Fold the tail back over the head so the end matches the start."""
    length = min(int(crossfade * RATE), len(samples) // 3)
    if length < RATE // 20:
        return samples
    body = samples[:-length].astype(np.float32).copy()
    tail = samples[-length:].astype(np.float32)
    ramp = np.linspace(0.0, 1.0, length, dtype=np.float32)
    if samples.ndim > 1:
        body[:length] = (body[:length].T * ramp + tail.T * (1.0 - ramp)).T
    else:
        body[:length] = body[:length] * ramp + tail * (1.0 - ramp)
    return body


def normalise(samples: np.ndarray, peak_db: float) -> np.ndarray:
    peak = float(np.abs(samples).max())
    if peak <= 0:
        return samples
    return (samples * (10 ** (peak_db / 20.0) / peak)).astype(np.float32)


def measure_lufs(samples: np.ndarray) -> float | None:
    """Integrated loudness through ffmpeg's EBU R128 meter."""
    channels = 1 if samples.ndim == 1 else samples.shape[1]
    payload = (np.clip(samples, -1.0, 1.0) * 32767.0).astype("<i2").tobytes()
    result = subprocess.run(
        ["ffmpeg", "-v", "info", "-f", "s16le", "-ar", str(RATE), "-ac", str(channels),
         "-i", "-", "-filter:a", "ebur128=framelog=quiet", "-f", "null", "-"],
        input=payload, capture_output=True)
    found = re.search(r"I:\s*(-?\d+(?:\.\d+)?)\s*LUFS", result.stderr.decode("utf-8", "replace"))
    return float(found.group(1)) if found else None


def soft_limit(samples: np.ndarray, ceiling_db: float, max_reduction_db: float) -> np.ndarray:
    """Hold peaks under the ceiling with a smoothed gain curve instead of hard clipping."""
    ceiling = 10 ** (ceiling_db / 20.0)
    envelope = np.abs(samples if samples.ndim == 1 else np.abs(samples).max(axis=1))
    window = int(RATE * 0.01)
    if window > 1:
        padded = np.pad(envelope, (window, window), mode="edge")
        strided = np.lib.stride_tricks.sliding_window_view(padded, 2 * window + 1)
        envelope = strided.max(axis=1)[: len(samples)]
    floor = 10 ** (-max_reduction_db / 20.0)
    gain = np.clip(ceiling / np.maximum(envelope, 1e-9), floor, 1.0).astype(np.float32)
    smooth = int(RATE * 0.02)
    if smooth > 1:
        kernel = np.ones(smooth, dtype=np.float32) / smooth
        gain = np.convolve(np.pad(gain, (smooth, smooth), mode="edge"), kernel, mode="same")[smooth:smooth + len(samples)]
    return (samples * (gain if samples.ndim == 1 else gain[:, None])).astype(np.float32)


def normalise_loudness(samples: np.ndarray, lufs: float, ceiling_db: float,
                       max_reduction_db: float = 6.0) -> np.ndarray:
    """Match perceived loudness, then hold peaks down with a gentle limiter."""
    measured = measure_lufs(samples)
    if measured is None:
        return samples
    out = (samples * 10 ** ((lufs - measured) / 20.0)).astype(np.float32)
    out = soft_limit(out, ceiling_db, max_reduction_db)
    peak = float(np.abs(out).max())
    if peak > 10 ** (ceiling_db / 20.0):
        out = out * (10 ** (ceiling_db / 20.0) / peak)
    return out.astype(np.float32)


def write_wav(path: Path, samples: np.ndarray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    data = np.clip(samples, -1.0, 1.0)
    with wave.open(str(path), "wb") as handle:
        handle.setnchannels(1 if data.ndim == 1 else data.shape[1])
        handle.setsampwidth(2)
        handle.setframerate(RATE)
        handle.writeframes((data * 32767.0).astype("<i2").tobytes())


def write_ogg(path: Path, samples: np.ndarray, quality: str) -> None:
    """Encode through oggenc; Godot imports Ogg Vorbis as a seamlessly loopable stream."""
    path.parent.mkdir(parents=True, exist_ok=True)
    channels = 1 if samples.ndim == 1 else samples.shape[1]
    data = np.clip(samples, -1.0, 1.0)
    payload = (data * 32767.0).astype("<i2").tobytes()
    subprocess.run(
        ["oggenc", "-Q", "-r", "-B", "16", "-C", str(channels), "-R", str(RATE),
         "-q", quality, "-o", str(path), "-"],
        input=payload, check=True, capture_output=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--raw-dir", required=True)
    parser.add_argument("--skip-existing", action="store_true")
    arguments = parser.parse_args()
    raw_dir = Path(arguments.raw_dir)
    report = {}

    for name, base, _variant, _request, target, loop, _prompt in M.sfx_files():
        destination = SFX_DIR / f"{name}.wav"
        if arguments.skip_existing and destination.exists():
            continue
        samples = to_mono(read_pcm(raw_dir / f"{name}.pcm"))
        samples = trim_silence(samples, keep_tail=loop)
        if loop:
            samples = seamless_loop(samples, 0.25)
            samples = normalise(samples, SFX_PEAK_DB)
        else:
            samples = fit_length(samples, target)
            samples = fade(samples, 2.0, 12.0)
            samples = normalise(samples, SFX_PEAK_DB)
        write_wav(destination, samples)
        report[name] = {"category": "sfx", "base": base, "loop": loop,
                        "seconds": round(len(samples) / RATE, 3)}

    for name, _zh, _seconds, _prompt in M.AMBIENCE:
        destination = AMBIENCE_DIR / f"{name}.ogg"
        if arguments.skip_existing and destination.exists():
            continue
        samples = to_mono(read_pcm(raw_dir / f"{name}.pcm"))
        samples = seamless_loop(samples, LOOP_CROSSFADE)
        samples = normalise_loudness(samples, AMBIENCE_LUFS, AMBIENCE_CEILING_DB,
                                     max_reduction_db=10.0)
        write_ogg(destination, samples, "4")
        report[name] = {"category": "ambience", "loop": True,
                        "seconds": round(len(samples) / RATE, 3)}

    for name, _zh, _ms, loop, _prompt in M.MUSIC:
        destination = MUSIC_DIR / f"{name}.ogg"
        if arguments.skip_existing and destination.exists():
            continue
        samples = decode_mp3(raw_dir / f"{name}.mp3")
        if loop:
            samples = trim_silence(samples, keep_tail=True)
            samples = seamless_loop(samples, LOOP_CROSSFADE)
        else:
            samples = trim_silence(samples, keep_tail=False)
            samples = fade(samples, 10.0, 350.0)
        samples = normalise_loudness(samples, MUSIC_LUFS, MUSIC_CEILING_DB)
        write_ogg(destination, samples, "5")
        report[name] = {"category": "music", "loop": loop,
                        "seconds": round(len(samples) / RATE, 3)}

    print(json.dumps(report, indent=1, sort_keys=True))
    print(f"\nprocessed {len(report)} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
