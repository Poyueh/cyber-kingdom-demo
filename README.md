# Cyber Kingdom

賽博龐克中古世界的像素橫向捲軸 RPG：人類靠龍晶驅動機械義肢，在魔法與巨龍統治的荒野建立最後的避難所。

## 最新公開版本

目前所有正式測試包、GitHub Release 與 GitHub Pages 試玩站，都統一發布在：

- [Cyber Kingdom Demo（最新倉庫）](https://github.com/Poyueh/cyber-kingdom-demo)
- [v0.0.17 Release](https://github.com/Poyueh/cyber-kingdom-demo/releases/tag/v0.0.17)
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

v0.0.17 全套重繪騎士動作：跑步與衝刺各 12 張、三段原地與踏斬各 24 張，並更新待機、喘息、受擊、倒地與拔劍。新舊紀錄都會換上新外觀，延續完工城牆阻擋修正。近期版本加入稀缺寶箱、龍晶商人、探索地標、探索圖及兩座部件遺跡挑戰。新旅程需依符序啟動符石或完成 12 秒中繼，解開封印後取得部件；錯序／超時可免費重試。舊紀錄保留原本直接拾取與經濟規則。請選「新遊戲」體驗新內容。

說明同步繁中、簡中、英文。每次新功能完成後，依專案規範更新說明、測試並發佈試玩版。七星球、集結隊伍、火箭與完整十四謎題仍未接入。

目前新旅程包含農具工坊、居民近域採集、施工中的防線停用、日夜循環、龍晶背包和戰鬥原型。詳情請看 [開發進度](docs/STATUS.md)、[架構說明](docs/ARCHITECTURE.md) 與 [Gitflow 流程](docs/GITFLOW.md)。

## 平台狀態

v0.0.17 提供含 v002 音效的 H5、macOS、Windows、Android debug APK 與待簽署的 iOS Xcode 專案。macOS／Windows 尚未正式簽署，Android 未以 Google Play 正式金鑰簽署；iOS 專案仍需在 Xcode 連接裝置後簽署。

## 授權與開發紀錄

這是個人獨立遊戲開發專案。美術、玩法與版本驗證紀錄保存在 `docs/`；發行校驗資料見 `docs/reports/`。
