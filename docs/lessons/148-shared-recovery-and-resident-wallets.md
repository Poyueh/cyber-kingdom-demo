# 第148課：共用流程與居民自己的晶袋

這次Demo無法在耐力恢復後順暢衝刺，原因是 `campaign_travel.configure()` 只接了主遊戲與舊核心模式，漏掉完整森林Demo的v3。修正時先用相同輸入驗證兩版都會失敗或通過，不能只改耐力條的外觀。

在Godot開啟 `data/core_loop.tres`，Sprint Recovery Ratio對應再次衝刺門檻，目前是三分之一。`presentation/core_loop_hud.gd` 用真實耐力值填入進度條，刻度使用同一個門檻；如此規則與玩家看到的提示才一致。

在 `data/spirit_companion.tres`，Reminder Interval為新手指示的重播間隔，Callout Interval為引導後的目標提醒。此次按任務經過時間計算，玩家走動不會把倒數清零。

狩獵收益放進既有居民 `crystals` 欄位，靠近才走原本的交付流程；不用再新增一份共享收入或另一種存檔。開啟 `data/hunter_roaming.tres` 可調城牆外狩獵範圍，新旅程保存設定，已有旅程缺少此設定時套用300像素基準。
