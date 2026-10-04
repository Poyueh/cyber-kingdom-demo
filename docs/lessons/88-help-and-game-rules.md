# 第 88 課：讓 Help 跟遊戲規則一致

在 Godot 的 FileSystem 選取 `data/campaign.tres`，於 Inspector 看 `Tree Crystals`、`Chest Crystals` 與 `Farm Cycle`：目前分別為 2、4、24。這些是新旅程使用的 Resource 設定；舊存檔可保留自己的數值。

Help 文案在 `docs/player-guide/index.html`，翻譯在 `translations.json`，示意互動在 `guide.js`。它們不是從 Resource 自動產生，所以未來改平衡時，要一起核對文案與示例，再用 `python3 tools/build_player_guide.py` 重建單檔。不要直接修改 builds 裡的產物。

小練習：只查看 Inspector 的樹木收益，再找到 Help 的「晶化樹木」，確認同為 2 龍晶。這堂只提供操作建議，尚未收到使用者練習回饋。
