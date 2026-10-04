# 全身連斬 v004

六張原稿由內建 imagegen 產生；使用既有黑鋼騎士支援動作與本次第一刀作造型參考。每張完整提示詞保存在 sources/*.png.prompt.txt，對應同名來源 PNG。

三段原地與三段踏斬各 8 個完整姿勢。第一刀轉肩後向前承重；第二刀沉身後回挑；第三刀抬身蓄力、壓腰重劈、收招回穩。角色身份、紅披風、青色義肢與刀刃延續 v003。

使用者已授權本機透明背景清理／切格。tools/prepare_whole_body_combo.py 對來源 alpha ≥160 的主要連通區取 8 個完整角色，每段共用固定比例，參考姿勢人物高 60px。最近鄰縮製 160×128 圖格；腳掌基準 y=113、雙靴底跨度中心 x=80，不把骨盆固定，也不逐格拉伸或拆手腳。attachments.json 為逐格背部掛點。

遊戲：art/characters/blacksteel-combo-v004/，由 data/blacksteel_v004_combo.tres 與 appearance 接入；非戰鬥動作沿用 v003。原稿資料夾 .gdignore 避免進入執行包。重建需 Pillow 與 NumPy，不需再次呼叫圖片服務。
