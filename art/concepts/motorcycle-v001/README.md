# 龍晶重機 · v0.0.75

使用內建 imagegen（非 API／CLI）製作。正式資源在 art/characters/motorcycle-v001、art/structures/motorcycle-v001；本目錄只存來源，不進入遊戲包。

- vehicle.png：固定的無人重機，黑鋼／黃銅／青色龍晶引擎，嚴格側視。
- riders.png：八種完整騎士姿勢，參考 hero-v011/idle.png；第一次稿件校正為硬邊透明及完整武器輪廓。
- workshop.png：核心座與車庫，同像素世界風格。

tools/prepare_motorcycle.gd 只做離線裁格、固定比例與合成。來源透明度門檻160，完整連通輪廓分離避免切掉劍尖；騎士共用0.19比例，以臀部對齊，沒有分拆／拉伸四肢。車身136像素寬，160×128圖格內底部y=96。前八格是同一騎姿，行駛由獨立輪轂呈現，不以重複變形產生馬步。8–11為蓄勢、舉劍、接觸、收招，12–13待機，14受擊，15休息；徒手使用完整的雙手握把姿勢。

輪轂由motorcycle_drive.gd以原生像素繪製；車身、輪胎保持固定。無人車使用同一底圖。引擎音是tools/make_motorcycle_audio.py原創數學合成，不使用馬蹄聲或外部錄音。

提示詞組記錄於prompts.md。原生場景預覽：docs/reports/release-0.0.75。
