# 69：跑步、衝刺與分段恢復

這次將一般移動與衝刺換成有蹬地、騰空、落地的跑姿；原先貼地的步態只留給力竭慢走。動畫決定姿勢，核心規則決定可用速度，兩者分開維護。

## 在 Godot 調整疲勞

在 FileSystem 點開 `data/travel_recovery.tres`，Inspector 有四項：

- Tired Speed Multiplier：力竭速度占一般跑速的比例，預設 0.42。
- Run Recovery Ratio：恢復一般跑步需要的體力比例，預設 0.30。
- Sprint Recovery Ratio：重新衝刺需要的體力比例，預設 0.75。
- Sprint Rest Seconds：連續停止移動的休息時間，預設 2 秒；移動或出刀會打斷。

完整循環：正常跑步 → 衝刺耗盡 → 慢走喘息 → 30% 體力恢復跑步 → 75% 體力且連續休息 2 秒 → 再次可衝刺。一直拉住第二段會在恢復期跑步，不會自動反覆衝刺。

`data/campaign.tres` 的 Fast Running 群組保留速度設定：Walking Speed 是既有欄位名稱，現在表示一般移動跑速，預設 165；Fast Run Multiplier 為 1.95，衝刺約 322。疲勞慢走約 69。實際手感可以由這幾個數值微調。

## 為什麼另存恢復進度

恢復規則位於 application/campaign_travel.gd，休息以模擬 tick 記錄；暫停不會替玩家累積休息。存檔升到 v11，包含疲勞階段與已休息時間；v10 舊紀錄會升級，疲勞不會因重開遊戲消失。

## 跑姿美術

新圖在 art/characters/flight-run-v001。持劍／空手都使用八格循環，跑步與衝刺使用不同前傾圖，正常 20 fps、衝刺 28 fps。慢走使用上一版十六格圖，12 fps。體力降低時呼氣逐漸加強；停止時再漸變成休息姿勢。

小練習：把 Sprint Rest Seconds 暫時改成 3，開新旅程，耗完體力後比較停下等待的時間，再改回 2。這是改遊戲規則，不需要重畫動畫。
