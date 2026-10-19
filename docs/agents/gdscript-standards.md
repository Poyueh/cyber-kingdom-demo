# Cyber Kingdom GDScript 撰寫規範

適用於 Godot 4.7 / GDScript。與 `AGENTS.md` 併讀，衝突時以 `AGENTS.md` 為準。

## 適用狀態

本規範描述**目標狀態**。以下條目在對應重構階段完成前尚未落地，但新程式碼一律朝它寫，
既有程式碼在碰到時順著搬，不另外發動大掃除：

| 章節 | 現況 | 落地階段 |
|---|---|---|
| §3 時間（tick 推進） | 核心仍以浮點秒推進，由 `_physics_process` 餵 delta | 階段三 |
| §4 亂數（注入分流） | RNG 在 domain 內自行 `new()`，用 seed 偏移分流 | 階段一鋪骨架、階段三接線 |
| §5 內容資料 | 數值集中在 `data/campaign_tuning.gd` 平表，實體仍寫在程式碼 | 階段四 |
| §6 Modifier | 尚未存在 | 階段一 |
| §9 不要為了抽象而抽象 | `campaign_session` 仍是三層繼承鏈 | 階段二 |
| §12 效能 | `_draw()` 無視錐裁剪、`context()` 每幀算兩次、自動存檔每 5 秒重建整個世界 | 效能線 P1–P3 |

其餘章節（分層、型別、存檔、命名、測試、提交）即刻適用。

## 1. 分層

```
domain/          純規則。不依賴任何外層。
application/     編排 domain，透過 ports 表達外部需求。
infrastructure/  存檔、偏好設定等外部操作，實作 ports。
presentation/    Godot 節點。讀核心狀態來呈現。
bootstrap/       組裝：讀資料 → 建核心 → 掛節點。
data/            Resource 定義與內容檔。
```

- 外層可呼叫內層，內層不得知道外層。
- `domain/` 與 `application/` 禁止出現：`Node`、`SceneTree`、`Input`、`FileAccess`、
  `get_tree()`、`OS.`、`Time.`、`randi()`、`randf()`、任何 UI 或渲染呼叫。
- 節點只做兩件事：讀核心狀態來呈現、把玩家輸入轉成指令送進核心。
- Autoload 只放無狀態服務。**遊戲狀態不准放 Autoload。**

## 2. 型別

- 所有變數、參數、回傳值都要標註：`var hp: int`、`func damage_of(id: StringName) -> int`。
- 陣列一律 typed：`Array[Dictionary]`、`Array[Modifier]`。
- **無型別 `Dictionary` 不得當實體容器。** 實體用 `RefCounted` 子類或 `Resource` 子類。
  `Dictionary` 只用於：存檔序列化的中介、明確標示為 UI 用的唯讀結構。
- `class_name` 只給 `Resource` 子類（`@export var x: Array[Modifier]` 需要它）。
  `RefCounted` 模組沿用 `const X = preload("res://...")` 慣例，並以 `var x: X` 取得型別。
- 識別字用 `StringName`（`&"max_hp"`），不用 `String`。

## 3. 時間

- 核心以 tick 推進，**不讀 delta、不讀系統時間**。
- `TickClock.TICKS_PER_SECOND = 30`，與 `Engine.physics_ticks_per_second` 對齊。
- 核心內所有計時器是 `int` tick 計數，不是 `float` 秒。
- `.tres` / config 的時間欄位用**秒**（Inspector 好調），在 `_init` 用 `TickClock.ticks_for()` 轉一次。
  轉換只發生在邊界，核心內不得混用兩種單位。
- 全專案只有 `presentation/sim_runner.gd` 一個 `_physics_process` 會推進模擬。
  其他 `_process` 只能做動畫、插值、音效這類純呈現的事。

## 4. 亂數

- 亂數只能來自注入的 `RngStreams`，依用途分流：`WORLD` / `LOOT` / `EVENT` / `COMBAT`。
- **禁止**在 domain 內 `RandomNumberGenerator.new()`，禁止用 seed 偏移（`seed + 6187`）自製分流。
- 新增一個會消耗亂數的系統時，先想它屬於哪條 stream；不屬於任何一條就新增一條 enum 值，
  不要借用現有的——借用會讓改動 A 系統時把 B 系統的骰子位移掉。
