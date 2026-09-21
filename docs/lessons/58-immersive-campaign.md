# 58：調整新旅程，不破壞舊紀錄

在 Godot 開啟 `scenes/frontier.tscn`，選最上層節點，Inspector 展開 Tuning。

本輪新增的 `Knight Health`、`Knight Damage`、`Rest Regen` 控制新旅程的基礎生命、傷害與回復速度。先把 Rest Regen 從 10 改成 8，建立新旅程，向右拖到第二段直到力竭；觀察喘氣時間是否變長。只改一項方便比較。

Tuning 是 Resource，提供可編輯數值；application/campaign_travel.gd 處理「何時必須休息」，presentation/knight_visual.gd 處理「怎麼看出在喘氣」。這樣換動畫不會改到遊戲規則。

舊紀錄保存當局設定，改 Inspector 不會直接重寫舊旅程。請從「新遊戲」測試新平衡。實機手感仍由試玩回饋決定；尚未把你標記為已掌握 Resource 操作。
