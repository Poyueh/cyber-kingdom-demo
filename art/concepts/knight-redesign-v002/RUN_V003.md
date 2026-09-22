# 全身跑步重設 v003

使用者否定先前 16 格生成動作和拆件重組版，要求重新設計。本輪是新的八格全身關鍵動作提案，使用內建 image_gen 生成；不是宣稱格數減少就比較流暢，也不是正式遊戲動畫驗收。

## 同一份圖，兩種查看方式

- `sources/run-v003-generated.png`：保留採用的完整生成輸出，4 欄 × 2 列，1774×887。
- `sources/run-v003-poses.png`：生成用八個姿勢藍圖。角色造型參考取既有 `sources/design.png` 第一個站姿。
- `prepare_run_v003.py`：只校正四格遠側腿光影與透明邊緣；不平移、旋轉、拉伸個別肢體，不插格，不合成人影，不減色。前後 opaque 輪廓有一致性檢查。
- `sources/run-v003.png`：最後採用的全身圖。頁面動畫與整張展示直接讀這個同一 URL，避免前次原圖與預覽不一致。
- `preview/index.html`：預設新跑姿，八格每秒 12 格，可暫停、半速及逐格；前版 16 格留作比較。整張角色只等比例縮放至約 60 像素高、按列對齊地面。

## 動作方向與限制

從落地、承重、蹬地、換腳組成左右兩步；肩腰、低位持劍手和披風是完整生成的全身姿勢。遠側腿減光使交錯較好辨认。第一張無藍圖的生成稿有背景、同側腿重複，沒有採用；第二輪依藍圖生成，再校正深度光影。

這仍是八個關鍵姿勢，接點節奏與主觀美感要依實際連播回饋調整。沒有為了增加圖格數複製姿勢，也没有把骨架切片當作生成原圖。Godot 主角和所有玩法都未改動，沒有發行新版本。

## 採用提示詞

內建 image_gen，輸入順序：八姿勢藍圖、既有角色站姿。

```text
EDIT IMAGE 1, keeping its EIGHT exact full-body poses and layout. Replace the plain figures with the armored knight costume in image 2. Image 1 is the binding animation blueprint. Image 2 is costume only.
Exactly 4 columns, 2 rows. Keep the blueprint's exact hip/knee/ankle positions in every cell and the opposite leg roles in bottom row. Turquoise leg becomes the NEAR silver-edged black-steel armored leg. Pink leg becomes the FAR darker armored leg. These blueprint colors must disappear in finished art. Critically frame 5 has dark FAR shin straight forward and bright NEAR shin tucked BACK; frame 7 has bright NEAR knee forward and dark FAR leg planted behind.
Render all eight figures as coherent expressive whole-body PIXEL ART, clean clusters with medium detail suitable for a 64px-tall sprite, consistent anatomy and silhouette. Black-steel knight, closed helmet cyan visor, cyan forearm, red cape trailing backwards, sword held low behind, free-arm counter-swing. Add gentle forward lean, but preserve exact leg poses and balanced pelvis in image1. Cape ripples subtly. One continuous run cycle with alternating legs. Do not copy a repeated lunging pose from other art. Do not add scenery, blur, afterimages, labels, ground lines, vignette, colored background or decorative effects. Output genuine transparent alpha. Keep sword, cape and all body parts inside their respective equally sized cells, with transparent margins on all sides.
```

後續明暗修正（仍有不足，以小範圍離線光影校正完成）：

```text
Edit this exact eight-frame sprite sheet. Keep all eight COMPLETE whole-body poses, silhouette, proportions, layout, camera, cape, sword and armor design unchanged.
ONLY fix leg depth lighting in the BOTTOM FOUR frames so they depict the OPPOSITE LEG taking the step:
Bottom frame 1 (overall frame 5): the leg extending FORWARD RIGHT must be the DARK FAR LEG; the bent leg BEHIND LEFT must have BRIGHT SILVER near-leg highlights.
Bottom frame 2 (frame 6): forward support leg is DARK; recovering rear leg has SILVER highlights.
Bottom frame 3 (frame 7): the bent raised leg FORWARD RIGHT has SILVER highlights; the support leg BEHIND LEFT is DARK.
Bottom frame 4 (frame 8): the leg reaching FORWARD RIGHT has SILVER highlights; the leg BEHIND LEFT is DARK.
The top four frames remain unchanged. This correction is essential to show alternating left/right steps: first row bright near leg contacts, second row dark far leg contacts. Do not invent poses, do not redraw anatomy or recompose. Preserve true transparent alpha; no background. No text.
```
