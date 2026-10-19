# 第143課：同一個「看不看得到」只能有一個答案

## 為什麼部件工坊會閃一下

v0.0.65 讓部件工坊在找到部件前不出現，規則寫在 `application/campaign_session.gd` 的 `site_visible("drill")`。但點火時的組裝動畫 `presentation/camp_reveal.gd` 自己列了一份要組裝的建築，裡面固定有 `drill`。結果：動畫先把工坊連鷹架畫出來，動畫結束後一般畫面再依規則把它藏起來——看起來就是閃一下。

修法是讓兩邊問同一個問題：`camp_reveal.gd` 新增 `assembling_sites(sim)`，部件工坊改成「`site_visible` 說可以才組裝」。測試直接檢查這個清單，不必去拍動畫。

> 當你發現一個顯示規則，先搜尋還有哪些地方畫同一個東西（`grep "drill"`），把它們都接到同一個判斷。

## 鬼魂喊目標：規則放 application，節奏放資料

- `application/spirit_callouts.gd` 只讀取世界狀態，決定現在是「撐過夜襲／擊敗巨龍／封門／採集龍晶／建造」哪一個。它不改模擬，所以可以在任何時候呼叫。
- 多久喊一次放在 `data/spirit_companion.tres` 的 `callout_interval`（20 秒）和 `callout_seconds`（3.5 秒），在 Inspector 就能調。
- 畫面用「這個目標已經持續多久」（`spirit_pose.age`）取餘數：`fposmod(age, 20)` 落在前 3.5 秒就顯示。不需要計時器，換目標時 `age` 自然歸零，立刻再喊。

## HUD 小改

- 耐力條放到騎士腳下：馬蹄和騎士的腳都踩在同一條地面，所以騎馬時不需要另外抬高。
- 晶袋常駐後，數字旁邊不必再寫「龍晶」：袋子本身就說明了在數什麼，改用龍晶圖示加「×數字」。
