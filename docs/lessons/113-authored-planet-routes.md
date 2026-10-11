# 第 113 課：隨機地圖也可以先有關卡節奏

這次在 Godot 的 FileSystem 打開 `data/planet_levels.tres`，可以看到七顆星球的路線 Resource。以 `data/levels/forest.tres` 為例，`left_roles` 和 `right_roles` 是從營地往外走的七段用途；`left_widths` 和 `right_widths` 是對應長度，`terrain` 決定林地、晶谷或遺跡的環境。

用途編號：0 補給區、1 靜謐荒野、2 主要聖所、3 遺藏、4 龍門前庭、5 戰馬遺跡。森林向西先遇到戰馬，向東遇到主要符序；不是每走進一個區段就自動放一個謎題。寬度有小幅隨機變化，但核心順序由作者決定。

練習：先備份 forest.tres，在 Inspector 將 `right_widths` 的第二個數值（索引 1）由 650 改成 700，另開一段新旅程，觀察第一處補給區後的空曠路段變長，完成後還原。Resource 是可編輯的資料，不是每一幀都執行的動作。

`application/journey_setup.gd` 只在建立旅程時把這些資料解析成實際地圖設定。存檔保存的是解析結果，所以改 Resource 不會搬動舊紀錄的寶箱或讓已完成的遺跡重新上鎖。這也解釋了為什麼體驗新關卡需要另開旅程。

尚無你的練習回報，因此不把 Resource、Inspector 或關卡配置記為已掌握。
