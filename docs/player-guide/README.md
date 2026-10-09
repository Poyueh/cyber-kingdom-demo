# 玩家圖文指南

給玩家看的世界觀、操作與通關說明，適用 v0.0.20 三星球遠征：龍核、火箭建造／重建、星圖回訪與三龍核通關。這是閱讀頁；完整遊戲請開啟試玩站。

## 交付

執行 `python3 tools/build_player_guide.py`，產出 `builds/player-guide/Cyber-Kingdom-玩家指南.html`。雙擊用瀏覽器開啟；分享時只需這一份 HTML。圖片、動畫、樣式和互動程式均內嵌，不需要網路或伺服器。手機／平板建議在瀏覽器閱讀，檔案預覽器可能不執行互動。

## 維護

- `index.html`：玩家文案、章節與示意初始內容。
- `style.css`：顏色、字級與響應式版面。
- `guide.js`：平台切換、龍晶填格示意、動畫播放。
- `translations.json`：繁中原文對應的簡中／英文；HTML 和互動文案修改需同步。
- `guide-i18n.js`：建置時嵌入翻譯，依遊戲傳入的 lang 或瀏覽器語言顯示。
- `assets/sources.json`：每張圖片的原始來源。原始素材不修改；指南另存縮圖或裁切副本。

本機編輯時可以直接開啟來源 index.html，但傳給玩家前需重新建置單檔。不要直接編輯 builds 下的產物。遊戲規則改版時，同步更新操作鍵、填格示例成本、體力成本、背包容量與裂隙條件；本頁不是從遊戲數值自動產生。概念封面已標示，實際畫面與刻意佈置的裝備對照保留原始來源。

互動示意只存在頁面記憶體，不會存取遊戲存檔。動畫預設停止。支援鍵盤焦點、折疊問答與減少動態偏好。驗證紀錄見 ../reports/player-guide-v001/。

`.gdignore` 讓 Godot 不匯入網頁專用圖片與動畫；請保留此檔。HTML 建置仍會讀取這些素材。

## 本次核對來源

- `data/campaign.tres`、`data/campaign_tuning.gd`：六晶開局、採集收益、農作與建造價格。
- `data/crystal_merchant.tres`、`domain/crystal_merchant.gd`：一次性贈禮、付費出遊與隔日近身交貨。
- `application/campaign_session.gd`、`application/knight_modules.gd`、`application/campaign_travel.gd`：部件、施工停用、封門／巨龍與力竭恢復。
- `data/night_pressure.tres`：逐夜增援。

填晶示例：六晶起始，工程器具 2／弓 3／裂隙 4。示例退款直接回示意袋，明示遊戲真正退款會落地。舊營火截圖與連斬動畫標明歷史示意，不能當現版視覺驗收。單檔指南已更新，已發佈的壓縮包不修改；下一次 Web 建置會帶入新指南。
