# 第 82 課：讓動作與裝備共用一套資料

這次將八格跑步和其他動作集中在 `data/blacksteel_v002_appearance.tres`。Godot 的 SpriteFrames 決定播放哪張圖，部件掛點則告訴呈現層「這一格的背甲在哪裡」，所以換動作時不必把装備寫死在螢幕座標。

在 Godot 的 FileSystem 選取 `data/blacksteel_v002_appearance.tres`，Inspector 裡調整 Run Fps（目前 12）可以改變跑步節奏；先試 10 再還原為 12。這只改動畫播放，角色移動速度和戰鬥判定仍由遊戲規則決定。使用 F5 開啟遊戲觀察腿部步伐，別只看靜態圖集。

居民的採集距離則在 `data/campaign.tres` 的 Work Margin。兩種參數分開存放，讓美術調整不會意外改動採集玩法。未收到使用者實作回饋，這一課仍記為已提供、尚未確認掌握。
