# 第 63 課：把玩法限制與角色表演分開

## 這次的移動規則

新旅程慢走速度是 120、快跑倍率 2.6，快跑約 312 世界單位／秒。慢走不扣體力，而且會繼續逐漸恢復。力竭會限制再次快跑，不限制普通移動；站著休息也會恢復。

在 Godot 選主場景根節點，展開 Tuning → Fast running，可調 **Walking Speed** 和 **Fast Run Multiplier**；Immersive journey 下的 **Rest Regen** 決定每秒恢復量。修改一項後按 F6，比較走路與快跑，不需要改戰鬥程式。

`application/campaign_travel.gd` 管理快跑與恢復條件；`bootstrap/frontier_root.gd` 把普通移速換算成角色移動倍率。走路動畫依實際移速降頻，避免慢走還在快速踏步。

## 喘氣是動畫，不是移動鎖

`presentation/knight_visual.gd` 以約 0.38 秒平順切入或離開疲憊姿勢。停下才用彎身喘氣的動作；開始走路就漸漸回到移動姿勢。受擊、死亡則立即交回原本的反應，避免休息動畫蓋過重要事件。

這些過渡權重只存在呈現層，不存進旅程。真正的體力與疲憊狀態仍會存檔，讀檔不會重置體力來繞過恢復限制。

## 營火拔劍

`art/characters/camp-ceremony-v001/draw_sword.png` 是 4×2 格素材，每格 160×128、腳底對齊 y=96。八格包含握劍、下蹲蓄力、拔出、舉劍與收勢。`presentation/knight_ceremony_view.gd` 的 ENDS 是各格結束秒數，控制蓄力停頓和拔出的快慢。

拔劍約 0.82 秒時接上引火、光芒和音效，設施隨後出現。這是可中斷的短演出；移動、攻擊或受擊會讓角色回到實際動作，不會鎖住操作。

新旅程初始龍晶減為 6 顆。Inspector 的 Knight backpack → Initial Crystals 可以調整；既有存檔持有的龍晶不會被扣除。晶袋縮為原本約 62% 尺寸，物理堆疊與 30 顆容量保留。
