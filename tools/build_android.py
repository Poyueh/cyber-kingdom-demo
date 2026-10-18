#!/usr/bin/env python3
"""Build a debug-signed ARM64 APK from a committed tree; no release credentials."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import tempfile
import shutil
from build_desktop import prepare_tree, run_logged

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ref", default="HEAD")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--godot", default="/Applications/Godot.app/Contents/MacOS/Godot")
    parser.add_argument("--debug-key", type=Path, default=Path.home()/".android/cyber-kingdom-debug.keystore")
    parser.add_argument("--edition", choices=["full","demo"])
    args = parser.parse_args()
    if not args.debug_key.is_file():
        parser.error("Provide the local Android debug keystore; do not use a release key.")
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    os.environ["GODOT_ANDROID_KEYSTORE_DEBUG_PATH"] = str(args.debug_key.resolve())
    os.environ["GODOT_ANDROID_KEYSTORE_DEBUG_USER"] = "androiddebugkey"
    os.environ["GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD"] = "android"
    with tempfile.TemporaryDirectory(prefix="cyber-android-") as folder:
        stage = Path(folder)
        tree = prepare_tree(args.ref, stage, args.edition)
        shutil.copyfile(stage / "distribution-manifest.json", output / "distribution-manifest.json")
        engine = [args.godot, "--headless", "--path", str(stage)]
        run_logged(engine+["--editor", "--import"], output/"import.log")
        apk = output/"Cyber-Kingdom-Android-debug.apk"
        run_logged(engine+["--export-debug", "Android Demo", str(apk)], output/"export.log")
        (output/"manifest.json").write_text(json.dumps({
            "source_tree": tree, "architecture": "arm64-v8a", "package": "org.cyberkingdom.forestdemo" if json.loads((output/"distribution-manifest.json").read_text())["edition"]=="demo" else "org.cyberkingdom.demo",
            "signing": "local debug certificate; not a store release",
            "sha256": hashlib.sha256(apk.read_bytes()).hexdigest(),
            "runtime_playtest": "record separately; export alone is not validation"
        }, indent=2)+"\n")
    print("Built Android debug APK at", apk)

if __name__ == "__main__":
    main()
