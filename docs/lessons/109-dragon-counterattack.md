# 第 109 課：在 Inspector 調整反擊回報

在 Godot FileSystem 點選 data/dragon_opening.tres，Inspector 的 Exposed Damage Multiplier 目前是 1.5，Minimum Recovery Seconds 是 6。前者是曝露時傷害倍率，後者是整套攻勢後至少留下的反擊秒數。

可以暫時把倍率改成 1.2，按 F5 建立新旅程，比較打中亮起龍核的回報，再還原 1.5。既有較長收招不會被六秒設定縮短。

設定只在建立旅程時讀入，舊紀錄保留原值。這就是 Resource 與戰鬥規則分離的用途：調數值不用修改傷害程式。尚無使用者練習回饋，不記為已掌握。
