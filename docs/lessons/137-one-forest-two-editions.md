# 第137課：同一套規則，用設定決定版本能走多遠

這次 Demo 從「兩夜試玩」改成「完整森林」，沒有複製一份 Demo 專用的遊戲程式，而是多了一個設定值：`core_loop_version=3`。主遊戲是 2、舊試玩是 1、新 Demo 是 3。三者共用同一個 `application/core_loop.gd`，差別只寫在建立旅程時的設定字典裡，例如 Demo 的 `voyage_enabled` 是 0，所以沒有火箭、星圖，打倒森林巨龍就是結局。

打開 `data/core_loop.tres`，在 Inspector 看 Core Loop Tuning 的 `warning_seconds`：這次從 45 改成 20，就是首夜預警的長度。改 Resource 只影響之後新建立的旅程；已經存檔的旅程會帶著當時保存的設定繼續，所以舊紀錄不會突然變規則。

要讓預警「下令弓兵就開始，但弓兵沒到不入夜」，程式在每個 tick 檢查：守軍已指派卻還沒走到城牆時，把剩餘時間維持在 3 秒（`ARRIVAL_HOLD_SECONDS`）。這是用資料推進時間的好處：不需要計時器節點，存檔與讀檔後行為也完全一樣。
