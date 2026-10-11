# 第 107 課：調整遠方魔物的抵達速度

在 Godot FileSystem 點選 `data/invasion_march.tres`，Inspector 的 Remote Multiplier 現在是 3。可改為 2，按 F5 建立一段新旅程，比較第一晚魔物從地獄門走到城牆的時間；測完改回 3。

Caution Radius 與 Blend Distance 決定靠近騎士、居民及防線時多早放慢，以及放慢過程的距離。先只改一個數值；這組設定只影響新旅程，讀取舊紀錄不會套用。尚無使用者實作回饋，不記為已掌握。
