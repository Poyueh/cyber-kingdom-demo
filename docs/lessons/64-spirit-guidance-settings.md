# 第 64 課：調整鬼魂停留時間

在 Godot 開啟 `scenes/frontier.tscn`，選最上層 Frontier，再展開 Inspector 的 Tuning 資源。找到 **Spirit Guidance**：

- **Spirit Opening Seconds**：開局最多跟隨多久，預設 150 秒；完成點火、工匠與首次採集委託仍會提早告別。
- **Spirit Visit Seconds**：引魂壇每次召回的停留時間，預設 18 秒。

小練習：把 Spirit Visit Seconds 改為 10，儲存資源，建立一個新旅程，點亮營火後等待鬼魂退場，到右側引魂壇按 E／下滑，觀察它約十秒後淡出。試完可改回 18。

這些數值跟著旅程存檔保存，因此改 Inspector 後請用新旅程測試。外觀畫在 presentation，何時出現／離開的規則在 application；改停留時間不必改繪圖程式，也不會動到招募或建築成本。
