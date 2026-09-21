# 第 65 課：不用改程式，調整部件與水岸

本次保留你原有未提交的場景和 Resource 調整。

1. 在 Godot FileSystem 選 data/campaign.tres，Inspector 展開 **Special modules**。Arc 是雷弧震盪，Lance 是穿甲雷槍；Damage 傷害、Cost 體力、Range 距離、Cooldown 冷卻秒數。先只改一項，再開新旅程比較；既有存檔保留當局數值。
2. 選 scenes/frontier.tscn 的根節點，展開 **Ambience**。Camera Offset Y 越接近 0，鏡頭越低、水面占比越大；Reflection Strength 是倒影清晰度；Lantern Energy 是夜燈強度。它們只改呈現，不改地面碰撞。
3. 場景中的升級站仍用 E 付晶升階；探索到部件並帶回後，用 F 開選配、K 使用。手機點齒輪選配，雙指向上滑使用。

這是 Clean Architecture 的實際分工：application/knight_modules.gd 決定能不能裝、何時能用；presentation/module_menu.gd 決定怎麼畫；bootstrap 把按鍵轉交規則。更換按鍵不用改傷害公式，修改介面也不會重置冷卻。

農業現在固定於避難所二級開放。這次先確立玩法；若日後想改成三級，需一起調整自動建造、介面和行為測試，而非只把按鈕藏起來。
