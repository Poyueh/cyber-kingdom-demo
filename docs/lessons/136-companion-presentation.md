# 第136課：讓陪伴動作跟著玩家，而不是讓玩家等動畫

本次鬼魂的樣貌在 `presentation/spirit_companion_art.gd`，陪走和回頭在 `presentation/spirit_motion.gd`。核心只提供「該去哪裡」，畫面層再決定看向哪裡、怎麼漂過去、何時短暫顯示文字。

打開 `data/spirit_companion.tres`，在 Inspector 調整 `wait_seconds` 就能改變鬼魂等多久才回頭；`caption_seconds` 決定短句停留時間。這些數值只影響呈現，不改變採集收入、教學完成或玩家存檔。

同一個遊戲時間不會重複推進動畫，所以暫停不會讓披風偷跑。附近兩位流浪者換位也不代表教學重來，因此招呼依步驟辨識，不依最近人物編號重播。
