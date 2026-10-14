# 騎士步態 v006 原稿

使用內建 image_gen 製作；保留黑鋼、黃銅及深紅披風身份，以早期完整雙步作姿勢參考，重新生成四套各16格：步行／快跑的持劍與徒手。每份 `sources/*.png` 對應同名完整 `.prompt.txt`；快跑最初生成提示在 `sprint-base.prompt.txt`，之後另修正重複劍刃。未選用的原稿不接入遊戲。

`tools/prepare_hero_gait_v006.gd` 裁出完整人物、清理半透明雜點，以四套共同倍率、固定腰胯錨點和最近鄰製成128×96原生圖格；不是分解肢體或逐格伸縮。輸出於 `art/characters/hero-gait-v006/`，再執行 `tools/build_hero_resources.py` 接回現有騎士資源。動作順暢度另以實際遊戲連續錄影驗收。
