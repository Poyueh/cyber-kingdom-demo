# 第 117 課：用同一套場景調整首戰節奏

打開 Godot 的 `data/trails/forest.tres`，Inspector 中的 Guard Count 決定晶巢怪物數量，Windup Seconds 是出招前可觀察的時間，Recovery Seconds 是攻擊後可反擊的空檔。本次設定為 1、1.2、2.4，沒有增加地圖上的事件。

`JourneySetup` 只在新旅程建立時把 Resource 解析成保存設定，所以改檔後要另開旅程，舊紀錄仍保持原本雙獸。這能避免玩家讀檔後關卡突然改變。

營火回程圖示則由 `NightWatch` 讀取現有時間與騎士位置，再由 `NightWatchView` 畫出；不必為每次顯示新增存檔欄位。這是區分「遊戲規則」與「畫面提醒」的一個實例。

可以先在 Inspector 找到三個欄位，對照新旅程的一次蓄力與收招；尚未收到練習回饋，不記為已掌握。
