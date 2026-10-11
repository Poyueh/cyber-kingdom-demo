# 第 118 課：調整巨龍出場的蓄力

這次演出不是播放影片，而是讓獨立的 Godot 場景操作原本的工匠、騎士和巨龍。數值放在 Resource，場景負責演出；因此不會改到玩家存檔。

在 Godot FileSystem 選 `data/opening_direction.tres`，找到 `Dragon Warning Seconds`，目前為 1.8。暫時改成 2.2，啟動主選單、按「重看開場」，觀察巨龍吐息前多出來的停頓。看完再改回 1.8。只調這個欄位，不必改程式。

`Shot Starts` 則決定各段落開始時間；比喻成導演的分鏡時間表。此次先只練習蓄力欄位，尚不代表你已掌握 Resource 或動畫系統。