- 存檔存的是每條 stream 的 `state`（目前位置），不是 seed。
- 呈現層的裝飾性隨機（草叢位置之類）走自己的 RNG，不得使用核心 stream，也不得寫回核心。

## 5. 內容資料

- 建築、物品、配方、事件、敵人、狀態效果一律走 `Resource` 子類 + `.tres`。
  數值與觸發條件不寫死在程式碼。
- **預設值只有一個來源**。`.tres` 裡有的，程式碼就不准再寫一次
  `config.get("warden_health", 90)`。找不到資料要明確失敗，不要靜默 fallback。
- 新增一種建築或敵人的正確成本是「新增一個 `.tres`」，不是「改四處程式碼」。
- `name_key` 是翻譯 key，**不得參與玩法判斷**。玩法判斷只看 `id: StringName`。
- 新增玩家可見文字要同步繁中、簡中、英文三份，保留格式占位符。
- `ContentCatalog.validate()` 在 bootstrap 與測試都要跑。

## 6. Modifier

- 任何「某情境下某數值 +X%」的需求，一律走 `StatBlock` + `Modifier`，
  **不要**在原地寫 `if raining: decay *= 1.1`。
- 運算順序固定：`(base + ΣADD) × ΠMULT`，`OVERRIDE` 最後套用。
- 每個 modifier 必須帶 `source`（`"weather:rain"`、`"building:barracks:2"`），
  移除時以 source 為單位，不得逐一比對數值。
- 有時效的用 `expires_tick`，由 `expire_at(tick)` 統一清理，不要各自寫倒數。
- `breakdown()` 是給 UI 解釋「為什麼是這個數字」用的，加新 stat 時順手確認它讀得到。

## 7. 存檔

- 存檔 = 序列化核心狀態，**不序列化任何 Node**。
- 必須涵蓋進行到一半的工作、計時器、RNG 位置。
- `application/campaign_snapshot.gd` 用 `get_property_list()` 反射，且 `_copy_fields` 嚴格比對
  欄位數量。因此：**在 session 上新增、刪除或改名任何非物件型別的 script 變數，
  就是改變存檔格式**，必須同步 bump `VERSION` 並補 `_upgrade_*`。
  新增物件型別欄位則安全（反射會跳過 `TYPE_OBJECT`）。
- `application/campaign_checkpoint_rules.gd` 直接讀 `data.session._spawn_remaining` 與
  `data.session.wave`，這類被還原驗證直接引用的欄位名改動會靜默壞掉。
- 未知版本與損壞資料一律走 `_invalid()`，保留原檔，**不得靜默覆蓋玩家存檔**。
- 每個存檔格式變更都要附一個「舊檔升級後能續玩」的測試。

## 8. 命名與結構

- 檔名 `snake_case.gd`，一檔一類。
- 私有成員前綴 `_`。
- 檔案 200–400 行為宜，**超過 400 行先拆**。
- 函式 50 行以內，巢狀不超過 4 層，用 early return 取代深層 if。
- 沒有魔術數字與魔術字串。常數集中在對應的 `const` 區或 `stat_id.gd` 這類集中檔。
- 狀態、動畫、事件名稱用 `enum` 或 `StringName` 常數，不用字面字串。

## 9. 不要為了抽象而抽象

- GDScript 沒有 interface，**不要**為了模擬它而寫只有一個實作的抽象基底類別。
- **不要**用繼承疊功能。需要共用行為就抽成具體的子系統類別，由呼叫端組合。
- 子系統在建構子明確接收它需要的東西，不做服務定位，不反向查 session。
- 不替尚未存在的需求製造框架。第二個使用者出現時再抽象。

## 10. 測試

- 新遊戲規則與 bug 修正**先寫有行為意義的失敗測試**，確認它是因為正確的原因失敗，再實作。
- 不寫只驗證常數或複製實作的測試充數。
- 核心邏輯（`domain/` + `application/`）必須能 headless 跑。
- **呈現層、輸入、動畫、手感不寫單元測試**，另行實機驗證。
- bug 在哪一層就在哪一層測。直接呼叫下游的私有方法會繞過真正的流程，抓不到上游的時機問題。
- 每次改動確定性相關的東西，補一條「同 seed 同輸入跑兩次結果相同」。
- 每次改動核心狀態，補一條「跑 N tick → 存 → 讀 → 再跑 M tick == 直接跑 N+M tick」。
- 既有測試是回歸網。**斷言期望值變了代表行為變了**，回報，不要改測試遷就實作。

