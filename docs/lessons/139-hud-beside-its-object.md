# 第139課：把 HUD 放在它描述的東西旁邊

耐力屬於騎士，龍晶數屬於晶袋，所以這次把兩個數值搬到它們的物件旁。重點是：HUD 在 CanvasLayer 的螢幕座標，騎士在世界座標，兩者要換算。

## 世界座標 → 螢幕座標

`presentation/campaign_hud.gd` 這樣算騎士在畫面上的位置：

```gdscript
get_viewport().get_canvas_transform()*Vector2(at,sim._player_y)
```

`get_canvas_transform()` 包含攝影機的位移與縮放，乘上世界座標就得到 HUD 用的座標。鬼魂也用同一個算法，所以兩者會一起跟著騎士移動。

## 從量測得到常數，不用猜

`presentation/core_loop_hud.gd` 的 `STAMINA_LIFT=82`、`MOUNTED_LIFT=28` 來自實際截圖量測：站立時頭盔頂端約在錨點上方 68，騎馬時約 95。測試 `tests/test_core_loop_scene.gd` 也用這兩個量測值檢查「在頭盔上方、但不會太遠」。之後如果換了騎士美術，先重新量，再改常數和測試註解。

## ProgressBar 要自己給樣式

第一次截圖時耐力條看起來偏左、顏色很淡，其實位置是對的：預設主題沒有畫出底槽，45% 時只看得到左半的填色。用 `add_theme_stylebox_override("background", ...)` 和 `("fill", ...)` 各給一個 `StyleBoxFlat`，就能看出剩多少；低於 18% 時直接改 fill 的 `bg_color` 變紅。

## 讓數字跟著另一個節點

龍晶數的位置來自晶袋的 `bounds`（`presentation/crystal_purse_view.gd`）：放在袋子左邊、垂直置中。因為 `core_hud.present()` 在晶袋更新之後才被呼叫，拿到的一定是這一幀的位置。
