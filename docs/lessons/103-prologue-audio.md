# 第 103 課：配樂跟隨畫面階段

在 Godot 開啟 `scenes/start_menu.tscn`，按 F6。先聽前導，再按 Esc 跳過；主題曲會接到主選單。遊戲暫停選單保存的音量和靜音，會沿用到下次前導。

在 `bootstrap/prologue_stage.gd` 可找到 MUSIC_MIX 與 EFFECTS_MIX，分別決定前導相對於玩家音量的混音比例。玩家偏好由主選單讀取一次，再傳給舞台；不要在舞台另存第二份偏好。

本課尚未收到操作回饋，不記為已掌握。
