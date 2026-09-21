# 無劍騎士 v002

使用 Codex 內建 imagegen，以 unarmed-v001/run.png 為編修參考生成 4×3 圖集。原始輸出保留 sources/sheet.png。依既有本機處理授權，nearest 等比例縮小、alpha 二值化、以盔甲頭部中心與腳底校正。每格 128×96，腳底 y=80；前兩排跑步，第三排四格站定呼吸，避免待機仍停在跨步。

提示詞：保留銀盔紅披風金色機械義肢、無武器、透明背景；前八格左右腳接地／下壓／通過／抬升連續跑步，後四格雙腳站定呼吸；統一比例、中心與地面，禁止光暈和格線。完整生成請求記錄於本次對話。

## 生成提示原文

Edit target/reference: this original game's silver helmet red-caped gold-mechanical-limbed UNARMED knight. Produce a polished readable authentic pixel-art animation sprite sheet with exactly TWELVE frames in a uniform 4 columns x 3 rows grid, transparent alpha background, no glow no shadow no text no grid lines. Match the character colors, size/proportions and crisp pixel density of the reference. Every cell same scale, character pelvis centered at same X, grounded foot baseline same Y, no horizontal drift. Row1 cells1-4 run phase0,1,2,3; row2 cells1-4 run phase4,5,6,7: ONE full smooth 8-frame side-facing-right run cycle: left contact/down/passing/up then RIGHT contact/down/passing/up, genuinely alternating legs, gold feet readable and arms swing opposite legs. Upright slight forward torso lean, relaxed unarmed clenched hands, absolutely NO sword or weapons anywhere. Cape trails LEFT with sequential fluid follow-through. Row3 cells1-4 four subtle breathing idle poses, BOTH feet planted neutral, arms lowered relaxed, head upright, NO running stance. Individual knight should fit in middle of each cell with generous transparent margins, avoid clipping cape. Required exact grid4x3 and distinct 8 run poses followedby4idle. A game-production spritesheet, not illustration or repeated copies. Preserve transparent background.
