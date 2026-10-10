# 第 101 課：從 Inspector 調整機關節奏

在 Godot 的 FileSystem 點 `data/ruin_mechanisms.tres`，到 Inspector 展開 Definitions。六項分別對應第二至第七顆星球。

先找 Planet 為 5 的雷城機關。Period Seconds 是一輪多久，Window Seconds 是玩家能啟動的亮窗長度；把 Window Seconds 從 2 改成 2.5，重新開一段旅程，就會有更寬裕的操作機會。舊紀錄保存開局規則，因此不會跟著改。

外觀讀核心當下的亮窗與指針位置，沒有另一份動畫倒數；所以暫停、存檔、讀檔後，畫面與可操作時機才能保持一致。資料驗證也會擋住無法完成的設定，例如亮窗超過整個週期。

本課尚未收到你的練習回饋，不記為已掌握。先找到這兩個欄位即可，不必改程式。
