# 第142課：網頁上的幀數要「量」，不能只看設定

手機玩 H5 會燙，先量再改。這次在頁面裡包一層 `requestAnimationFrame`，記錄每一幀主執行緒花了多少時間：

| 版本 | 遊戲中主執行緒（毫秒／秒） |
|---|---|
| v0.0.64（不限幀，120Hz 螢幕跑 120 幀） | 約 300 |
| 手機設定：30 幀＋物理 30Hz | 約 142 |

## `Engine.max_fps` 在網頁上會忙等

第一版用 `Engine.max_fps = 30`，結果主執行緒反而 98% 忙：單執行緒的網頁沒辦法「睡」，Godot 只能空轉等時間。所以改成 `web/frame-pacing.js`：瀏覽器叫動畫幀時，時間還沒到就直接不叫 Godot，主執行緒真的休息。上限值仍在 `data/web_performance.tres`，由 `bootstrap/frame_pacing.gd` 啟動時傳給頁面。

## 畫面幀數和物理更新是兩件事

只把畫面降到 30 幀，省下的不多，因為 `_physics_process` 每秒仍跑 60 次：模擬、騎士移動、場景和 HUD 準備都在裡面。而模擬時鐘 `domain/time/tick_clock.gd` 本來就是每秒 30 刻，所以手機網頁把 `Engine.physics_ticks_per_second` 設為 30，固定成本直接減半。

## 其他兩個手機設定

- `web/phone-display.js`：三倍螢幕的像素比限制為 2，像素畫看不出差別，GPU 每幀少填一半以上的像素。
- 網頁音樂改用 `AudioStreamPlayer.playback_type = PLAYBACK_TYPE_STREAM`：邊播邊解，不再整首解壓放在頁面裡；短音效仍用樣本播放，延遲最低。

## 一起做的版面修正

營地間距的測試不寫死座標，而是檢查「實際畫出來的東西」相鄰是否至少 150 像素（塔可以貼牆）。版面數值集中在 `application/core_loop_layout.gd` 的常數，`guided_forest_layout.gd` 直接引用，不再各寫一份。

後續v0.0.74修正：短音效也改用Stream。反覆Sample播放在長時間手機試玩仍有音訊配置壓力，詳見[第151課](151-web-audio-allocation-and-soak.md)；上面的「短音效仍用樣本」為v0.0.65歷史決策。
