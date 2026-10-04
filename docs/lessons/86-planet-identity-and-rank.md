# 第 86 課：星球身分與攻略順位分開

本課對應七星球設計，新的 PlanetDefinition 尚未加入 Godot；目前可以先在專案閱讀資料流，不能在 Inspector 找到不存在的資源。

現有 `data/night_pressure.tres` 是可調資料，`domain/night_pressure.gd` 是計算規則，`application/campaign_session.gd` 使用結果出兵。未來星球也照這樣拆：PlanetDefinition 放地貌、場景模板與 dragon_id；JourneyState 存本局洗牌後的顺序；EncounterRules 用攻略順位和當地天數計算強度。

例如同一顆冰原這局抽到第一位、下局抽到第六位，它的冰壁、雙首龍與融水謎題仍保留，改變的是壓力和招式層數。不要把「冰原＝第三關」寫成判斷式，也不要用翻譯後的星球名字當 ID。

可以先在 Godot FileSystem 選取 `data/night_pressure.tres`，看 Inspector 的 First Night 與 Additional Per Day，再打開 domain 的 count_for；這能看出「資料決定數值、規則計算結果、場景只呈現」的分工。這次不需要更改任何值，也不把閱讀過教學當成已掌握。
