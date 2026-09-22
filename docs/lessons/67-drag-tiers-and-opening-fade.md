# 67：拖曳分段與前導淡入

這次拖曳箭頭讀取實際移動意圖：第一段亮青色箭頭，第二段再亮金色箭頭。拉到 84 個介面單位進入第二段，退回 72 以下才回第一段，這段差距讓手指微晃不會一直切速度。規則在 presentation/drag_state.gd，繪圖在 drag_controls.gd，彼此分開。

在 Godot 打開 presentation/campaign_prologue.gd，可以看到匯出的 **Opening Fade Seconds**（預設 1.6）。淡入期間先停住演出，不顯示字幕；淡入結束才啟動舞台，因此不會一邊黑畫面、一邊漏掉劇情。跳過仍立即釋放整個前導場景。

選取騎士的 KnightVisual，**Walking Frame Rate** 與 **Running Frame Rate** 控制動作節奏，這次為 12／18；角色真的走多快由遊戲移動數值決定。修改動畫速度不會替玩家多扣體力，也不改存檔。新的持劍和無劍跑姿在 art/characters/stride-v001，替換圖時需維持 128×96 的切格。
