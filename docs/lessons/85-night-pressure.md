# 第 85 課：用 Inspector 調整逐夜增援

本輪把「每晚總數」與「同時在場數」分開，讓後期有持續增援，又不一次塞滿大量怪物。

在 Godot 的 FileSystem 選 `data/night_pressure.tres`，Inspector 可以修改：

- First Night：第一晚總數，目前 3。
- Additional Per Day：之後每晚增加數，目前 2。
- Nightly Limit：單晚總數的安全上限，目前 60。
- Concurrent Limit：同時在場上限，目前 12；滿員時等待，不取消剩餘增援。

修改後新建旅程才會採用新數值，既有紀錄會使用建立旅程時保存的設定。第一晚預期 3 隻、第二晚 5 隻、第三晚 7 隻；封印一側的门則取消那一側的增援。

採集和農作收益在 `data/campaign.tres` 的 Crystal Harvest 與 Production。練習只把 Additional Per Day 改為 1，預想第二、三晚的數量，再還原成 2；目前尚未收到實作回饋，不將此課記為已掌握。
