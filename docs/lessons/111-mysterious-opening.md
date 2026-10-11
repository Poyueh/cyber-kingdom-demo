# 第 111 課：用 Resource 調整開場節奏

在 Godot 的 FileSystem 點 `data/opening_direction.tres`。Duration 是演出主段長度，目前 19 秒；Fade In Seconds 與 Fade Out Seconds 控制開頭和結尾，Menu Reveal Seconds 控制主選單浮現。

先將 Menu Reveal Seconds 從 0.65 改成 1.0，執行後略過開場，觀察主選單是否顯得拖慢，再還原。這只改呈現，不會改玩家存檔或難度。

Shot Starts 依序對應森林回聲、星球掠影前段、掠影後段、古龍亮相。需保持遞增，最後一段早於 Duration；Caption Keys 對應四段字幕。星球掠影在第二段到第四段之間均分六個世界，所以調整段落時間也會改變掠影速度。

「重看開場」只建立隔離演出；「開始旅程」確認節奏後才由原本的存檔流程建立遊戲。讓美術與遊戲狀態分開，才能放心反覆調整演出。

尚未收到使用者實作練習回饋，不記為已掌握。
