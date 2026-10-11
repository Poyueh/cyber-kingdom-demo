# 持續維護的遊戲企劃規格書

公開入口：https://poyueh.github.io/cyber-kingdom-demo/spec/

`content.json` 是唯一人工維護的完整內容來源。`web/game-spec/` 提供閱讀樣式與搜尋；`tools/build_game_spec.py` 產生 HTML、圖片與完整性 manifest，不手動改生成檔。原始碼連結固定到建置來源提交。這份繁中企劃是開發工作文件；三語玩家指南仍維持原流程。

## 新功能必須一起更新

1. 依實際程式審訂受影響章節，注明新旅程／既有存檔／未實作差異。更新 `game_version` 對齊 `export_presets.cfg`，遞增 `revision`，修改 `updated`、`review_note`，並在最後章節的變更表追加一筆。
2. 核對數值與 Resource、通關條件、操作、風格、平台限制；不能把提案當實作。純重構不影響玩家時，明確在審訂摘要記錄理由。
3. 完成審訂後執行 `python3 tools/build_game_spec.py --record-review`，提交 `content.json` 與 `sync.json`。審訂命令要求新 revision 與不同的 review_note，建置不會偷偷更新指紋。
4. `python3 tools/test_game_spec.py`、`python3 tools/build_game_spec.py --check`、`bash tools/check.sh` 都需通過。可用 `python3 tools/build_game_spec.py --output /tmp/cyber-spec-new` 建立新的預覽目錄，實際瀏覽桌面／手機、搜尋、章節、列印。
5. 按既有 Gitflow 發行。`build_web.py` 使用匯出暫存樹內同一提交的建置器，先驗證規格再匯出遊戲；包內自帶 `spec/`。Pages 驗證包內文件與遊戲版本及檔案雜湊，保持兩者成套。
6. 驗證公開 `/spec/manifest.json` 的版本、修訂與檔案，以及來源連結與瀏覽器內容，記錄到 `docs/STATUS.md`。

## 文件單獨更新

不修改遊戲程式或執行包時，可維持遊戲版本、只增加文件修訂。合併 main 後使用 Pages 工作流程的同版本 tag 與 `refresh_spec=true`；完整檢查通過後才刷新 `/spec/`，其他已發布執行檔保持不動。初次遇到沒有規格的舊包，也只有內容版本一致才補建；不同版本直接拒絕。舊版包本身不會被重上傳或改 tag。

## 同步檢查的範圍與限制

指紋涵蓋 domain、application、bootstrap、presentation、infrastructure、data、scenes、localization、art、docs/design、docs/player-guide/assets 中的遊戲程式／資料／素材，以及 project.godot／export_presets.cfg。新增、刪除與改內容都會讓審訂失效。排除 .uid、.import、測試產物與引擎快取。project.godot 僅正規化匯出會改寫的產品名、圖示與 ETC2 匯入開關；按鍵、入口與其他設定仍列入同步檢查。新類型或新根目錄的遊戲資源應一併加入 `SOURCE_DIRS`／`SOURCE_SUFFIXES`。

`sync.json` 是明確的審訂紀錄，不是自動生成正確企劃的承諾。工具只能發現範圍內的變動與漏記審訂，不能判斷自然語言是否真實。CI 在 push／PR 檢查，Web 打包與 Pages 文件刷新亦檢查；不需要定時機器人或外部服務。

本頁的網頁在沒有 JavaScript 時仍可閱讀全文；搜尋、範圍篩選與列印按鈕用小型本地腳本。沒有帳號、追蹤器、外部字型或 CDN 依賴。列印一律顯示完整文件，即使當下正篩選章節。
