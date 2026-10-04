# 騎士 v003 動作驗證

- 16 張內建 imagegen 原稿，共 160 個完整姿勢；素材、提示詞與重建入口在 art/concepts/knight-actions-v005/README.md。
- 主戰役（含前導劇場）載入 blacksteel_v003_appearance；規則／存檔不變，舊獨立戰鬥測試場保留其歷史外觀。
- macOS Godot 4.7.2 Compatibility 原生 960×540，透過實際 InputMap 與主戰役控制器拍攝。空手／持劍跑步、衝刺均觀察到 12 個不同圖格；原地三連斬 x 位移為 0，踏斬有位移且返回跑步；喘息後接慢走，拔劍使用新圖集。
- native-*.gif 是原生 viewport 的最近鄰 3 倍局部裁圖。其他 GIF 是同一原生圖集的離線動作檢視（斬擊刻意慢播），不是遊玩速度證據。native-evidence.json 保存來源與幀數；atlas-checks.json 驗證透明邊界及所有圖格未裁切。
- tools/check.sh 全套通過，核心 2,485 斷言零失敗；無 SCRIPT ERROR／ERROR。包括原地／踏斬輸入、左右方向、障礙、疲勞、手機連點、部件掛載、受擊掉劍、舊檔騎乘及存讀回歸。
- 原生擷取工具結尾加上釋放等待，重跑後無 Godot ERROR／資源洩漏訊息。首次擷取的結束清理訊息不列作遊戲記憶體量測。
- 三語指南改用 native-planted 實錄，離線指南已重建、翻譯覆蓋通過。未在 Windows／iPhone／Android 真機驗收，本輪不宣稱長局效能改善；動作美感仍需要使用者實玩回饋。

重現：以原生 Godot 執行 tools/review_knight_actions.gd，明確停用玩家存檔；输出 /tmp/knight-v003-render。動畫 Resource 控制外觀、圖格與節奏；domain／application 不讀取圖片。
