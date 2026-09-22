# 瀏覽器試玩版

H5 是快速試玩與收集回饋的預覽交付，不是正式平台的效能基準。正式效能與記憶體驗收以 macOS／Windows 原生包及 iPhone／iPad App 為準；Web 專用調整不得改變原生遊戲的玩法、輸入或資源架構。

沿用 Godot 遊戲本體，以單執行緒 WebAssembly / WebGL 2 匯出；不另寫一份 HTML 遊戲規則。入口仍是營火戰役，桌面鍵盤與手機觸控共用既有玩法。

`python3 tools/build_web.py --ref HEAD --output builds/web-新版本` 會從指定已提交版本的隔離副本建立 `web/` 與 `Cyber-Kingdom-Web.zip`。輸出目錄必須尚未存在。引擎錯誤、缺檔、空檔及錯誤 WASM 標頭都會阻擋交付。來源樹與壓縮檔 SHA-256 記錄於 manifest。

遊戲必須透過 HTTP（本機）或 HTTPS（正式網站）載入，不能以 file:// 開啟。將 web 目錄的全部檔案一起部署，保留相對路徑。一般靜態網站即可承載此單執行緒版本，不需 SharedArrayBuffer。正式服務應以 application/wasm 提供 .wasm 並使用傳輸壓縮；本次沒有上傳外部主機。

瀏覽器自己控制畫布尺寸；不可套用桌面視窗置中與縮放，否則畫面和指標座標會錯位。瀏覽器以觸控能力自動選擇操作介面，Inspector 的明確控制模式設定仍優先。Web 與原生 iOS 是不同交付途徑。

user:// 由 Godot 儲存於 IndexedDB。自動與手動存檔仍獨立，依網址來源、瀏覽器及使用者設定隔離；不是雲端同步，也不會自動搬移桌面存檔。清除網站資料會移除進度。手動讀檔本身不立即覆寫自動槽；恢復遊玩或再次暫停時依既有規則保存。

驗證包含桌面實際按鍵、按鈕與瀏覽器讀回存檔，以及模擬行動瀏覽器。Chrome 測試不能代替實體 iPhone Safari 效能、音質或觸控舒適度驗收。

參考：[Godot 官方 Web 匯出說明](https://docs.godotengine.org/en/latest/tutorials/export/exporting_for_web.html)。
