# 騎士 v008 原稿

以內建 image_gen 生成／修改完整人物姿勢；來源 PNG 與逐張完整 prompt 保存在 sources/。未採用的實驗稿留在工具原始輸出目錄，不接入遊戲。

動作研究與出處見 docs/design/knight-motion-remaster.md。離線 `tools/prepare_hero_v008.gd` 將完整人物等比例轉為原生像素圖集，`tools/build_hero_resources.py` 更新共同角色 Resource。原稿不覆寫；正式遊戲不直接縮放高解析原稿。

檢查重點是實際播放時的換腳、同一頭身比例、單一完整身體和起收勢，而不是生成格數。
