# Cyber Kingdom — 公開試玩與下載

這個倉庫只保存已發布遊戲成品、玩家指南、公開規格及網站部署工具。
遊戲原始碼、美術原稿、開發分支與歷史保存在另一個私有倉庫，不在此處開發。

- [H5 森林 Demo](https://poyueh.github.io/cyber-kingdom-demo/)
- [玩家指南](https://poyueh.github.io/cyber-kingdom-demo/guide.html)
- [公開遊戲規格](https://poyueh.github.io/cyber-kingdom-demo/spec/)
- [已發布成品](https://github.com/Poyueh/cyber-kingdom-demo/releases)

目前 Demo 為 v0.0.79；保留的 `/main/` 為 v0.0.77。本次更新森林引導、探索戰鬥與巨龍／火箭收尾；主遊戲入口維持原包。
GitHub 自動產生的「Source code」壓縮檔只有本倉庫的發布工具，並非遊戲原始碼。

## 維護

新版本先在私有開發倉庫驗證、匯出，再將授權公開的成品上傳為 Release 附件。
這裡的版本標籤只指向本倉庫的發布紀錄，禁止推送私有開發分支或原始碼標籤。
Pages 只下載已發布成品，驗證校驗碼後部署；不讀取私有倉庫、不編譯遊戲。
只更新 Demo 時，Release 必須同時帶入原有 Main Web 附件，保留其原版本號與校驗碼。

```bash
gh workflow run pages.yml --repo Poyueh/cyber-kingdom-demo --ref main -f tag=v0.0.79
```

發布授權與本機開發是不同操作，不因原始碼更新自動發布。