## 11. 驗證與提交

- 交付前執行 `bash tools/check.sh`，**逐行檢查 Godot `SCRIPT ERROR`，不能只信退出碼**。
- 行為變更與純重構分開提交。
- conventional commit：`feat:` / `fix:` / `refactor:` / `test:` / `docs:` / `chore:` / `perf:`。
- Gitflow：`main` 正式版、`develop` 整合，功能開 `feature/<name>`，完成後 `--no-ff` 併回。
  不強推、不重寫既有歷史、不提交憑證與引擎快取。
- 每個工作單元更新 `docs/STATUS.md`，架構決策寫進 `docs/adr/`。

## 12. 效能

- **先量測再優化。** 沒有基線數字就不改效能相關的程式碼。提交時附修改前後的對照。
- **效能修改不得改變視覺與玩法。** 改變了就是設計變更，要先確認，不能夾帶在 `perf:` commit 裡。
- **`_draw()` 必須裁剪。** 世界比畫面寬，就要用可見範圍過濾後才送 draw call。
  把 `tint.a` 設成 0 不算裁剪——draw call 照樣送出去。
  裁剪邊界要留物件寬度的 margin，避免畫面邊緣彈出。
- **同一份資料每幀只算一次。** view 與 HUD 需要同一個結果時，由組裝層算一次傳下去，
  不要各自呼叫一次核心的掃描函式。
- **玩家看的提示不需要每幀重算。** 以固定間隔更新，間隔值用 `@export`，不寫死。
- **任何會成長的集合都要有上限或存活時間**：掉落物、特效、屍體、記錄。
  上限值放資料檔。「只有被消耗才會移除」的集合等於沒有上限。
- **主執行緒的同步 I/O 要有頻率依據。** 自動存檔這類操作的間隔要能說出理由，
  且成本不得隨遊戲狀態無限成長。
- **存檔的自我驗證不得移除**，但驗證用的基線應該可以快取——
  只依賴一局之內不變的設定值的東西，不要每次存檔重算一遍。
- 熱路徑（每 tick、每幀）避免重建陣列與字典。`x = x.filter(...)` 每次都配置一個新陣列。
- 量測用的計時程式碼放呈現層或 bootstrap，**不得進 `domain/` 或 `application/`**，
  且要能用旗標關掉，不留在熱路徑上。
- **Web 音訊不得在執行中複製或重新載入 AudioStream。** Web 匯出預設以樣本模式播放，
  每個新的串流實例都會解壓成整段 WebAudio 緩衝（兩分鐘音樂約 40 MB），引擎無法釋放；
  `duplicate()`、快取逐出後再 `load()` 都會讓記憶體持續上升，直到手機瀏覽器重整頁面。
  需要設定循環等屬性的串流一律從 `presentation/shared_audio_streams.gd` 取得共用實例。
  `preload` 的常數本來就是同一份，可以直接用。

## 13. Review 檢查表

- [ ] `domain` / `application` 沒有 Node、SceneTree、FileAccess、`OS.`、`Time.`、裸亂數
- [ ] 全部標了型別，陣列是 typed array，沒有無型別 `Dictionary` 當實體
- [ ] 核心沒有讀 delta，計時器是 int tick
- [ ] 亂數走注入的 stream，且用途分流正確
- [ ] 新數值進了 `.tres`，沒有第二份預設值
- [ ] 情境加成走 modifier，不是原地乘算
- [ ] 動到 session 欄位的話，`VERSION` 有 bump 且有升級測試
- [ ] 沒有只有一個實作的抽象基底類別
- [ ] 檔案 < 400 行、函式 < 50 行
- [ ] 沒有魔術數字與魔術字串
- [ ] 有失敗過的測試，不是事後補的
- [ ] `tools/check.sh` 輸出無 `SCRIPT ERROR`
- [ ] 新的 `_draw()` 內容有做可見範圍裁剪
- [ ] 沒有同一份資料在同一幀被算兩次
- [ ] 新增的集合有上限或存活時間
- [ ] 執行中沒有 `duplicate()` 或重新 `load()` 音訊串流（Web 會累積無法釋放的緩衝）
