# 第 89 課：效能優化先量測

Godot 執行遊戲時可在底部 Debugger 的 Profiler／Monitors 觀察耗時與記憶體。平均 FPS 看不出每隔一段時間的存檔頓點，因此也要看較慢的那一幀。

這次 `application/campaign_snapshot.gd` 只記住「每種腳本有哪些欄位」，每次仍讀取最新遊戲資料。驗證欄位時不再先深拷貝整份資料，但正式存檔與讀回的旅程仍各自擁有獨立副本，避免互相改到。

重現量測：執行 `tools/bench_checkpoint.gd`，比較相同種子、地圖和設定的 capture／restore。這是 CPU 工作量，不能直接換算手機 FPS；實機仍要觀察遊玩、暫停存檔與恢復時是否卡頓。

小練習：在 Godot 執行主場景，打開 Monitors，觀察遊玩與暫停時的 Process Time。尚未收到練習回饋，不代表已掌握 Profiler。
