# 農具工坊、施工停用與工作距離

在 Godot 的 FileSystem 選 `data/campaign.tres`，展開 **Resident Work Territory**，可以調整 **Work Margin**。目前新旅程預設 850；數值越大，工人和獵人可以離城牆越遠。按 F6 開啟 `scenes/frontier.tscn` 試新旅程即可比較，既有存檔會讀自己的設定。

同一份 `domain/resident_work_area.gd` 規則供資源付款、工人領單、獵人搜尋和鬼魂指引使用，避免畫面允許付款、居民卻永遠不去工作的情況。

農具工坊的招牌和工具架在 `presentation/farm_workshop.gd`；這裡只畫出庫存，不製造工具。真正的付費生產由 `application/campaign_session.gd` 執行，居民只拿現有鋤頭。未付滿與滿架都不會憑空產出。

城牆的「有血量」和「能運作」現在分開：`domain/settlement.gd` 的 `wall_operational()` 會同時檢查血量與施工狀態。施工中的牆仍記住舊等級、血量及進度，卻不再替居民擋怪；完成後便恢復。

這次先練習找到 Work Margin，改成 700 或 1000 比較新旅程能委託的距離，再改回 850。不需要修改角色或輸入程式。
