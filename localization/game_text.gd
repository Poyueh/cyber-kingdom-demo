extends RefCounted
## Stable source text, Traditional Chinese, Simplified Chinese, English.
const ROWS=[
 ["點右側劍鈕攻擊，再點可連斬","點右側劍鈕攻擊，再點可連斬","点右侧剑钮攻击，再点可连斩","Tap the sword button. Tap again to combo."],
 ["按 J 攻擊，再按可連斬","按 J 攻擊，再按可連斬","按 J 攻击，再按可连斩","Press J to attack. Press again to combo."],
 ["第 %d 天", "第 %d 天", "第 %d 天", "Day %d"],
 ["營火正在受襲！", "營火正在受襲！", "营火正在受袭！", "The campfire is under attack!"],
 ["拔出劍，點亮最後的營火。", "拔出劍，點亮最後的營火。", "拔出剑，点亮最后的营火。", "Draw the sword. Kindle the last campfire."],
 ["把龍晶交給流浪者，邀他留下。", "把龍晶交給流浪者，邀他留下。", "把龙晶交给流浪者，邀他留下。", "Offer a crystal to a wanderer. Give them a home."],
 ["提供工程錘，居民會自行取用。", "提供工程錘，居民會自行取用。", "提供工程锤，居民会自行取用。", "Provide a hammer. A resident will take it."],
 ["委託工匠採集，帶回龍晶。", "委託工匠採集，帶回龍晶。", "委托工匠采集，带回龙晶。", "Mark resources for your engineers to harvest."],
 ["提供弓，讓居民狩獵和防守。", "提供弓，讓居民狩獵和防守。", "提供弓，让居民狩猎和防守。", "Provide bows for hunting and defense."],
 ["投入龍晶，讓工匠築起城牆。", "投入龍晶，讓工匠築起城牆。", "投入龙晶，让工匠筑起城墙。", "Invest crystals. Engineers will build the wall."],
 ["夜色降臨，回去保護營火。", "夜色降臨，回去保護營火。", "夜色降临，回去保护营火。", "Night approaches. Return to protect the fire."],
 ["打開寶箱，補充龍晶。", "打開寶箱，補充龍晶。", "打开宝箱，补充龙晶。", "Open the chest to replenish your crystals."],
 ["靠近龍晶，自動收入袋中。", "靠近龍晶，自動收入袋中。", "靠近龙晶，自动收入袋中。", "Approach crystals to collect them."],
 ["沿著荒地探索，尋找居民與資源。", "沿著荒地探索，尋找居民與資源。", "沿着荒地探索，寻找居民与资源。", "Explore the wilds for people and resources."],
 ["擴建避難所，封印雙門並擊敗巨龍。", "擴建避難所，封印雙門並擊敗巨龍。", "扩建避难所，封印双门并击败巨龙。", "Build your refuge. Seal both gates. Slay the dragon."],
 ["左右拖曳移動，拉遠加速", "左右拖曳移動，拉遠加速", "左右拖曳移动，拉远加速", "Drag left or right. Drag farther to run."],
 ["A／D 移動；Shift 快跑", "A／D 移動；Shift 快跑", "A／D 移动；Shift 快跑", "A / D to move; Shift to run."],
 ["向下拖曳並按住投入／互動", "向下拖曳並按住投入／互動", "向下拖曳并按住投入／互动", "Drag down and hold to invest / interact."],
 ["按住 E 投入／互動", "按住 E 投入／互動", "按住 E 投入／互动", "Hold E to invest / interact."],
 ["在附近向下滑動丟出龍晶", "在附近向下滑動丟出龍晶", "在附近向下滑动丢出龙晶", "Swipe down nearby to offer a crystal."],
 ["按 Q 丟出龍晶", "按 Q 丟出龍晶", "按 Q 丢出龙晶", "Press Q to offer a crystal."],
 ["等待居民自行領取器具", "等待居民自行領取器具", "等待居民自行领取器具", "Wait for a resident to take the tool."],
 ["跳過前導", "跳過前導", "跳过前导", "Skip intro"],
 ["魔法與巨龍統治荒野，人類只剩機械義肢與一縷火光。", "魔法與巨龍統治荒野，人類只剩機械義肢與一縷火光。", "魔法与巨龙统治荒野，人类只剩机械义肢与一缕火光。", "Magic and dragons rule the wilds. Humanity survives on steel limbs and a fading flame."],
 ["拔出龍晶之劍，點亮營火，為流浪的人建立家園。", "拔出龍晶之劍，點亮營火，為流浪的人建立家園。", "拔出龙晶之剑，点亮营火，为流浪的人建立家园。", "Draw the crystal sword. Kindle the fire. Give the wanderers a home."],
 ["把龍晶交給居民，提供器具，讓他們採集、建造與狩獵。", "把龍晶交給居民，提供器具，讓他們採集、建造與狩獵。", "把龙晶交给居民，提供器具，让他们采集、建造与狩猎。", "Offer crystals and tools. Your people gather, build and hunt."],
 ["夜裡守住營火。有限的龍晶，要留給自己還是居民？", "夜裡守住營火。有限的龍晶，要留給自己還是居民？", "夜里守住营火。有限的龙晶，要留给自己还是居民？", "Protect the fire at night. Spend your scarce crystals on yourself, or your people?"],
 ["封印兩側地獄之門，召出巨龍。帶著你的王國，迎戰最後一夜。", "封印兩側地獄之門，召出巨龍。帶著你的王國，迎戰最後一夜。", "封印两侧地狱之门，召出巨龙。带着你的王国，迎战最后一夜。", "Seal both gates to summon the dragon. Lead your kingdom into the final night."],
 [
  "最後的避難所",
  "最後的避難所",
  "最后的避难所",
  "The Last Refuge"
 ],
 [
  "帶著龍晶出征，帶著大家回家。",
  "帶著龍晶出征，帶著大家回家。",
  "带着龙晶出征，带着大家回家。",
  "Carry hope out. Bring everyone home."
 ],
 [
  "旅程",
  "旅程",
  "旅程",
  "Journeys"
 ],
 [
  "新遊戲",
  "新遊戲",
  "新游戏",
  "New Game"
 ],
 [
  "選擇紀錄",
  "選擇紀錄",
  "选择记录",
  "Load Journey"
 ],
 [
  "每次新遊戲都另存一段旅程。",
  "每次新遊戲都另存一段旅程。",
  "每次新游戏都另存一段旅程。",
  "Each new game creates a separate journey."
 ],
 [
  "玩家圖文指南",
  "玩家圖文指南",
  "玩家图文指南",
  "Player Guide"
 ],
 [
  "返回",
  "返回",
  "返回",
  "Back"
 ],
 [
  "還沒有旅程，先建立新遊戲。",
  "還沒有旅程，先建立新遊戲。",
  "还没有旅程，先创建新游戏。",
  "No journeys yet. Start a new game."
 ],
 [
  "手動檢查點 · 另存續玩",
  "手動檢查點 · 另存續玩",
  "手动存档点 · 另存继续",
  "Manual checkpoint · continue as new"
 ],
 [
  "先前旅程",
  "先前旅程",
  "先前旅程",
  "Previous journey"
 ],
 [
  "自動紀錄",
  "自動紀錄",
  "自动存档",
  "Autosave"
 ],
 [
  "%s\n無法讀取 · 原檔已保留",
  "%s\n無法讀取 · 原檔已保留",
  "%s\n无法读取 · 原文件已保留",
  "%s\nUnreadable · original preserved"
 ],
 [
  " · 已通關",
  " · 已通關",
  " · 已通关",
  " · Completed"
 ],
 [
  " · 挑戰結束",
  " · 挑戰結束",
  " · 挑战结束",
  " · Defeated"
 ],
 [
  "第 %d 天 · 聚落 %d%s\n%s",
  "第 %d 天 · 聚落 %d%s\n%s",
  "第 %d 天 · 聚落 %d%s\n%s",
  "Day %d · Settlement %d%s\n%s"
 ],
 [
  "保存並回起始頁",
  "保存並回起始頁",
  "保存并返回主菜单",
  "Save and return to title"
 ],
 [
  "無法建立紀錄，請確認裝置有可用空間後再試一次。",
  "無法建立紀錄，請確認裝置有可用空間後再試一次。",
  "无法创建存档，请确认设备有可用空间后重试。",
  "Cannot create a save. Check available storage and try again."
 ],
 [
  "紀錄無法讀取，原檔已保留。請重新選擇。 ",
  "紀錄無法讀取，原檔已保留。請重新選擇。 ",
  "存档无法读取，原文件已保留。请重新选择。 ",
  "Cannot load this save. The original is preserved. Choose again."
 ],
 [
  "無法另存檢查點，原紀錄未變更。請稍後重試。 ",
  "無法另存檢查點，原紀錄未變更。請稍後重試。 ",
  "无法另存存档点，原存档未更改。请稍后重试。 ",
  "Cannot copy this checkpoint. Your original save is unchanged. Try again."
 ],
 [
  "跟隨系統／平台",
  "跟隨系統／平台",
  "跟随系统／平台",
  "System / platform"
 ],
 [
  "語言",
  "語言",
  "语言",
  "Language"
 ],
 [
  "語言設定未能保存；本次仍可使用，稍後重新選擇可重試。",
  "語言設定未能保存；本次仍可使用，稍後重新選擇可重試。",
  "语言设置未能保存；本次仍可使用，稍后重新选择可重试。",
  "Language could not be saved. It applies for now; select again to retry."
 ],
 [
  "新地圖 [N]",
  "新地圖 [N]",
  "新地图 [N]",
  "New Map [N]"
 ],
 [
  "A/D 移動　E 標記／建設　J 戰鬥　L 衝刺　Space 跳躍　R 重玩此圖",
  "A/D 移動　E 標記／建設　J 戰鬥　L 衝刺　Space 跳躍　R 重玩此圖",
  "A/D 移动　E 标记／建设　J 战斗　L 冲刺　Space 跳跃　R 重玩此图",
  "A/D Move · E Mark / Build · J Attack · L Dash · Space Jump · R Retry Map"
 ],
 [
  "龍晶邊境 #%d · 探索 %d/6 · 拓荒站 %d",
  "龍晶邊境 #%d · 探索 %d/6 · 拓荒站 %d",
  "龙晶边境 #%d · 探索 %d/6 · 拓荒站 %d",
  "Crystal Frontier #%d · Explored %d/6 · Outposts %d"
 ],
 [
  "生命 %d  盾 %d  廢料 %d  龍晶 %d  木材 %d  食物 %d",
  "生命 %d  盾 %d  廢料 %d  龍晶 %d  木材 %d  食物 %d",
  "生命 %d  盾 %d  废料 %d  龙晶 %d  木材 %d  食物 %d",
  "HP %d  Shield %d  Scrap %d  Crystals %d  Wood %d  Food %d"
 ],
 [
  "王國建立！三波守成、王城與居民都保住了。N 開始另一片邊境。",
  "王國建立！三波守成、王城與居民都保住了。N 開始另一片邊境。",
  "王国建立！三波守成、王城与居民都保住了。N 开始另一片边境。",
  "Kingdom established! Three raids survived. Press N for another frontier."
 ],
 [
  "夜襲已退 / 目標：王城 3 級、防線 2 級存活、至少 3 位居民。",
  "夜襲已退 / 目標：王城 3 級、防線 2 級存活、至少 3 位居民。",
  "夜袭已退 / 目标：王城 3 级、防线 2 级存活、至少 3 位居民。",
  "Raids repelled / Goal: level 3 town, surviving level 2 wall, at least 3 residents."
 ],
 [
  "夜襲 %d 秒 / 城鎮 %d/3 · 工坊備器具 → E 標記 → 工匠採集搬運",
  "夜襲 %d 秒 / 城鎮 %d/3 · 工坊備器具 → E 標記 → 工匠採集搬運",
  "夜袭 %d 秒 / 城镇 %d/3 · 工坊备器具 → E 标记 → 工匠采集搬运",
  "Raid in %d s / Town %d/3 · Stock tools → E to mark → Engineers gather"
 ],
 [
  "標記居民工作 [E]",
  "標記居民工作 [E]",
  "标记居民工作 [E]",
  "Assign work [E]"
 ],
 [
  "營火 · 王國由此開始",
  "營火 · 王國由此開始",
  "营火 · 王国由此开始",
  "Campfire · A kingdom begins"
 ],
 [
  "聚落 %d/3 · 收貨點",
  "聚落 %d/3 · 收貨點",
  "聚落 %d/3 · 收货点",
  "Settlement %d/3 · Delivery point"
 ],
 [
  "防護 ×%d",
  "防護 ×%d",
  "防护 ×%d",
  "Protection ×%d"
 ],
 [
  "REFUGE / 避難所",
  "REFUGE / 避難所",
  "REFUGE / 避难所",
  "REFUGE"
 ],
 [
  "龍晶分配試驗  /  每輪重置，尚未保存出征進度",
  "龍晶分配試驗  /  每輪重置，尚未保存出征進度",
  "龙晶分配试验  /  每轮重置，尚未保存出征进度",
  "Crystal allocation trial / Resets each round; expedition progress is not saved"
 ],
 [
  "改造騎士",
  "改造騎士",
  "改造骑士",
  "Augmented Knight"
 ],
 [
  "返回訓練場",
  "返回訓練場",
  "返回训练场",
  "Back to Training"
 ],
 [
  "確認配置，出征",
  "確認配置，出征",
  "确认配置，出征",
  "Confirm and Depart"
 ],
 [
  "最後的避難所  /  這次，能源留給誰？",
  "最後的避難所  /  這次，能源留給誰？",
  "最后的避难所  /  这次，能源留给谁？",
  "The Last Refuge / Who gets the energy?"
 ],
 [
  "魔潮預報：%d 名居民各承受一次衝擊。每顆龍晶可護住 1 人。",
  "魔潮預報：%d 名居民各承受一次衝擊。每顆龍晶可護住 1 人。",
  "魔潮预报：%d 名居民各承受一次冲击。每颗龙晶可护住 1 人。",
  "Raid forecast: %d residents each face one hit. Each crystal protects one person."
 ],
 [
  "護盾  %d\n分配 %d 顆龍晶",
  "護盾  %d\n分配 %d 顆龍晶",
  "护盾  %d\n分配 %d 颗龙晶",
  "Shield  %d\nAssigned %d crystals"
 ],
 [
  "居民防護  %d / %d 人",
  "居民防護  %d / %d 人",
  "居民防护  %d / %d 人",
  "Residents protected  %d / %d"
 ],
 [
  "共 %d 顆龍晶：騎士 %d ／ 避難所 %d。\n預計 %d 人受傷；騎士護盾承受傷害後不再恢復。",
  "共 %d 顆龍晶：騎士 %d ／ 避難所 %d。\n預計 %d 人受傷；騎士護盾承受傷害後不再恢復。",
  "共 %d 颗龙晶：骑士 %d ／ 避难所 %d。\n预计 %d 人受伤；骑士护盾承受伤害后不再恢复。",
  "%d crystals: knight %d / refuge %d.\nExpected injuries: %d. Shield damage does not regenerate."
 ],
 [
  "擊敗守衛帶回廢料；撤退或倒下也會結算魔潮。出征後配置鎖定。",
  "擊敗守衛帶回廢料；撤退或倒下也會結算魔潮。出征後配置鎖定。",
  "击败守卫带回废料；撤退或倒下也会结算魔潮。出征后配置锁定。",
  "Defeat the sentinel for scrap. Retreat or defeat also resolves the raid. Allocation locks on departure."
 ],
 [
  "騎士 %d  /  避難所 %d",
  "騎士 %d  /  避難所 %d",
  "骑士 %d  /  避难所 %d",
  "Knight %d / Refuge %d"
 ],
 [
  "騎士 %d\n避難所 %d",
  "騎士 %d\n避難所 %d",
  "骑士 %d\n避难所 %d",
  "Knight %d\nRefuge %d"
 ],
 [
  "出征成功",
  "出征成功",
  "出征成功",
  "Expedition won"
 ],
 [
  "提前撤退",
  "提前撤退",
  "提前撤退",
  "Retreated"
 ],
 [
  "騎士倒下",
  "騎士倒下",
  "骑士倒下",
  "Knight fallen"
 ],
 [
  "魔潮過後  /  ",
  "魔潮過後  /  ",
  "魔潮过后  /  ",
  "After the raid / "
 ],
 [
  "魔潮已結算：%d 人安然無恙，%d 人受傷。",
  "魔潮已結算：%d 人安然無恙，%d 人受傷。",
  "魔潮已结算：%d 人安然无恙，%d 人受伤。",
  "Raid resolved: %d safe, %d injured."
 ],
 [
  "生命  %d\n護盾擋下 %d 傷害",
  "生命  %d\n護盾擋下 %d 傷害",
  "生命  %d\n护盾挡下 %d 伤害",
  "HP  %d\nShield absorbed %d damage"
 ],
 [
  "避難所  /  %d 名居民受傷",
  "避難所  /  %d 名居民受傷",
  "避难所  /  %d 名居民受伤",
  "Refuge / %d residents injured"
 ],
 [
  "帶回廢料 %d　剩餘護盾 %d\n本次配置：騎士 %d 顆 ／ 避難所 %d 顆",
  "帶回廢料 %d　剩餘護盾 %d\n本次配置：騎士 %d 顆 ／ 避難所 %d 顆",
  "带回废料 %d　剩余护盾 %d\n本次配置：骑士 %d 颗 ／ 避难所 %d 颗",
  "Scrap recovered %d  Shield remaining %d\nAllocation: knight %d / refuge %d crystals"
 ],
 [
  "重試會還原本輪龍晶與居民，供比較不同選擇；這不是永久死亡或完整經營系統。",
  "重試會還原本輪龍晶與居民，供比較不同選擇；這不是永久死亡或完整經營系統。",
  "重试会还原本轮龙晶与居民，供比较不同选择；这不是永久死亡或完整经营系统。",
  "Retry resets this round's crystals and residents to compare choices. This is an allocation trial."
 ],
 [
  "重新分配，再試一次",
  "重新分配，再試一次",
  "重新分配，再试一次",
  "Reallocate and Retry"
 ],
 [
  "訓練場",
  "訓練場",
  "训练场",
  "Training"
 ],
 [
  "最後的避難所 / 現場建設",
  "最後的避難所 / 現場建設",
  "最后的避难所 / 现场建设",
  "The Last Refuge / Build on Site"
 ],
 [
  "A/D 移動　E 投入　J 劈砍　L 衝刺　Space 跳躍　R 重試",
  "A/D 移動　E 投入　J 劈砍　L 衝刺　Space 跳躍　R 重試",
  "A/D 移动　E 投入　J 劈砍　L 冲刺　Space 跳跃　R 重试",
  "A/D Move · E Invest · J Attack · L Dash · Space Jump · R Retry"
 ],
 [
  "生命 %d  護盾 %d  廢料 %d  龍晶 %d",
  "生命 %d  護盾 %d  廢料 %d  龍晶 %d",
  "生命 %d  护盾 %d  废料 %d  龙晶 %d",
  "HP %d  Shield %d  Scrap %d  Crystals %d"
 ],
 [
  "投入 %d %s  [E]",
  "投入 %d %s  [E]",
  "投入 %d %s  [E]",
  "Invest %d %s [E]"
 ],
 [
  "互動 [E]",
  "互動 [E]",
  "互动 [E]",
  "Interact [E]"
 ],
 [
  "已暫停 / Esc 或 PAUSE 繼續",
  "已暫停 / Esc 或 PAUSE 繼續",
  "已暂停 / Esc 或 PAUSE 继续",
  "Paused / Esc or Pause to resume"
 ],
 [
  "騎士倒下 / R 重試整段避難所",
  "騎士倒下 / R 重試整段避難所",
  "骑士倒下 / R 重试整段避难所",
  "Knight fallen / R to retry the refuge"
 ],
 [
  "三波試煉結束。留下的居民與防線，就是本輪的結果。",
  "三波試煉結束。留下的居民與防線，就是本輪的結果。",
  "三波试炼结束。留下的居民与防线，就是本轮的结果。",
  "Three raids complete. Your surviving residents and defenses are this round's outcome."
 ],
 [
  "第 %d 波來襲！保護居民；敵人倒下的廢料要靠近回收。",
  "第 %d 波來襲！保護居民；敵人倒下的廢料要靠近回收。",
  "第 %d 波来袭！保护居民；敌人倒下的废料要靠近回收。",
  "Raid %d! Protect residents; approach fallen enemies to collect scrap."
 ],
 [
  "夜襲約 %d 秒後 / 招攬居民 → 供應器具 → 建造防線",
  "夜襲約 %d 秒後 / 招攬居民 → 供應器具 → 建造防線",
  "夜袭约 %d 秒后 / 招揽居民 → 供应器具 → 建造防线",
  "Raid in about %d s / Recruit → Stock tools → Build defenses"
 ],
 [
  "未探索的邊境",
  "未探索的邊境",
  "未探索的边境",
  "Unexplored frontier"
 ],
 [
  "龍晶林 · 標記居民伐木",
  "龍晶林 · 標記居民伐木",
  "龙晶林 · 标记居民伐木",
  "Crystal forest · Assign logging"
 ],
 [
  "晶脈 · 標記居民採礦",
  "晶脈 · 標記居民採礦",
  "晶脉 · 标记居民采矿",
  "Crystal veins · Assign mining"
 ],
 [
  "舊王朝遺跡 · 回收廢料",
  "舊王朝遺跡 · 回收廢料",
  "旧王朝遗迹 · 回收废料",
  "Ancient ruins · Recover scrap"
 ],
 [
  "施工 %d%%",
  "施工 %d%%",
  "施工 %d%%",
  "Building %d%%"
 ],
 [
  "拓荒站",
  "拓荒站",
  "拓荒站",
  "Outpost"
 ],
 [
  "已清理 · 可拓建",
  "已清理 · 可拓建",
  "已清理 · 可拓建",
  "Cleared · Ready to expand"
 ],
 [
  "王城",
  "王城",
  "王城",
  "Citadel"
 ],
 [
  "聚落 %d/3",
  "聚落 %d/3",
  "聚落 %d/3",
  "Settlement %d/3"
 ],
 [
  "工坊 / 工程器具",
  "工坊 / 工程器具",
  "工坊 / 工程器具",
  "Workshop / Engineering tools"
 ],
 [
  "武器坊 / 守備器具",
  "武器坊 / 守備器具",
  "武器坊 / 守备器具",
  "Armory / Guard equipment"
 ],
 [
  "義肢爐",
  "義肢爐",
  "义肢炉",
  "Prosthesis Forge"
 ],
 [
  "護民塔 ×%d",
  "護民塔 ×%d",
  "护民塔 ×%d",
  "Refuge Beacon ×%d"
 ],
 [
  "防線 %d/2",
  "防線 %d/2",
  "防线 %d/2",
  "Wall %d/2"
 ],
 [
  "工匠施工中",
  "工匠施工中",
  "工匠施工中",
  "Engineer at work"
 ],
 [
  "警鐘",
  "警鐘",
  "警钟",
  "Alarm bell"
 ],
 [
  "農具架",
  "農具架",
  "农具架",
  "Farming tools"
 ],
 [
  "獵具架",
  "獵具架",
  "猎具架",
  "Hunting tools"
 ],
 [
  "農田 / 自動留種",
  "農田 / 自動留種",
  "农田 / 自动留种",
  "Farm / Seeds retained"
 ],
 [
  "可開墾農地",
  "可開墾農地",
  "可开垦农地",
  "Available farmland"
 ],
 [
  "訓練 %d/%d",
  "訓練 %d/%d",
  "训练 %d/%d",
  "Training %d/%d"
 ],
 [
  "流浪者",
  "流浪者",
  "流浪者",
  "Wanderer"
 ],
 [
  "居民",
  "居民",
  "居民",
  "Resident"
 ],
 [
  "工匠",
  "工匠",
  "工匠",
  "Engineer"
 ],
 [
  "農夫",
  "農夫",
  "农夫",
  "Farmer"
 ],
 [
  "獵人",
  "獵人",
  "猎人",
  "Hunter"
 ],
 [
  "守備兵",
  "守備兵",
  "守备兵",
  "Guard"
 ],
 [
  "搬運中",
  "搬運中",
  "搬运中",
  "Hauling"
 ],
 [
  "作業中",
  "作業中",
  "作业中",
  "Working"
 ],
 [
  "工坊 / 工程錘",
  "工坊 / 工程錘",
  "工坊 / 工程锤",
  "Workshop / Engineering hammer"
 ],
 [
  "防線 Lv.%d",
  "防線 Lv.%d",
  "防线 Lv.%d",
  "Wall Lv.%d"
 ],
 [
  "E / 投入 %d %s",
  "E / 投入 %d %s",
  "E / 投入 %d %s",
  "E / Invest %d %s"
 ],
 [
  "E / 互動",
  "E / 互動",
  "E / 互动",
  "E / Interact"
 ],
 [
  "龍晶",
  "龍晶",
  "龙晶",
  "Crystals"
 ],
 [
  "工程師",
  "工程師",
  "工程师",
  "Engineer"
 ],
 [
  "HP %d/%d   SHIELD %d   CHARGE %d   SCRAP %d",
  "生命 %d/%d   護盾 %d   體力 %d   廢料 %d",
  "生命 %d/%d   护盾 %d   体力 %d   废料 %d",
  "HP %d/%d   SHIELD %d   CHARGE %d   SCRAP %d"
 ],
 [
  "PAUSED — Esc or PAUSE to resume",
  "已暫停 — Esc 或暫停鍵繼續",
  "已暂停 — Esc 或暂停键继续",
  "PAUSED — Esc or PAUSE to resume"
 ],
 [
  "OATH BROKEN — press R / RESTART",
  "騎士倒下 — R 或重試",
  "骑士倒下 — R 或重试",
  "OATH BROKEN — press R / RESTART"
 ],
 [
  "SENTINEL DEFEATED — R / RESTART to train again",
  "守衛已擊敗 — R 或重試再次訓練",
  "守卫已击败 — R 或重试再次训练",
  "SENTINEL DEFEATED — R / RESTART to train again"
 ],
 [
  "Defeat the sentinel for salvage. R / RETURN retreats to the refuge.",
  "擊敗守衛取得廢料。R 或返回可撤退至避難所。",
  "击败守卫取得废料。R 或返回可撤退至避难所。",
  "Defeat the sentinel for salvage. R / RETURN retreats to the refuge."
 ],
 [
  "Prosthesis trial: cross the platforms. Watch for amber warnings.",
  "義肢試煉：越過平台，留意琥珀色攻擊預警。",
  "义肢试炼：越过平台，留意琥珀色攻击预警。",
  "Prosthesis trial: cross the platforms. Watch for amber warnings."
 ],
 [
  "RETREAT / RETURN",
  "撤退／返回",
  "撤退／返回",
  "RETREAT / RETURN"
 ],
 [
  "CYBER KINGDOM / EXPEDITION",
  "CYBER KINGDOM／出征",
  "CYBER KINGDOM／出征",
  "CYBER KINGDOM / EXPEDITION"
 ],
 [
  "A/D MOVE   SPACE JUMP   J HIT   L DASH   R RETURN",
  "A/D 移動　Space 跳躍　J 劈砍　L 衝刺　R 返回",
  "A/D 移动　Space 跳跃　J 劈砍　L 冲刺　R 返回",
  "A/D MOVE   SPACE JUMP   J HIT   L DASH   R RETURN"
 ],
 [
  "CYBER KINGDOM  /  REFUGE TRIAL",
  "CYBER KINGDOM／避難所試煉",
  "CYBER KINGDOM／避难所试炼",
  "CYBER KINGDOM  /  REFUGE TRIAL"
 ],
 [
  "Approach the sentinel.",
  "接近守衛。",
  "接近守卫。",
  "Approach the sentinel."
 ],
 [
  "A/D MOVE   SPACE JUMP   J HIT   L DASH   R RESTART",
  "A/D 移動　Space 跳躍　J 劈砍　L 衝刺　R 重試",
  "A/D 移动　Space 跳跃　J 劈砍　L 冲刺　R 重试",
  "A/D MOVE   SPACE JUMP   J HIT   L DASH   R RESTART"
 ],
 [
  "LEFT",
  "向左",
  "向左",
  "LEFT"
 ],
 [
  "RIGHT",
  "向右",
  "向右",
  "RIGHT"
 ],
 [
  "DASH",
  "衝刺",
  "冲刺",
  "DASH"
 ],
 [
  "JUMP",
  "跳躍",
  "跳跃",
  "JUMP"
 ],
 [
  "HIT",
  "劈砍",
  "劈砍",
  "HIT"
 ],
 [
  "PAUSE",
  "暫停",
  "暂停",
  "PAUSE"
 ],
 [
  "RESTART",
  "重試",
  "重试",
  "RESTART"
 ],
 [
  "兵營",
  "兵營",
  "兵营",
  "Barracks"
 ],
 [
  "需要更高級聚落，或兵營已滿級",
  "需要更高級聚落，或兵營已滿級",
  "需要更高级聚落，或兵营已满级",
  "Requires a higher settlement tier, or barracks are fully upgraded"
 ],
 [
  "守護塔",
  "守護塔",
  "守护塔",
  "Defense tower"
 ],
 [
  "升級守護塔",
  "升級守護塔",
  "升级守护塔",
  "Upgrade defense tower"
 ],
 [
  "升級堡壘",
  "升級堡壘",
  "升级堡垒",
  "Upgrade fortress"
 ],
 [
  "等待工匠施工，或先升級聚落",
  "等待工匠施工，或先升級聚落",
  "等待工匠施工，或先升级聚落",
  "Await construction, or upgrade the settlement first"
 ]
]
