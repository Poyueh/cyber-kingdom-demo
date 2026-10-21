# 第155課：場景位置與遊戲規則

本次兩座兵營畫在不同位置，但它們共用裝備庫存；守牆指派保存在application/core_guard_orders.gd的orders陣列。畫面只讀取狀態，不能在重繪時生成居民或扣龍晶。

可在Godot開啟project.godot並按F5，讀取三級營火旅程後走到任一兵營，按E開啟配置：＋花1晶、－免費撤回。觀察左右「已指定／到位」的差別；指定立即生效，士兵走到牆內後才算到位。這次只需體會「按下指令」與「角色完成行動」是兩個時刻。

程式驗收見tests/test_frontier_revision.gd；實際面板與輸入見tests/test_frontier_revision_scene.gd。這份教學不代表使用者已掌握，學習紀錄維持原狀。
