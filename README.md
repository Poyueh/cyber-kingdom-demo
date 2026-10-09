# Cyber Kingdom

賽博龐克中古世界的像素橫向捲軸 RPG：人類靠龍晶驅動機械義肢，在魔法與巨龍統治的荒野建立最後的避難所。

## 最新公開版本

目前所有正式測試包、GitHub Release 與 GitHub Pages 試玩站，都統一發布在：

- [Cyber Kingdom Demo（最新倉庫）](https://github.com/Poyueh/cyber-kingdom-demo)
- [v0.0.20 Release](https://github.com/Poyueh/cyber-kingdom-demo/releases/tag/v0.0.20)
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

v0.0.20 加入三張可玩地圖：原有微光林地、銹沙盆地、鏡霜海岸。每張封印雙門、擊敗各自巨龍並領取龍核；首次 20 龍晶與工匠建造火箭，從星圖探索或回訪，落地殘骸花 12 晶重建。城鎮、居民、採集與日數分開保存；騎士攜帶現有龍晶、劍與部件，集齊三顆龍核通關。舊感受式紀錄可續玩。保留 12 格跑步／衝刺、48 格全身連斬、商人、稀缺寶箱與兩座部件遺跡。

說明同步繁中、簡中、英文。每次新功能完成後，依專案規範更新說明、測試並發佈試玩版。七星球、集結隊伍與完整十四謎題仍未完整接入；目前為三地遠征。

目前新旅程包含農具工坊、居民近域採集、施工中的防線停用、日夜循環、龍晶背包和戰鬥原型。詳情請看 [開發進度](docs/STATUS.md)、[架構說明](docs/ARCHITECTURE.md) 與 [Gitflow 流程](docs/GITFLOW.md)。

## 平台狀態

v0.0.20 提供含 v002 音效的 H5、macOS、Windows、Android debug APK 與待簽署的 iOS Xcode 專案。macOS／Windows 尚未正式簽署，Android 未以 Google Play 正式金鑰簽署；iOS 專案仍需在 Xcode 連接裝置後簽署。

## 授權與開發紀錄

這是個人獨立遊戲開發專案。美術、玩法與版本驗證紀錄保存在 `docs/`；發行校驗資料見 `docs/reports/`。
