# 第137課：同一套規則，用設定決定版本能走多遠

這次 Demo 從「兩夜試玩」改成「完整森林」，沒有複製一份 Demo 專用的遊戲程式，而是多了一個設定值：`core_loop_version=3`。主遊戲是 2、舊試玩是 1、新 Demo 是 3。三者共用同一個 `application/core_loop.gd`，差別只寫在建立旅程時的設定字典裡，例如 Demo 的 `voyage_enabled` 是 0，所以沒有火箭、星圖，打倒森林巨龍就是結局。

打開 `data/core_loop.tres`，在 Inspector 看 Core Loop Tuning 的 `warning_seconds`：這次從 45 改成 20，就是首夜預警的長度。改 Resource 只影響之後新建立的旅程；已經存檔的旅程會帶著當時保存的設定繼續，所以舊紀錄不會突然變規則。

要讓預警「下令弓兵就開始，但弓兵沒到不入夜」，程式在每個 tick 檢查：守軍已指派卻還沒走到城牆時，把剩餘時間維持在 3 秒（`ARRIVAL_HOLD_SECONDS`）。這是用資料推進時間的好處：不需要計時器節點，存檔與讀檔後行為也完全一樣。

## 補充：為什麼要測「真正匯出的封包」

發佈前的 Demo 匯出檢查抓到一個原始碼測試沒抓到的問題。打包工具 `tools/build_distribution.py` 會把其他六顆星球從 `data/planet_levels.tres` 與 `data/trail_encounters.tres` 刪掉，封包裡只剩森林；但 `domain/planet_level_layout.gd` 的 `valid_options()` 寫死「必須正好 7 顆」，所以封包一建局就觸發 `assert`。

兩個 Godot 重點：
- `assert()` 只在 debug 執行，正式匯出的 release 模板會整行略過。因此玩家版不一定當場出錯，卻可能帶著沒被檢查的資料繼續跑；要靠 `tools/test_exported_distribution.gd` 這類用 `--main-pack` 載入實際 PCK 的檢查才看得到。
- 修正時不放寬成「什麼都接受」，而是改成「可只含前幾顆星球、森林必須在第一筆、所選星球必須存在」。`tests/test_forest_demo.gd` 直接比較：只含森林的目錄建出的設定，必須和完整目錄建出的森林完全相同（`==` 在 Godot 4 會逐層比較 Dictionary 內容）。
