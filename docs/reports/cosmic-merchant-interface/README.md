# v0.0.45 原生呈現驗收

原生 Godot 4.7.2／Apple M3 Pro，Compatibility 渲染。腳本使用獨立場景、關閉正式存檔，不改玩家旅程。

- `cyber45-proof.gd`：實際主選單、三級商人 24 姿勢中的待機與六格走路、三語宇宙星圖、960×450 矮視窗；11 項通過。PNG 均由原生 viewport 擷取。
- `cyber45-voyage.gd`：沿用七星球真實場景回歸，以強制繪製擷取避免背景視窗不送 frame_post_draw。37 項通過，確認查看不立即啟航、解鎖與返航、七核勝利、完整存檔還原。
- `cyber45-muted.gd`：歷史 muted=true、滑桿顯示零、拉高恢復與設定持久化，4 項通過。
- `cyber45-audio-before.log` 保留移除快捷鈕前的兩個预期失敗：三鈕仍顯示、滑桿全零未關閉音效架。原生初次發現的 shader int/float 混用已明確轉型，最後原生紀錄無 shader/script error。
- 舊 mission/frontier/audio 整合預期按使用者指示更新：移除三個外側快捷鈕。勝敗後仍驗證可開暫停、返回起始頁；保留原來鍵盤重開與新圖操作檢查。

`art/concepts/merchant-v001/prompt.txt` 保存內建 imagegen 完整提示，`atlas.json` 保存固定縮小與各格裁切錨點；正式圖集 `art/characters/merchant-v001/merchant.png` 由重建工具生成。

完整回歸、打包後確認與上線核對結果收錄同版本發行驗證紀錄。匯出成功不代表 Windows／手機實機驗收。
