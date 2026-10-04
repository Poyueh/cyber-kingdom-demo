# 第 87 課：用 Resource 調整商人

在 Godot 檔案系統選取 `data/crystal_merchant.tres`，Inspector 的 Delivery Crystals 是每次交貨量，Trip Cost 是出遊費；Treasure Limit、Treasure Camp Distance、Treasure Spacing 控制新地圖寶箱數量與間距。這些數值由同一份資源供規則與付款提示使用。

例如日後測試收入太高，可先把 Delivery Crystals 從 6 調成 5，再建立新旅程比較。既有紀錄保留建立時的數值，不會因修改 Resource 而偷偷改變玩法。

未收到實際練習回覆，不記為已掌握。
