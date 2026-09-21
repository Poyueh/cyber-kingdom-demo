# 59：微調付款保留時間

Godot 開啟 scenes/frontier.tscn，選最上層節點，在 Inspector 展開 Tuning，找到 Investment Refund Delay。預設1秒；改成1.3，再試著付一顆、放開、隔一會點上方龍晶格，感受續填是否更從容。

這是操作時間設定，由 application/investment_hold.gd 管理；presentation/campaign_view.gd 畫龍晶格。改時間不用改美術，也不改既有旅程的經濟數值。疲勞動作和袋子另放在 presentation/knight_fatigue_view.gd、crystal_purse_view.gd，避免把呈現混進戰鬥規則。
