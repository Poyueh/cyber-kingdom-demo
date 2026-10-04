# 第 95 課：刀光與命中停頓分開調整

打開 `scenes/frontier.tscn`，選最上層 Frontier，在 Inspector 展開 **Sword Style**。Light Stop 是前兩刀命中的停頓秒數，Heavy Stop 是最後一刀。Light Kick / Heavy Kick 控制鏡頭推力；不想晃可設 0。

刀光由 `presentation/knight_sword_trail.gd` 隨劍路繪製，讀取實際揮擊階段；`knight_combat_feedback.gd` 只觀察成功命中的事件。揮空有刀光、沒有接觸停頓。這樣調畫面手感不必改傷害、經濟或存檔。

八張姿勢在 `data/blacksteel_v003_combo.tres` 的權重控制每格停留比例。蓄力格停久一點，出刀格快一點，就能形成節奏；不是單純把整段動畫加速。重建素材工具同步保留相同權重。

小練習：把 Heavy Kick 暫改成 0，打一輪三連斬，感受「停頓」與「震動」的差別，再恢復 3.5。請不要改攻擊有效階段來遷就圖片。尚未收到本課操作回饋。
