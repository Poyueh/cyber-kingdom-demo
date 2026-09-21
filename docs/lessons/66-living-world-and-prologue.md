# 66：用同一個遊戲場景做前導

這次沒有新增大型影片檔，而是由 `bootstrap/prologue_stage.gd` 建立一份隔離的 Frontier 場景，安排騎士走向營火、點火、戰鬥和巨龍登場。字幕與跳過按鈕由 `presentation/campaign_prologue.gd` 處理；結束時整份舞台釋放，不會成為玩家的旅程紀錄。

在 Godot 開啟 `scenes/frontier.tscn`，選取主節點：

1. 展開 **Ambience**，調整 **Sunbeam Strength** 控制林間光束。較小值保留像素輪廓，較大值氣氛強，但夜景容易泛白。
2. 選取 Knight 下的 Visual，**Walking Frame Rate** 與 **Running Frame Rate** 控制移動動畫節奏。它們只改動作播放速度；實際走多快仍由遊戲數值決定。
3. 回主節點展開 **Tuning → Crystal Prices → spirit**，調整召回鬼魂所需龍晶，預設 1。空袋無法召回，設定多顆時會使用原本逐顆填格與退款規則。

試著先只改一個數值、啟動新旅程，比較改前與改後。舊紀錄會保留部分建立時的規則，因此調整召魂價格請用新旅程驗證。

這是 Clean Architecture 的實例：召魂付款規則留在 application；樹木、光束與字幕只是 presentation；bootstrap 決定如何組裝。未來更換樹圖或改前導鏡頭，不需要改玩家存檔結構。
