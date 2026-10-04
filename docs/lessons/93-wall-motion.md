# 第 93 課：怪物的每一種位移都要遵守城牆

本次城牆不是 Godot 碰撞體，而是核心規則。一般走路會選城牆作目標，但部件與重斬直接改位置、抱晶撤退走另一條流程，於是漏掉阻擋。

現在位移統一經過 `application/settlement_session.gd` 的 `move_raider`；抱晶怪受阻時先走既有攻牆流程。規則依 `world.wall_operational()` 判定，施工與毀損仍可通行。

Godot 小練習：在腳本編輯器搜尋 `move_raider`，比較正常追擊、部件擊退與抱晶撤退三個呼叫位置。日後新增衝撞怪，也應使用這個入口。測試見 `tests/test_wall_motion.gd`；未記錄為已掌握。
