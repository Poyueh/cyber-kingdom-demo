# 第 91 課：調整關卡挑戰，不改程式

在 Godot 的 FileSystem 找到 `data/ruin_trials.tres` 並點選。Inspector 的 Relay Seconds 是中繼挑戰時間，Station Spacing 是三座符石的距離，Interaction Radius 是靠近到多近能按 E／下滑啟動。

小練習：先記住預設 12 秒，把 Relay Seconds 改成 18，建立新旅程，體驗中繼的移動壓力；完成後還原為 12。既有紀錄保存了當局數值，所以改設定後要建立新旅程才會套用。

符序邏輯在 domain，按鍵和手勢仍使用原本的互動入口；日後改圖素或 UI，不需要重寫謎題規則。尚未收到練習回饋，不記為已掌握。
