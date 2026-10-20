# 2026-09-21 效能與驗證紀錄

## 找到並處理的成長來源

- SettlementSession 的 loot、world.supplies 已拾取紀錄原本持續留在陣列；現在拾取後移除。
- 固定地點採收會增加獨立晶堆，讓每幀掃描及存檔隨時間變重。現在鄰近靜止晶堆合併，保留龍晶總量；飛行中、尚在拾取等待期間的晶體不合併。
- 不每幀合併：初版雖降低晶堆數量，卻增加 CPU。改成新收益、丟晶或湧出時才整理。
- CampaignView 在貼圖／風動前做離屏與透明裁剪。GroundedArt 原本已有透明底部快取，並不是逐幀無限制重新取圖。
- 居民獻晶後，騎士附近的居民不立刻撿回自己的晶體，避免重複獻出／收回。

## 同條件比較

本機 Apple M3 Pro，Godot 4.7.2，既有 tools/bench_sim.gd、種子 742601、舊玩法相同情境，模擬第 600 秒。這是單次診斷比較，不是 iPhone FPS 或統計基準。

| 指標 | 修改前 | 修改後 |
| --- | ---: | ---: |
| advance 平均微秒 | 506 | 389 |
| 存檔微秒 | 10826 | 7692 |
| 地上晶堆項目 | 198 | 81 |

## 新規則 30 分鐘加速測試

tools/soak_immersive.gd 以 30 Hz 模擬 54000 步；為持續施壓，補給騎士並清除夜襲，故不代表自然玩法平衡或通關難度。七個時點都保存並還原驗證。

| 分鐘 | Godot static memory bytes | 物件數 | 地上晶堆 | 存檔 bytes |
| --- | ---: | ---: | ---: | ---: |
| 0 | 41663453 | 1608 | 3 | 15261 |
| 5 | 41788821 | 1610 | 11 | 17939 |
| 10 | 41896505 | 1610 | 27 | 21771 |
| 15 | 41894413 | 1610 | 25 | 21790 |
| 20 | 41906161 | 1610 | 25 | 22085 |
| 25 | 41884777 | 1610 | 22 | 21435 |
| 30 | 41878345 | 1610 | 20 | 21194 |

觀測到暖機後的平台期。這個指標不包含瀏覽器、WASM heap 保留、GPU 貼圖或 Safari 分頁限制，不能據此宣稱 H5 手機閃退已完全解決。

## 尚待真機完成

iPhone 17e／16 Pro Max Safari 各連玩 30–60 分鐘，涵蓋多日夜襲、反覆開關指南、背景／恢復、滿人口採收與存讀；記錄何時出現 lag 或分頁重載。再比對 Xcode 原生 iOS 記憶體、Metal 貼圖與 Steam 桌面版本。此輪未打包或宣稱通過原生上架版。

## 2026-10-21 · v0.0.74 Web 音效反覆配置

使用者回報手機 Chrome 遊玩20分鐘以上重整。先重跑30分鐘加速核心模擬：暖機後約46.5 MB、1733個Godot物件持平；這只排除該測試情境的核心持續成長，未涵蓋手機瀏覽器。

Godot Web 預設 Sample，既有設定只讓音樂用Stream，短音效、環境床與循環仍用Sample。用真實CampaignAudio六路架、同一組八種音效、每畫面一次請求（受原有池與冷卻限制），每15秒切換日夜，觀察120秒：

| 指標 | 原Sample音效 | 全Stream音效 |
| --- | ---: | ---: |
| 請求／接受播放 | 7185／3813 | 7184／3926 |
| 建立AudioBufferSource | 3835 | 0 |
| 建立AudioBuffer | 3855 | 0 |
| 累計PCM配置bytes | 567875888 | 0 |
| 建立GainNode | 22953 | 15（固定） |

累計配置量不是即時RSS；JS heap受GC與瀏覽器共用程序影響，不據此宣稱已重現手機OOM。原測試120–125秒的收尾誤將observe和stop重複交錯，故表格只採0–120秒有效窗口；保存的重現工具已改為只stop一次。完整場景測試另外記錄。

Web的 `audio/general/default_playback_type.web=0` 統一串流，保留共用AudioStream、六路池、音效時機與音量。原生播放、畫面、玩法、存檔v24和既有30Hz手機預算不變。未加入定時重載、強制關音、低畫質或改存檔間隔。

相似上游回報：[Godot #116750](https://github.com/godotengine/godot/issues/116750)；[官方ProjectSettings](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html#class-projectsettings-property-audio-general-default-playback-type-web)說明Web預設Sample，Stream可能增加延遲／爆音風險。這是需在手機驗收的取捨，不能把相似回報當成已證實的同一崩潰。

`tools/build_web_soak.py --ref <commit> --scene audio|campaign --output <new-folder>`可建立不含正式玩家紀錄的本機診斷。完整場景為32分鐘實時、30Hz，保護角色／營火以持續施壓，涵蓋日夜、移動、交戰、每20秒自動存檔及每5分鐘手動存讀；不代表自然玩法平衡。正式包不使用診斷入口，結果放 `docs/reports/release-0.0.74/`。
