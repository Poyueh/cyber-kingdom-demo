# 第 90 課：把探索資訊和畫面分開

在 Godot 開啟專案，執行主場景，從漢堡選單點地圖圖示。走過新的區域後再次開圖，就會看到對應區塊與尚未領取的探索獎勵。

這次的 `application/exploration_survey.gd` 只回答「玩家已經知道哪些地點」，不修改遊戲。`presentation/exploration_chart.gd` 再把資料畫成地圖。因此日後改配色與圖示，不會意外改到地圖生成或存檔。

小練習：在 `presentation/exploration_chart.gd` 找到 COLORS 的 forest 顏色，稍微調亮後重新執行，觀察探索圖林地區塊的差異，再還原。這只影響選單內的地圖，不改實際森林或獎勵。

尚未收到練習回饋，不記為已掌握。
