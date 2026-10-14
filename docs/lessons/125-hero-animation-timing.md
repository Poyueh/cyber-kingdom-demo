# 第125課：動作格數與戰鬥速度分開

在 Godot 的 FileSystem 點選 `data/hero_v005_appearance.tres`，Inspector 裡的 `Run Fps` 是跑步畫面的基準播放速度，目前28。先試26，再在相同路段跑過，比較披風和步伐，最後還原28。這只調畫格速度，不會改角色真實移動速度。

出刀則由 `hero_v005_combo.tres` 的 `Slash Durations` 分配各格權重：蓄力稍久、揮出較快、收招再穩住。12格加總為1；有效攻擊窗仍由戰鬥狀態決定，不能只改圖片就認為劍已打中。這次先練習調整 Run Fps，不需同時動攻擊權重。
