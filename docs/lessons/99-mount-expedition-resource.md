# 第 99 課：調整探索事件的節奏

用 Godot 開啟 cyber-kingdom-design，在 FileSystem 找到 `data/mount_expedition.tres` 並點選，右側 Inspector 可見：

- Stable Cost：修復馬廄需要的龍晶，目前 6。
- Warning Seconds：預警到可觸發襲擊的最短時間，目前 70 秒；實際仍等夜晚開始。
- Assault Extra / Recovery Discount：該夜增加敵人與下一晚減少敵人，目前 6／4。
- Dragon Growth Days：巨龍最多成長幾天，目前 8。

小練習：把 Warning Seconds 改成 100，建立新旅程體驗，再還原 70。既有存檔保存開始時的規則，所以改 Inspector 後要開新旅程。先只改一個值，才能辨認玩感差異。

資料檔決定數值；domain 決定規則；presentation 決定畫面。調整節奏時不用修改繪圖或存檔程式。此課尚未收到使用者完成練習回饋。
