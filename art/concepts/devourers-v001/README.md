# 噬晶異獸與七龍原稿

全部 16 張透明原稿由內建 **imagegen** 製作；同名 `.txt` 是完整提示。`grunt` 是原創共同種族參考，七份 `elite-*` 是各地既有守門者，`carry` 是一晶撤退；七份 `dragon-*` 依原有七龍的身份素材擴充完整姿勢。沒有手持武器。

此目錄 `.gdignore` 排除正式引擎匯入；遊戲只讀 `art/characters/devourers-v001`。重建工具：`tools/prepare_devourer_art.py`，需 Pillow、NumPy。固定比例、最近鄰取樣與腳底對齊；不切肢、不逐幀配框、不產生插值假姿勢。圖集與遊戲畫面使用同一份輸出。

`manifest.json` 記錄尺寸與站姿高度；`docs/reports/devourers-v001/atlas-checks.json` 保留所有來源框、輸出框與共同比例。原生截圖與影片是刻意配置的戰鬥演出驗證，不是自然通關紀錄。畫面表現與恐懼感仍需要玩家試玩回饋。
