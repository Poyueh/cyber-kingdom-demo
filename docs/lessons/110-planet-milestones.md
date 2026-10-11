# 第 110 課：調整領核演出的節奏

在 Godot 的 FileSystem 點 data/planet_feedback.tres。Inspector 的 Duration 是整段演出秒數，Flight Seconds 是核心飛入印記的時間，Fade Seconds 是淡入淡出時長。

可以暫時將 Duration 從 6 改為 5，測試領核後是否有足夠時間讀完新航線，再還原 6。這只影響演出，不改變龍核、通關或玩家存檔。

星圖的功績來自 application/voyage_progress.gd 對既有遊戲狀態的唯讀整理；畫面不需要另外存一份「完成數」。這能避免實際已解開遺跡，介面卻顯示未完成的不同步問題。

尚未收到實作練習回饋，因此不記為已掌握。
