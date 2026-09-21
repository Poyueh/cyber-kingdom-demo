# 第 60 課：角色只有一個身體，介面固定在螢幕

這次疊圖是兩段程式同時控制顯示造成的：`knight_visual.gd` 選好空手／疲勞／連斬圖後，裝備更新又把底層騎士打開。現在 `set_mounted()` 只記錄是否騎乘，`present()` 統一決定本幀要顯示哪個身體，切換前關閉其他姿勢。

Godot 的 `self_modulate.a = 0` 只隱藏這個節點自己的畫面，子節點仍可顯示；因此可讓疲勞姿勢取代基本 AnimatedSprite2D。不要把整個父節點 hide，否則子姿勢也消失。

晶袋屬於 HUD 的 CanvasLayer，使用安全顯示區計算右上角，所以相機和騎士移動時它不動。`presentation/crystal_purse_view.gd` 的 `bounds` 控制位置與尺寸；`presentation/campaign_layout.gd` 排列按鈕。

可試的小練習：先看右上晶袋與左上選單，再走到地圖另一處，確認角色在世界移動、UI 固定在螢幕。這是兩種座標系，尚未假定你已掌握。
