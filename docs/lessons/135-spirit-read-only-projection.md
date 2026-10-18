# 鬼魂怎麼知道下一步

打開 `application/core_spirit_guide.gd`，看 `income()` 如何從工匠持晶與地上實際掉落選出目標。這裡只讀世界，不能送龍晶或把教學設成完成。

再開 `presentation/campaign_guide_view.gd`：`mood` 控制托手、等待和警戒動作，`_celebrate_until` 只控制短暫光點。這就是把「遊戲事實」與「怎麼演出」分開：調漂亮不會改壞進度。

小練習：在 `scenes/frontier.tscn` 的 HUD 中找到 Guide View（執行時建立），看 Spirit Distance／Spirit Height 如何改變伴隨位置；改前記下原值。這只是建議練習，尚未確認使用者完成。
