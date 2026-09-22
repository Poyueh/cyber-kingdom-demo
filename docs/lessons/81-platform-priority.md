# 第 81 課：先為正式平台設計

Cyber Kingdom 的正式目標是 macOS／Windows 與 iPhone／iPad。H5 適合讓玩家快速開啟、分享與回報問題，但瀏覽器的 WASM 記憶體和 WebGL 行為不能代表原生 App 或桌面版。

因此效能基準要在原生 Godot 匯出物上建立；共用的 domain、application、資源載入與呈現規則應保持一致。只有瀏覽器載入或 Pages 部署需要的調整，才放在 Web 匯出層，不能為了瀏覽器犧牲正式平台。
