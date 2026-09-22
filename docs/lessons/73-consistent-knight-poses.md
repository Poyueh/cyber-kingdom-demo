# 第 73 課：同一位騎士，切換不同姿勢

Godot 的 `AtlasTexture` 只是從大圖中裁出一格；它不會知道兩張圖的頭盔、身高或腿甲是否相同。這次待機、移動、拔劍及徒步喘息，改用同一組美術部件先產生成圖集，遊戲仍只播放圖片，不增加即時骨架或逐幀圖片處理。

在 `presentation/knight_ceremony_view.gd`，`ENDS` 決定八格拔劍各播放到哪個時間；在 `presentation/knight_visual.gd`，`walking_frame_rate`、`running_frame_rate` 決定跑步和衝刺的播放節奏。調整播放率會改變快慢，但無法修正圖本身抬膝太高。

外觀有兩部分：圖集與材質。騎士升級的材質也必須跟到徒手／拔劍狀態；騎乘則使用既有最高階配色，喘息沿用相同馬匹圖。這次先以測試重現切換漏掉配色、騎馬喘息換圖，再修正。

可練習：Godot 開啟 `scenes/frontier.tscn`，選取 Knight 下的 KnightVisual，找出 Walking Frame Rate。先記下原值 32，短暫改成 28 試看節奏，再改回 32。這只影響動畫播放，不改騎士實際移動速度。

尚未收到練習完成回覆，因此不更新為已掌握。
