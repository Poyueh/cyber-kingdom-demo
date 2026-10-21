# 第154課：「站在哪裡」也是規則

## 用畫面上的真實寬度寫測試

玩家看到的是「流浪者被樹冠遮住」。測試 `tests/test_wanderer_ground.gd` 就照畫面判斷：每棵樹的寬度直接讀實際貼圖（`frontier_details.harvest_texture()`、其他星球用 `planet_scenery.TREE`），一半寬度加風擺 3 像素就是樹冠；流浪者身體半寬 14。只要兩者重疊就算「站在樹下」。這樣之後換樹的美術，測試仍然量的是玩家看到的東西。

## 一個純函式，三個地方共用

`domain/open_ground.gd` 只處理地面上的區間：
- `tree_cover()`：把站著的樹變成排序、合併過的樹冠區間。
- `spot()`：在範圍內找最近的空地，而且空地要多留一個身體寬（`CLEARING`），避免夾在兩棵樹中間。
- `span()`：一個人所在空地的左右邊界，徘徊就限制在這裡。

開局位置（`core_loop_layout.gd`、`campaign_session.gd`）、黎明新來者（`frontier_ecology.gd` 的 `gathering_x()`）和每幀徘徊都呼叫同一組函式。規則只有一份，就不會像第143課那樣兩處說法不同。

## 世界生成也是存檔格式

這個專案的存檔不存整張地圖：讀檔時用種子重新生成世界，再逐棵比對樹木座標（`campaign_checkpoint_rules.gd`）。所以一開始把營地外兩棵樹往西挪 10～20 像素，所有舊的 Demo／主遊戲紀錄都會讀不進來。完整回歸抓到後：

- 已存在的佈局常數（`CoreLoopLayout.WILD_TREES`）一律不動，旁邊註明原因。
- 要改生成就加設定值：新旅程的 economy 帶 `forest_clearing=1`，`domain/frontier.gd` 才用新的樹位置；舊紀錄沒有這個值，照原本公式重建。
- 新增 `tests/fixtures/guided-forest-v24-*.json`（用 v0.0.76 程式存的紀錄），並確認「移動樹」時這個測試會失敗。

另外，`Frontier`、`FrontierEcology` 的每個一般變數都會進存檔、讀檔時欄位數要完全相同。需要在執行時記住「這個世界有沒有空地」又不能改存檔，就放進物件欄位：`wanderer_gathering.gd` 是 RefCounted，存檔會略過物件。

## 測不到的情況要先讓它失敗

「夾在兩棵樹中間」一開始沒有測試，是看截圖才發現的。補上 `wedged()` 測試後，先把 `CLEARING` 暫時設成 0，確認會失敗（東側流浪者卡在 1348 的 4 像素縫裡），再改回 28 確認通過。這是確認測試真的在檢查你以為它在檢查的東西。
