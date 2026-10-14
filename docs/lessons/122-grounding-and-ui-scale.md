# 第 122 課：讓景物扎進地面

Godot FileSystem 選 `data/scene_finish.tres`，Inspector 的 `Scenery Embed` 是景物在透明邊界對齊後，再往下埋的世界像素。暫時從 4 改成 2，執行森林觀察樹根，再改回 4。

這是畫面錨點，不是碰撞地板。動物不使用這個埋地量；字級則用同一份資料的 Caption／Body／Action／Heading 四個欄位分層管理。先練習一個欄位，不必同時修改所有字級。
