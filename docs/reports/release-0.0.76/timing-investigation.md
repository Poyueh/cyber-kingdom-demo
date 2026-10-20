# 混合更新頻率的喘息倒數

成品內容檢查先在iOS、後在Android發現75次推進後仍有1至2刻度喘息；同一套件在其他起始相位會通過。診斷顯示起始workforce.elapsed為0.18333333333333、last_tick為6，2.5秒後仍剩2刻度。原因是以單步秒數換算的上限截斷了四捨五入邊界上合法的2刻度差。

新增公開Session行為測試：先推進11次1/60秒，再耗盡並推進75次1/30秒，原本兩項失敗。改用當次模擬的前後刻度限制歷史時間，兩項轉綠；舊引導存檔last_tick=0仍不能跳過新喘息。玩家規則與快照v24欄位不變。

保留initial-ios-audit.log、Android-content-audit.log為修正前證據；ck76-phase-red.log、ck76-phase-green.log及ck76-clock-green.log記錄重現與修正。最終發布以preflight.json記載的來源及重新匯出成品為準。
