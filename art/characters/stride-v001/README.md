# 騎士步態 v001

內建 imagegen 以 combo-v005/run.png 與 unarmed-v002/motion.png 為外形參考，新生成持劍及無劍跑步；原圖保留於 sources/generated.png。並未更換待機、攻擊、疲憊或拔劍素材。

最終 armed.png／unarmed.png 各為 512×192，4×2 格，每格 128×96；最近鄰縮放、alpha 閾值 150，統一亮色頭盔錨點，保留腳步的支撐／離地差異。後製使用玩家既有授權的本機工具，重現腳本 sources/process.py 需要 Pillow 與 NumPy；來源資料不進 Godot 匯入或發布包。

## 生成提示摘要

Same cyber medieval knight: silver closed helmet and armor, gold mechanical legs, red cape, cyan visor. Strict 4 columns by 4 rows, sixteen isolated transparent cells; top two rows an eight-frame armed run, bottom two rows matching unarmed run. All face right. Sword trails behind toward left. Alternate contact, compression, push-off and flight on both legs. Consistent scale and baseline, cape follows motion. Low resolution crisp pixel clusters, no text, grid, environment, shadows or particles. Preserve reference costume and intended 128×96 final cell size.

原圖實際 1448×1086，以等分格擷取，固定縮放 0.28 並對齊頭盔中心至 (70,38)，腳步約落於既有腳底基準附近；四相位的頭部垂直差 0／1／0／-1 像素。
