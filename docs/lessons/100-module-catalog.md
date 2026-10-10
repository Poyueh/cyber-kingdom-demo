# 第 100 課：在 Inspector 修改探索獎勵

這次把新部件的數值放進 `data/module_catalog.tres`。在 Godot 的 FileSystem 找到它，點選後，在 Inspector 展開 Definitions，再展開其中一個 Resource，就能看到費用、範圍、冷卻、目標數與來源星球。

例如選 `command`：Cost 是體力代價、Cooldown 是秒、Power 是弓兵下一箭額外傷害，Duration 是標記保留秒數。先將 Cooldown 從 14 改成 18，再開**新旅程**觀察使用後等待時間。既有紀錄會保存開局設定，所以改資料後續玩舊檔不會追改數值。

Resource 是可以在編輯器調整的資料，不負責處理輸入或畫特效。資料送進核心後才換成 30 ticks／秒計時；畫面只讀結果。這樣你之後調整一件部件，不必翻整個角色程式。

本課尚未收到你的實際操作回饋，不記為已掌握。可先只找出 `command`，確認能看到上述欄位，再嘗試修改。
