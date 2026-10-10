# 第 98 課：用 Resource 調整星球與航線

在 Godot FileSystem 點 `data/planets/swamp.tres`，Inspector 會列出孢潮沼澤的設定。`Route Requires` 勾選 Desert，表示必須拿到沙地龍核才能首次抵達；已到訪的星球仍可返航。雷城同時勾 Swamp 與 Volcanic，兩顆核都要取得。

可把 `Dragon Followup` 從 1.6 改為 2.0，讓孢翼龍後續招式的預警更長，再用新旅程比較。舊存檔保存原設定，因此不會因平衡修改突然改變進行中的戰鬥。測完可在 Git 還原這筆調整。

本次新增地貌仍需圖片檔，但夜襲數量、龍招式節拍與航線前置都集中在 Resource，無需修改星圖 UI 或核心流程。這不是學習程度測驗，尚未收到操作回饋。
