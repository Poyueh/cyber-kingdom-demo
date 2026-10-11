# 第 114 課：用蓄力與收招調節探索戰鬥

在 Godot 開啟 `data/trails/forest.tres`。Inspector 的 `windup_seconds` 是攻擊預警時間，`recovery_seconds` 是收招空檔；`guard_count` 控制這一處晶巢的獸數。這些數值由 Resource 提供，建立新旅程時解析並保存，舊旅程不會被重新平衡。

這次沒有在每段荒野加怪：一顆星球只有一處晶巢與一處安靜發現。想讓戰鬥更容易讀懂，可以先把森林蓄力由 0.85 秒調到 1.2 秒，另開新旅程觀察，完成練習後還原。先調反應時間，不必增加怪物數量。

`domain/trail_encounters.gd` 保存整數 tick 的 REST、WINDUP、CHARGE、RECOVER、DEFEATED 狀態。每秒 30 tick；presentation 只讀它來畫地面預警，暫停時核心不前進，畫面也一起停住。

建築人物在 `data/settlement_identity.tres` 選擇整套姿勢、腳底基線和工作循環。每個姿勢先製成原生像素，繪製時不用拆頭身拉伸。`presentation/campaign_audio_cues.gd` 的音效追蹤則只用敵人的暫時物件編號，不寫回存檔資料。

尚無你的練習回報，本課不記為已掌握。
