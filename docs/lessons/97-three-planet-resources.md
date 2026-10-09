# 第 97 課：用 Resource 調整星球

在 Godot FileSystem 開啟 `data/planets/desert.tres`，Inspector 中可調整白天長度、夜晚長度、第一晚敵數及火箭建造／重建花費。這些是新旅程的設定；已存在的旅程把規則保存在自己的存檔中，不會突然改變。

試把沙地的 `day_seconds` 由 165 改成 180，建立測試旅程比較一天節奏。遊戲規則在 `application/star_voyage.gd`，星圖顯示在 `presentation/star_map.gd`，儲存透過 `campaign_progress.gd`。更換美術或翻譯，不必改旅行規則。

本課已提供；尚無使用者實作回饋，不記為已掌握。
