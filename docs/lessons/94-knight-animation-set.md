# 第 94 課：換動作，不改遊戲規則

這次的入口是 `data/blacksteel_v003_appearance.tres`。在 Godot FileSystem 點選它，Inspector 的 Run Fps（18）與 Sprint Fps（24）決定圖格切換速度；角色實際移動速度仍由玩法設定決定。12 張圖不等於每秒 12 張，18 fps 播完一次約需 0.67 秒。

先把 Run Fps 暫改為 15，用 F5 跑到營火前觀察腳步，再還原 18。其他欄位先不改，避免把動畫節奏與移動速度混為一談。這份練習尚未收到你的實作回饋。

劈砍則由 `data/blacksteel_v003_combo.tres` 的三組權重分配蓄力、揮擊和收刀時間。它追隨戰鬥進度，暫停或受擊時不會自行繼續播放。新圖先完成像素裁格，再交給 Resource；domain 不需要知道圖片在哪裡。
