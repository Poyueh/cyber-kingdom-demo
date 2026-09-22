# 黑鋼騎士：首次遊戲接入

原始設計與產圖記錄保留於 `art/concepts/knight-redesign-v002`。本目錄只有執行期使用的原生像素素材及檢視圖；`sources` 原稿不進遊戲包。以 `tools/prepare_blacksteel_knight.py` 重建。

- `run.png`：逐位元組複製已確認的 `preview/run-native.png`，八格、每格 128 × 96。跑步 12 fps、衝刺 18 fps、疲勞慢走 7 fps，三者目前共用同一套姿勢；不是另畫的三套動畫。
- `idle.png` 與 `attack.png`：同角色提案的原生待機與八格斬擊。
- 徒手版移除持握劍刃，保留全身跑步姿勢。沒有拆腿重組或改變肢體比例。
- `rest.png`、`ceremony.png`：取同角色設計稿的跪姿、舉劍及站姿，依原有喘息、拔劍時機呈現；仍是有限关键姿勢的初版接入，不視為完成逐格精修。
- `planted.png`／`advancing.png`：保留原有三段時序。踏斬在有效段使用同角色前傾刺擊姿勢；原地斬不增加角色位置位移，移動距離仍由戰鬥規則控制。
- `mounted.png`：保留既有坐騎六格，校正騎士頭盔與上身甲色以銜接黑鋼身份；不是全新手繪騎乘動畫。

`data/blacksteel_appearance.tres` 統一綁定整套素材與播放率；`scenes/frontier.tscn` 採用它。舊訓練／獨立原型仍可使用原美術，不修改歷史圖集或存檔。後續精修應替換本套資源，避免只換跑步而讓待機、受擊或喘息跳回舊騎士。
