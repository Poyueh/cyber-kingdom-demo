# 第130課：動作過渡不等於延遲操作

在Godot開啟scenes/frontier.tscn，按D起跑、鬆開停步，再按A轉身。data/hero_v005_appearance.tres的Start Seconds、Stop Seconds、Turn Seconds只調完整人物過渡長度；移動仍即時回應，J攻擊會立即打斷過渡。練習把Stop Seconds從0.20改成0.25比較承重感，再還原。

商人的教訓則是：同一個tick沒有新時間，不應清掉「正在移動」這種可見狀態。此為練習說明，尚無使用者完成回報。
