# 第 115 課：讓 NPC 停手招呼，再回到工作

在 Godot 的 FileSystem 找到 `data/attendant_behavior.tres`，點開 Inspector。`Approach Radius` 控制人物注意到騎士的距離，`Departure Radius` 控制離開多遠後才重新準備招呼；後者必須比前者大，否則在邊界走動就會反覆招呼。

小練習：先把 `Greeting Seconds` 從 1.2 改成 1.6，執行主場景、走近工坊，看看機械師多停留的0.4 秒是否自然。再還原成 1.2。每個 Profile 的 `Work Frames` 與 `Work Holds` 必須一一對應；例如機械師的短敲擊與長收手，來自同一批完整人物圖格，不是拉伸手臂。

工作時計讀模擬的已經過時間，所以暫停後姿勢也停止。`presentation/building_attendants.gd` 只觀察既有付款與庫存，不製造器具；遊戲進度仍由原本核心保存。這次不用重開旅程便能看到變化。

尚無操作回饋，本課不代表你已掌握 Resource 或動畫狀態。
