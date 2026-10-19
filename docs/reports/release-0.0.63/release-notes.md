修正手機網頁版玩到一半會自動重整。

原因是記憶體用光：網頁版會把每段音樂整個解壓後交給瀏覽器播放，舊版音樂播放器在切換曲子時會重新載入並複製新的音樂，每次多出約 40 MB 而且無法釋放。在營地和野外之間走動、日夜交替、夜襲時都會切換音樂，玩一陣子手機就撐不住，瀏覽器只好重開頁面。

- 音樂、環境音與循環音效改為整場遊戲只建立一份並重複使用。
- 實測同樣切換 50 次音樂：舊版 JS 記憶體升到約 1.47 GB 仍持續上升，新版穩定在約 350 MB。
- 玩法、規則與存檔格式（快照 v22）不變；企劃規格修訂 50。

附件分別提供 Main／Demo 的 macOS、Windows、Web、Android debug APK、iOS Xcode 專案及玩家指南。macOS 沿用既有簽章方式，Windows 未簽署；iOS 為匯出專案，需在 Xcode 簽署與真機安裝。

[森林 Demo（網頁）](https://poyueh.github.io/cyber-kingdom-demo/?v=0.0.63) · [主遊戲（網頁）](https://poyueh.github.io/cyber-kingdom-demo/main/?v=0.0.63) · [企劃規格](https://poyueh.github.io/cyber-kingdom-demo/spec/?v=0.0.63)
