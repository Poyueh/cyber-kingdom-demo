# 第124課：把黑幕和文字分開計時

在 Godot 的 FileSystem 找到 `data/outcome_direction.tres`，點選後在 Inspector 看 `Blackout End` 與 `Message Start`。

前者是黑幕變成全黑的時間，後者是失敗文字開始出现、移動鎖定的時間。現在是1.65與1.85秒，留0.2秒全黑停頓。練習把 Message Start 改成2.1、Message End 改成2.9，播放營火失敗情境觀察停頓，再還原。保持 Last Blow Hold < Blackout End < Message Start < Message End；這些只控制演出，不改營火耐久或存檔格式。
