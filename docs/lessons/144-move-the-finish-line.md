# 第144課：把終點往後移，不另寫一套終章

## 用一個設定值重用現有系統

主遊戲本來就有「領龍核 → 建火箭 → 開星圖」：狀態在 `domain/planet_state.gd`，互動在 `application/planet_operations.gd`，畫面在 `presentation/planet_rocket_view.gd`。Demo 以前只是把整套關掉（`voyage_enabled=0`）。

這次沒有複製一份 Demo 專用火箭，而是在 `data/core_loop_tuning.gd` 的 `resolve_demo()` 多寫一行 `rocket_finale=1`：

- `PlanetState` 看到它就啟用，並記住 `finale=true`。
- `PlanetOps.resolve()`：火箭完成時，`finale` 讓 `planet.completed=true`，原本「巨龍勝利先改回進行中」的規則就不再攔，勝利成立。
- 唯一的分歧是終點：`finale` 時完工火箭不提供星圖。

驗證規則 `campaign_checkpoint_rules.gd` 只允許 v3（Demo）帶這個值，主遊戲帶了就拒讀。

## 存檔格式要升版，不偷塞欄位

星球狀態以前只存在主遊戲的七星封套裡，Demo 沒有封套，存讀檔就會丟掉「已領龍核、火箭付了幾晶」。這次把 `planet` 放進一般世界存檔，`campaign_snapshot.gd` 的 `VERSION` 從 22 升到 23：

- 舊版 v22 紀錄在 `_legacy_planet()` 補上星球狀態（巨龍已倒就留一顆龍核可領）。
- `_restore_planet()` 拒絕矛盾資料：沒有火箭的世界帶著火箭進度、巨龍還活著卻已清場。

另外，火箭付款上限原本只對主遊戲放寬到 30，Demo 付到第 13 顆時存檔會被判壞檔。測試 `tests/test_demo_finale_save.gd` 先付 15 顆再存讀，抓到這個問題。

## 回主選單放在組裝層

「9 秒後回主選單」是場景切換，屬於 bootstrap。`bootstrap/planet_travel_controller.gd` 每個物理幀累計勝利後的時間，暫停時不算，時間長度放在 `data/outcome_direction.tres` 的 `finale_return`，Inspector 可調。場景測試 `tests/test_demo_finale_scene.gd` 驗證一半時間時還在遊戲裡、時間到才回到 StartMenu。

## 同一條攻擊規則要分清位置

這次弓兵登塔後站在 y=340，原本地面射擊只接受接近 y=430，因此箭塔看似有人卻不會攻擊。修正時由駐塔狀態明確允許高處射擊，箭的起點也讀弓兵位置；地面居民仍保留原高度限制。

可在 Godot 開啟 `data/hero_v005_appearance.tres`，找到 Mounted Fps；它只改戰馬換格速度，不改騎士移動速度。本次設為12，快跑最高24，讓手機30幀仍看得到每個姿勢。
