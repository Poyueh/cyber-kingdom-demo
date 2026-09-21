#!/usr/bin/env bash
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
if [ ! -x "$GODOT_BIN" ]; then
  echo 'Set GODOT_BIN to your Godot 4 executable.' >&2
  exit 1
fi
mkdir -p "$ROOT/test-results"
run_check() {
  local name="$1"
  shift
  local result=0
  "$GODOT_BIN" --headless --path "$ROOT" "$@" -- --no-campaign-save > "$ROOT/test-results/$name.log" 2>&1 || result=$?
  cat "$ROOT/test-results/$name.log"
  if [ "$result" -ne 0 ]; then return "$result"; fi
  # Godot can emit a script error without a nonzero process exit.
  if grep -Eq 'SCRIPT ERROR:|(^|[[:space:]])ERROR:' "$ROOT/test-results/$name.log"; then
    echo "$name failed: Godot reported an error." >&2
    return 1
  fi
}
python3 "$ROOT/tools/test_build_desktop.py"
python3 "$ROOT/tools/test_build_ios.py"
python3 "$ROOT/tools/test_build_web.py"
python3 "$ROOT/tools/test_localization.py"
python3 "$ROOT/tools/check_architecture.py"
run_check import --editor --import
run_check behavior --script res://tests/run_tests.gd
run_check integration --script res://tests/test_scene.gd
run_check combo --script res://tests/test_combo_scene.gd
run_check residents --script res://tests/test_resident_scene.gd
run_check bilateral --script res://tests/test_bilateral_scene.gd
run_check mission --script res://tests/test_mission_scene.gd
run_check growth --script res://tests/test_growth_scene.gd
run_check ecology --script res://tests/test_ecology_scene.gd
run_check expansion --script res://tests/test_expansion_scene.gd
run_check fortifications --script res://tests/test_fortification_scene.gd
run_check stamina --script res://tests/test_stamina_scene.gd
run_check languages --script res://tests/test_language_scene.gd
run_check start_menu --script res://tests/test_start_menu_scene.gd
run_check cycle_menu --script res://tests/test_cycle_menu_scene.gd
run_check campaign_save --script res://tests/test_campaign_save_scene.gd
run_check mobile --script res://tests/test_mobile_scene.gd
run_check modules --script res://tests/test_modules_scene.gd
run_check mount --script res://tests/test_mount_scene.gd
run_check feedback --script res://tests/test_feedback_scene.gd
run_check spirit_hit --script res://tests/test_spirit_hit_scene.gd
run_check guide --script res://tests/test_guide_scene.gd
run_check audio --script res://tests/test_audio_scene.gd
run_check traversal --script res://tests/test_traversal.gd
run_check refuge --script res://tests/test_refuge_scene.gd
run_check settlement --script res://tests/test_settlement_scene.gd
run_check frontier --script res://tests/test_frontier_scene.gd
run_check crystal --script res://tests/test_crystal_scene.gd
run_check investment --script res://tests/test_investment_scene.gd
run_check immersive --script res://tests/test_immersive_scene.gd
run_check crystal_survival --script res://tests/test_crystal_survival_scene.gd
run_check scene --quit-after 120
echo 'PASS: architecture, import, behavior, and main scene smoke checks.'
