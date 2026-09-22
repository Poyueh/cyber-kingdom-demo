# 第 80 課：用一份 Resource 管理整套角色造型

這次把新騎士接進 `scenes/frontier.tscn`。選取 `Knight/ KnightVisual` 的 Appearance，可以找到 `data/blacksteel_appearance.tres`；它集中設定待機、跑步、徒手、喘息、拔劍、騎乘與攻擊素材。

Run Fps 與 Sprint Fps 控制圖格播放速度，不控制人物在地圖上的移動速度。現在跑步八格每秒 12 格；衝刺共用八格但每秒 18 格。若覺得腳步太急，應先調這份 Resource 的播放率，不要修改角色移動或攻擊規則。

把造型資料集中管理，可以一次替換所有狀態，避免跑步是新騎士、停下來又變回舊角色。使用者尚未回報操作練習，不記為已掌握。
