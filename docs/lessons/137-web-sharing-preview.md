# 第137課：遊戲畫面與分享縮圖是兩回事

Godot 的 Web 遊戲在 Canvas 畫圖，社群爬蟲通常不會先啟動遊戲。因此在匯出後，tools/install_social_preview.py 會在 HTML 的 head 指定 og:image，讓連結預覽使用 web/social 裡的真實遊戲截圖。

之後換圖時，選擇能看清角色和場景的實際截圖，使用新的檔名並同步尺寸；不必重新製作遊戲動畫。Facebook 已快取的卡片可用 Sharing Debugger 重新抓取，但是否刷新既有貼文由平台決定。
