# 騎士動作 v002 製作記錄

使用內建 image_gen 產生；原稿在 sources/。依使用者既有授權，以本機 Pillow／NumPy 清透明邊緣、裁格、统一原生像素密度。

重建：tools/prepare_knight_actions_v002.py（需 Pillow、NumPy）。圖片生成來源與正式動作不是逐格手繪；正式遊戲與預覽都讀相同的原生圖集。跑步八格為不同全身姿勢，衝刺使用全身前傾版本而非拆件腿部重組。

三段攻擊各八格；踏斬在同組全身原稿上增加整體前傾，位移仍由實際按方向的戰鬥規則決定。騎乘四格奔跑與四格攻擊；待機四格、喘息四格、受擊二格、倒地二格、拔劍八格。

所有角色素材繪在 128×96 或 160×128 原生畫布；步行騎士約 60 像素高。部件掛點由圖格 metadata 指定，不使用浮動 UI 圖示。

概念來源根部 .gdignore 避免高解析稿匯入遊戲包；未採用稿保留於圖片工具輸出，不加入遊戲倉庫。

## 生成提示詞

### run2_prompt

Edit the pose blueprint (image2) into a professionally animated pixel-art knight spritesheet; image1 ONLY character design reference. Exactly 8 frames 4 columns x2 rows. CRITICAL faithfully follow EACH blueprint's two legs, hip/feet positions, not the poses of image1. Orange leg denotes NEAR silver-edged leg; blue-grey leg denotes FAR dark leg. Frame1 near leg forward; frame3 near leg under hip; frame4 near leg BEHIND, far leg FORWARD; frame5 dark far leg lands FORWARD and near silver leg trails BEHIND; frame7 silver near leg swings forward across dark leg. Do not make silver shin always lead. Distinct opposite half cycles necessary for running. Confident muscular athletic RUN to right 15degree lean no sneaking, large horizontal step, feet low and push off. Black steel closed helmet cyan visor, crimson cape, cyan mechanical near arm, cyan-edged sword low trailing behind. Reference blueprint's exact coherent skeleton proportions, legs should not be copied pasted. Character about60 native pixels tall with crisp pixel clusters. Transparent background genuine alpha, no blueprint remains no text/numbers/lines, all 8 cells isolated equal width/gutters, entire sword and cape fit, same zoom/height all frames. Near leg silver shading vs far dark shading enables visible crossing. Paint the eight distinct poses as instructed; visual matching identity alone is insufficient.

### unarmed_prompt

Edit THIS exact 4x2 animation sprite sheet. Remove ONLY all swords/blades/hilts from hands across the eight frames. This is same knight running unarmed before acquiring sword. Preserve exactly each frame's body pose, dimensions, armour/cape, helmet, leg arrangement, location and 4x2 grid. Hands empty closed fists, natural same rear running arm, do not cut out wrist/gauntlet. Genuine transparent alpha background, no other changes. Do not redraw legs, do not reorder poses, same identity and pixel-art density.

### support_prompt

Production animation sprite sheet, same black steel knight identity as reference (closed cyan angular visor, red cape, silver shoulder trim, mechanical cyan gauntlet). Exactly 4 columns x 4 rows=16 whole body frames. Uniform grid, each frame separated by clean transparent gutters and aligned contact foot baseline. True alpha background, NO text, NO landscape. Top row 4 frames QUIET STANDING IDLE breathing cycle, sword down behind, subtly moving shoulders cape. Row2 4 frames TIRED SLOW WALK cycle distinct alternating left and right leg, upright weight, low feet, sword lowered. Row3 4 frames EXHAUSTED BREATHING cycle bends slightly hands braced on thighs shoulders rise/fall, knees softly bent, planted boots. Row4 first TWO frames actual HIT RECOIL chest pulls backward head rocked; last TWO frames DEATH kneels then collapses lying on ground facing right. Keep same character scale even collapsed, no miniaturization, no duplicate drawings, no fading ghosts. Clean game pixel clusters suitable to reduce to a 60-pixel-tall character per 128x96 cell, not painterly illustration, coherent limbs and strong silhouette. Keep torso crest/shoulder height stable within cycles. Right facing always. Use identity but replace all actions with these specified ones.

