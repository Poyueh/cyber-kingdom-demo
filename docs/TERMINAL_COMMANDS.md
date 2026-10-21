# Cyber Kingdom 終端機操作筆記

更新日期：2026-10-21。以下命令適用目前這台 Mac 與專案內現有工具，可複製到終端機執行。

## 開發預設

沒有明確要求發佈時，預設「只實作，先不要發佈」；完成遊戲修改及必要驗證後，由開發代理啟動本地主遊戲供操作試玩。共同玩法、本機企劃與指南仍同步更新。明確要求發佈卻沒指定平台時，只處理 H5 森林 Demo。

本頁是指令筆記，不會自動執行指令。聊天中的 `/ck ...` 由代理解讀，不能當成終端機程式使用；聊天指令另見 [Gitflow](GITFLOW.md#聊天指令)。

## 先進入專案

每次開新的終端機視窗，先執行：

```bash
cd /Users/jenpoyueh/GitHub/cyber-kingdom-design
```

以下命令都以此目錄為起點。已安裝的工具位置：Godot 在 `/Applications/Godot.app`，另需 Python 3；公開部署使用 GitHub CLI（`gh`）與此倉庫的操作權限。

## 啟動本地主遊戲

```bash
open -n -a /Applications/Godot.app --args --path "$PWD"
```

會開啟獨立的遊戲視窗，不需要先打包。讀取目前本機程式（包括尚未提交的修改），專案預設為完整主遊戲。`-n` 會開新視窗，已有遊戲時請避免重複執行。

也可用 Godot 開啟專案的 `project.godot`，按 **F5** 從主選單開始；**F6** 只執行目前編輯的場景。

## 本機打包：H5 森林試玩版

```bash
python3 tools/build_web.py --edition demo --output "builds/h5-demo-$(date +%Y%m%d-%H%M%S)"
```

產生森林 Demo，實體排除其餘六星關卡與專用素材；包含該版本規格及玩家指南。輸出目錄內的 `Cyber-Kingdom-Web.zip` 是網頁包，`web/` 是可架站的檔案。只產生本機檔案，不會公開上傳。

若要完整主遊戲 Web 包：

```bash
python3 tools/build_web.py --edition full --output "builds/h5-main-$(date +%Y%m%d-%H%M%S)"
```

## 本機打包：macOS 與 Windows

目前桌面工具一次產生兩種平台：

```bash
python3 tools/build_desktop.py --edition full --output "builds/desktop-main-$(date +%Y%m%d-%H%M%S)"
```

輸出包含 `Cyber-Kingdom-macOS.zip` 與 `Cyber-Kingdom-Windows.zip`。macOS 為 ad-hoc 簽署、未公證，Windows 未正式簽署。`full` 換成 `demo` 可製作森林試玩版。

## 本機打包：Android 測試 APK

```bash
python3 tools/build_android.py --edition full --output "builds/android-main-$(date +%Y%m%d-%H%M%S)"
```

產生 `Cyber-Kingdom-Android-debug.apk`，使用本機測試金鑰 `~/.android/cyber-kingdom-debug.keystore`；需要已設定好的 Android 匯出環境。`full` 換成 `demo` 可製作森林試玩版。這是測試 APK，未包含 Google Play 上架流程。

## 打包時要知道的事

- 打包工具預設讀取 **Git 已提交的 HEAD**，尚未提交的修改不會進入包內；和直接啟動本機遊戲不同。
- 可加 `--ref <已存在的分支、commit 或 tag>`，指定要打包的版本。
- `--edition full` 表示完整主遊戲，`--edition demo` 表示森林試玩版。
- 輸出都在專案 `builds/` 下；時間戳記用來建立新目錄。工具會拒絕沿用已存在的輸出目錄；同一秒重跑時請改目錄名。
- Web 打包會檢查企劃規格是否與提交的程式同步；失敗時先修正規格同步問題，不能把失敗包當成完成品。
- 成功匯出不代表已完成手機或 Windows 真機試玩。

## 公開部署：重新部署已建立的 H5 Release

**這段會公開更新網站。**前提是指定版本的 GitHub Release 已存在，且具有匹配的 Web 封包、`SHA256SUMS.txt` 與有效規格。

以下以已發布的 `v0.0.77` 為例；要部署其他已建立的 Release，將版本號換成其實際 tag：

```bash
gh workflow run pages.yml \
  --repo Poyueh/cyber-kingdom-demo \
  --ref main \
  -f tag=v0.0.77
```

這是重新部署指定 Release 的 Web 成品，不會把目前本機工作目錄或剛打包的 ZIP 自動上傳，也不會建立新版本。該 Release 如果同時帶有 Main Web，現有流程也會部署 `/main/`。新版本仍須依 Gitflow 完成版本與規格更新、必要驗證、tag、Release 附件及校驗檔準備。

若將來只發 H5 Demo，部署前須確認保留既有 `/main/` 的上一版資產；Pages 會替換整個網站，不能因少帶 Main 包而意外移除原入口。舊 Release 與附件維持原樣。

查看工作流程執行狀態：

```bash
gh run list --repo Poyueh/cyber-kingdom-demo --workflow pages.yml --limit 5
```

觸發成功不代表部署完成，仍須確認流程成功與公開遊戲／指南／規格符合本次版本。完整發行規範見 [Gitflow](GITFLOW.md)。
