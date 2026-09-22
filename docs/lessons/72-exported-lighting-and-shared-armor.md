# 72：匯出後的光照與共用腿甲

這次黑畫面不是夜晚太暗，而是日夜與場景氛圍的 Resource 在發布包中變成空值。原先用腳本 `.new()` 建立 Inspector 屬性的預設物件，在本機專案可以用，但實際匯出包沒有保留。現在改成明確的 `.tres` 檔案，讓匯出器能追蹤依賴。

在 Godot 的 FileSystem 點開 `data/daylight_style.tres`，Inspector 可以調整 Daylight、Dawn Light、Night Light；`data/world_ambience.tres` 則控制水面、斜光與騎士燈光。顏色預設值仍集中在對應腳本，沒有複製第二套數值。改完務必檢查真正匯出的遊戲，不能只看 F6。

腿甲不一致是待機與移動沿用不同來源。現在持劍／空手的待機、跑步、衝刺及慢走，都以同一套銀色大腿甲、脛甲、靴子離線產出；檔案位於 `art/characters/grounded-run-v001/`。動畫的姿勢可以不同，但裝甲造型與比例應維持一致。

H5 打包流程增加 `tools/test_exported_ambience.gd`，直接載入 `.pck` 檢查場景設定與日夜光照；舊版 v0.0.8 的包可重現失敗，修正包通過。這項檢查仍須搭配瀏覽器目視驗收。