### unarmed_support_prompt

Edit this exact 4x4 knight animation sheet. Remove ONLY all sword blades and hilts, make hands naturally empty. Preserve character identity, proportions, poses, frame locations and exact 4x4 layout, native pixel-art style, transparent alpha background. Do not change legs/head/cape/gauntlets. This is UNARMED version idle4, slow walking4, exhausted breathing4, hurt2, dying2. Especially last lying-down death must retain complete body and helmet, no sword. No added backgrounds or text.

### combat2_prompt

Production sprite sheet must have WIDE BLANK GUTTERS between each whole character. Exactly 4 columns x 6 rows =24 images on transparent background (portrait canvas). 3 different eight-frame sword combos, each combo spans TWO rows read left to right. Same BLACK STEEL knight reference cyan angular visor red cape cyan gauntlet sword. Cells uniform, each cell contains entire knight AND entire sword sweep with generous margins. Never touch neighbouring cell. First8 frames diagonal cut sequence: rear guard, shoulder load, torso twist, fast diagonal sweep HIT, extended followthrough, deceleration, return, guard. Next8 reverse upward cut: blade low front, coil torso, pull, rising slash HIT, reach high front, settle, return, guard. Last8 strong horizontal thrust: rear guard, chamber blade near ribs, brace, thrust HIT, full extension, retract, settle, guard. All facing right. Boots planted same locations for all frames except very subtle weight shifts. One narrow cyan streak on hit only, no giant crescents, no afterimages. Never mirror/time reverse first action for second. New anatomically coherent whole-body drawings. Clean deliberate pixel art intended 60px tall figure in160x128 native cell, stable black armour/cyan/red palette, NOT detailed painted illustration. Truly transparent alpha no text or lines. Enough transparent padding above below left right of each image is ESSENTIAL. No cropping, no extended blade crossing neighbouring frame.

### combat_cutout_prompt

Remove entire smoky colored backdrop from this sprite sheet and output genuine transparent alpha. Preserve exact existing 24 knight poses at their exact locations and scale. No re-layout/no redesign. 4 columns6rows remain. Remove all glow haze outside silhouettes, retain crisp sword edges and red capes, preserve dark armour. Nothing except knights and their held swords should remain; no shadows/no smoke/no checkerboard. This must be a clean usable transparent game sprite atlas.

### ceremony_mount_prompt

Generate pixel-art animation sheet for SAME BLACKSTEEL KNIGHT (reference identity): black angular closed helmet cyan visor, cyan prosthetic arm, silver trim black armour crimson cape. Exactly FOUR columns x FOUR rows uniform grid total16 isolated full-body frames. First 2 rows=8-frame camp SWORD EXTRACTION ceremony: 1 empty hands reaching down toward cyan sword embedded in earth; 2 hands grip hilt kneeling;3 weight starts rising;4 sword drawn halfway;5 blade releases knight standing;6 raises sword triumphantly;7 lowers blade;8 settles ready with blade behind. Bottom 2 rows=8 frames of same knight RIDING A DARK BROWN WARHORSE bronze/cyan harness, full horse facing right: frames9-12 four distinct gallop contact passing airborne landing, frames13-16 saddle sword sweep windup, slash forward, followthrough, return, horse planted during slashes. Fit full horse no clipped hooves sword/cape. Keep knight same anatomical scale across top/bottom rows (horse makes total silhouette larger). Each cell about160x128 native pixel canvas. Foot baseline consistent per row, ample transparent gutters. Detailed but clean pixel clusters at native about60px rider height on foot. Genuine transparent alpha, no floor or cast shadows, no text, no grid lines, NO afterimages. Artwork clear and coherent, every frame new posture. Do not show separate detached weapons.
