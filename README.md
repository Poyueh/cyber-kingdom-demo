# Cyber Kingdom

賽博龐克中古世界的像素橫向捲軸 RPG：人類靠龍晶驅動機械義肢，在魔法與巨龍統治的荒野建立最後的避難所。

## 最新公開版本

目前所有正式測試包、GitHub Release 與 GitHub Pages 試玩站，都統一發布在：

- [Cyber Kingdom Demo（最新倉庫）](https://github.com/Poyueh/cyber-kingdom-demo)
- [v0.0.33 Release](https://github.com/Poyueh/cyber-kingdom-demo/releases/tag/v0.0.33)
- [H5 線上試玩](https://poyueh.github.io/cyber-kingdom-demo/)
- [玩家圖文指南](https://poyueh.github.io/cyber-kingdom-demo/guide.html)

此 demo 倉庫是目前的玩家下載入口；原 cyber-kingdom 倉庫保留早期開發歷史。

## 本機開發

1. 安裝 Godot 4.7.2 Standard。
2. 匯入專案根目錄的 `project.godot`。
3. 按 **F6** 執行目前場景，或按 **F5** 從起始頁開始。

專案使用 Godot／GDScript、Clean Architecture、TDD 與 Gitflow。核心規則位於 `domain/`，流程編排位於 `application/`，Godot 畫面位於 `presentation/`，場景組裝位於 `bootstrap/`。

執行完整驗證：

```bash
bash tools/check.sh
```

v0.0.33 領核時揭示新航線，星圖回顧各星球的探索、遺跡與聚落功績；完成項目亮起金色印記，離開星球後仍可回顧。功績均為選做，七核通關不變；三語指南同步，既有紀錄可續玩。詳見 [本版更新](docs/releases/0.0.33.md)。

v0.0.29 新旅程可選遠征／拓荒／圍城，白天準備時間與夜襲壓力各異，七星球與完整收藏共用。節奏隨紀錄保存；修正手動檢查點另存漏帶星球進度。三語指南同步。詳見 [本版更新](docs/releases/0.0.29.md)。

v0.0.28 二、三級營火升級後有聚落成長演出與新設施光脈；探索地圖的營火頁可回顧三個建設階段。夜襲警訊優先，讀檔不重播；三語指南同步，舊旅程也可使用。詳見 [本版更新](docs/releases/0.0.28.md)。

v0.0.27 新旅程第四晚起加入偏側壓境、延遲夾擊與雙側常規攻勢；日落前 75 秒警訊、兩批出兵相隔 18 秒。每日敵人總數維持，封門取消該側增援。舊紀錄保留原攻勢，三語指南同步。詳見 [本版更新](docs/releases/0.0.27.md)。

v0.0.26 修正前導與主選單配樂重疊，前導沿用玩家音量與靜音設定，三語指南同步校正六地機關說明。既有紀錄可續玩，詳見 [本版更新](docs/releases/0.0.26.md)。

v0.0.25 改善情境引導：鬼魂會先帶你收取居民保管的採集收入，龍晶不足完成下一筆建設時先找補給；採集中、商人回程與火箭施工各有對應提示。既有紀錄可直接使用，三語指南同步。詳見 [本版更新](docs/releases/0.0.25.md)。

v0.0.24 新旅程的六顆後續星球新增連動燈、冷熱平衡與脈衝亮窗三類機關，各地有不同連線、初態與時窗。靠近 E／手機下滑免費操作，部分進度可保存；解封後取得原有八件部件收藏。森林入門與舊紀錄的機關不變，開新旅程可體驗新解法。詳見 [更新條目](docs/releases/0.0.24.md)。

目前提供七張可玩地圖與七隻巨龍：微光林地、銹沙盆地、鏡霜海岸、孢潮沼澤、熔脊裂谷、雷纜廢都、黯潮墓環。星宇航線分支解鎖，暫停選單可查看目前位置、龍核與解鎖條件；在火箭旁互動後選星球並確認啟航。每地封雙門、打龍、領核，集齊七核通關。

首次火箭 20 龍晶、落地殘骸重建 12 晶，均需工匠施工；城鎮、居民、採集與日數分開保存，騎士攜帶龍晶、劍與部件。舊三地存檔（包含三核已勝利）可以接著探索新四地。

說明同步繁中、簡中、英文。每次新功能完成後，依專案規範更新說明、測試並發佈試玩版。十四種部件謎題、完整集結隊伍與更深入的龍戰機關仍待後續開發；本版實作範圍見 [七地遠征](docs/design/seven-playable-worlds.md)。

目前新旅程包含農具工坊、居民近域採集、施工中的防線停用、日夜循環、龍晶背包和戰鬥原型。詳情請看 [開發進度](docs/STATUS.md)、[架構說明](docs/ARCHITECTURE.md) 與 [Gitflow 流程](docs/GITFLOW.md)。

## 平台狀態

v0.0.33 提供含 v002 音效的 H5、macOS、Windows、Android debug APK 與待簽署的 iOS Xcode 專案。macOS／Windows 尚未正式簽署，Android 未以 Google Play 正式金鑰簽署；iOS 專案仍需在 Xcode 連接裝置後簽署。

## 授權與開發紀錄

這是個人獨立遊戲開發專案。美術、玩法與版本驗證紀錄保存在 `docs/`；發行校驗資料見 `docs/reports/`。
