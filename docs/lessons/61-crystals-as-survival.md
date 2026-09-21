# 第 61 課：把平衡數值和畫面分開

這次可以在 Godot Inspector 選擇 `data/campaign.tres`，找到 **Hit Crystal Loss**。它代表一次有效受擊最多掉幾顆龍晶，目前是 3；可試著改成 4，再開新旅程比較生存壓力。Backpack Capacity 最多 30，Initial Crystals 是開局持有量。

規則由 `domain/crystal_survival.gd` 決定；晶袋飛入、飛出和淡出由 `presentation/crystal_purse_view.gd` 畫出。調整袋子外觀不應改變角色實際持有的錢。這是本次 Clean Architecture 的具體用途。

記得舊旅程會保存自己的規則；測試新平衡請建立新遊戲，不必刪除原來的紀錄。此課尚未收到實際操作回饋，沒有標記為已掌握。
