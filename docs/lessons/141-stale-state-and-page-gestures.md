# 第141課：沒被更新的狀態，和網頁外面的手勢

## 只在某條路徑上更新的欄位會過期

`domain/resident_roaming.gd` 用 `roam_role` 記住「上次漫遊時的身分」，身分一變就以當下位置重新設定漫遊中心 `roam_home`。問題是：只有流浪者和閒置居民會走到這段程式，弓兵在引導流程由守軍命令決定位置，從來不漫遊。所以弓兵的 `roam_role` 一直是當初在野外的「wanderer」，`roam_home` 也還是野外那個點。被打回流浪者時，程式以為「身分沒變」，就照舊走回野外。

修法放在身分改變的那一刻：`domain/settlement.gd` 的 `hit_person()` 把 `roam_role` 從字典移除，下一次漫遊自然以倒下的位置重新開始。這裡不寫成空字串，因為存檔驗證只接受合法身分；移除欄位則是選填欄位的合法狀態。

測試 `tests/test_resident_revert.gd` 先重現：倒下 20 秒後離倒下處 447、離野外原點只剩 13，再修正。

## 數值要用「規則」測，不是用常數測

Demo 開局龍晶改成 `CoreLoopTuning.demo_starting_crystals`（Inspector 可調）。測試沒有寫「必須等於 12」，而是用實際價格算：

> 開局龍晶 + 一次採集 − 首日引導花費（招募 2、錘、委託、弓、牆）≥ 4

之後改價格或收益，這條規則仍然檢查「新手第一天有沒有餘裕」。

## Godot 管不到畫布以外的觸控

Godot 只在自己的畫布上攔截觸控，而且只在事件可以取消時才攔。從畫布以外開始的滑動，或瀏覽器自己的下拉重新整理，就不歸它管。所以這次在網頁外殼加上兩層：
- `web/touch-guard.css`：`overscroll-behavior: none`，並把頁面固定，關掉瀏覽器的下拉與回彈。
- `web/touch-guard.js`：在 `document` 用 `{ passive: false }` 監聽 `touchmove` 並 `preventDefault()`；玩家指南視窗例外，讓它能捲動。

它們透過匯出設定的 `html/head_include` 載入，`tools/build_web.py` 把檔案放進匯出包。
