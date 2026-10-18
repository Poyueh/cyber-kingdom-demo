# 第138課：手感數值放在 Resource，時機用「年齡」判斷

這次三個改動都沒有新增系統，只改了「數值」和「判斷條件」。

## 開局距離是一個 Inspector 數值

騎士出生位置在 `bootstrap/frontier_root.gd` 的 `restart()`：`sim.world.sites.hall-tuning.arrival_walk_distance`。這個值來自 `data/campaign_tuning.gd`：

```gdscript
@export_range(150,1250,10) var arrival_walk_distance: float=260.0
```

`@export_range` 讓 Inspector 出現滑桿，並限制可調範圍。`data/campaign.tres` 沒有覆寫這個欄位，所以會使用程式裡的預設值；改成 260 後，營火就在 960 像素寬畫面的右側，一進場就看得到。測試不寫死 260，而是檢查「營火在畫面內」（`tests/test_mobile_scene.gd`），之後微調距離也不必改測試。

## 鬼魂什麼時候說話：用年齡，不用計時器

`presentation/spirit_motion.gd` 每一幀回傳一個姿勢字典，裡面有幾個「年齡」：
- `age`：這個任務開始多久了（任務一換就歸零）。
- `near_age`：抵達目標多久了。
- `idle`：玩家停住多久了。

`presentation/campaign_guide_view.gd` 的 `_needs_caption()` 只比較這些年齡和 `data/spirit_companion.tres` 的秒數，例如：

```gdscript
if spirit_pose.age>=Style.caption_delay and spirit_pose.age<Style.caption_delay+Style.announce_seconds:return true
```

不用 `Timer` 節點的好處是暫停、讀檔、換任務時不會留下舊的計時器；畫面只是「讀」目前的狀態。想讓鬼魂更早或更久說話，只要在 Inspector 改 `caption_delay`、`announce_seconds`、`reminder_interval`。

## 翻譯帶參數

遠處的句子是 `tr("spirit.lead %s")%goal`。專案規定：有 `%s` 的翻譯，鍵名本身也帶 `%s`，三種語言都要保留同樣的占位符；`tools/test_localization.py` 會檢查。

## 兩個網站放在同一個 Pages

`tools/unpack_release_site.py` 把同一個 Release 的 Demo Web 包解到網站根目錄，Main Web 包解到 `main/`，兩包都先比對 `SHA256SUMS.txt`。Godot Web 的 `user://` 存在瀏覽器 IndexedDB，路徑來自 `config/custom_user_dir_name`；Main 與 Demo 這個名稱不同，所以同網域也不會共用存檔。
