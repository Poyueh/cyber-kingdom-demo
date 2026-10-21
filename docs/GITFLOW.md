# Gitflow

`main` 保存正式發行版本；日常可遊玩的整合成果放在 `develop`。每個開發單元從 develop 建立 feature 分支，先測試再實作，完成後以 merge commit 保留工作單元。

```text
main ────────────────────── 正式發行
  └─ develop ────────────── 下一版本整合
       └─ feature/<name> ── 開發與驗證 ── merge --no-ff → develop
```

## 每日開發

1. 檢查工作目錄，不覆蓋未提交修改。
2. 從 develop 建立 `feature/<name>`。
3. 為新規則寫測試，確認合理失敗，再完成實作。
4. 同步三語遊戲說明、操作提示、進度與教學，重建指南；執行 `bash tools/check.sh` 並完成對應試玩。
5. 提交功能和文件，以 `--no-ff` 合併回 develop。
6. 預設只實作、不發佈：完成必要驗證與本機文件同步後啟動本地主遊戲供操作試玩。主遊戲與Demo共同程式照常同步。只有明確收到發佈指令才接續release／tag／附件與Pages流程；平台省略時僅H5森林Demo。

例如下一個營地測試可用 `feature/camp-economy-prototype`。`test:`、`feat:`、`fix:`、`docs:` 描述提交目的。

## 發行與修補

- 準備可發行版：由 develop 開 `release/<version>`，只處理發行與驗證問題。
- 驗證完成後回合 main 和 develop，於 main 建正式版本 tag。
- 已發行版的緊急修補：從 main 開 `hotfix/<name>`，修好也回合 main 與 develop。
- 尚未簽署、未通過裝置驗證的訓練場不當作正式上架版本。

本地 Git 提交與 GitHub 備份是不同步驟。提交完成不代表已推送；不使用 force push，不重寫歷史，不提交憑證。使用者最新指示為「只實作，先不要發佈，完成後啟動本地遊戲」；明確發佈時遠端目的地為Poyueh/cyber-kingdom-demo。

## 聊天指令

真正可在終端機執行的命令另見 [終端機操作筆記](TERMINAL_COMMANDS.md)。

2026-10-21使用者最新指定：沒講發佈就「只實作，先不要發佈」，完成本機更新及必要驗證後啟動本地主遊戲供操作試玩。此指示取代先前預設公開H5的政策。主遊戲與Demo共同玩法、企劃與指南照常在本機更新；上傳、Release、tag和Pages僅在收到明確發佈指令後進行。

以下`/ck ...`是在開發聊天使用的命令格式，由代理解讀執行；沒有安裝同名終端機程式。一般自然語言指示也繼續有效。

| 指令 | 執行範圍 |
| --- | --- |
| `/ck run main` | 啟動本地主遊戲。 |
| `/ck run demo` | 啟動本機森林Demo，使用隔離版別、資源與存檔。 |
| `/ck publish h5 demo` | 公開更新H5森林試玩站、對應規格與指南。 |
| `/ck publish h5 main` | 公開更新完整主遊戲Web入口。 |
| `/ck publish windows main` | 建置並發布Windows主遊戲下載包。 |
| `/ck publish macos main` | 建置並發布macOS主遊戲下載包。 |
| `/ck publish android main` | 建置並發布Android debug APK。 |
| `/ck publish ios main` | 匯出並發布待簽署的Xcode專案。 |
| `/ck publish all both` | 明確要求本次雙版本五平台發布。 |

`main`可換成`demo`以指定森林試玩版。自然語言「發佈」未指定平台時按H5 Demo處理；明確指定其他平台但省略版別時按主遊戲處理。打包仍完成該平台的必要驗證、分包與校驗；未實際上傳不能稱為已發布。iOS專案不代表可直接安裝；App Store／Google Play／Steam上架及付費服務另行指定。

H5-only發行最少保留Demo Web封包與SHA256SUMS.txt；不為湊齊附件而匯出其他平台。Pages部署會替換整站，下一次Demo-only發布須保留先前/main/資產並核對實際版本。舊Release與附件維持原樣。

本機主遊戲：Godot開啟此倉庫的project.godot後按F5；本地distribution.json預設full，無須先匯出安裝包。也可在終端機執行：

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/jenpoyueh/GitHub/cyber-kingdom-design
```
