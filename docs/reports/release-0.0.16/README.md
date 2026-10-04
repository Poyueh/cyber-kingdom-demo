# v0.0.16 城牆穿越修正驗證

完工城牆的擊退與持晶撤退漏了阻擋。修正前左右兩側共 8 個行為斷言失敗（red.log），統一敵人位移入口後通過。補齊測試後核心 2,485 斷言零失敗，完整 tools/check.sh 回歸通過，無 SCRIPT ERROR／ERROR，結果見 check.log；打包後的原生 PCK 也通過同一場景測試。

原生 Godot 實際 frontier 場景：三級牆內的抱晶怪、牆外的進攻怪，經 180 次場景更新後仍在各自一側且牆有受傷；抱晶未丟失。fixture 停用存檔，不讀寫玩家紀錄。native-smoke.gd.txt 保存可重現操作，native-wall.png 為原生渲染截圖。

施工／升級／修復以及已毀損牆仍通行。保存格式不變；本次沒有修復在舊版中已經穿入城內的敵人位置，更新後阻擋其後續穿牆。Windows／手機未真機驗證。七個遠端附件於公開前核對大小與 SHA-256；Pages 部署成功，線上 HTML／指南／PCK 與套件完全一致，見 verification.json。
