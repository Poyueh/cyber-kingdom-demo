# 第 116 課：Resource、規格與成品要說同一件事

在 Godot 的 FileSystem 選 `data/planets/forest.tres`，Inspector 裡的 `Day Seconds` 是森林「遠征」旅程的白天基準，目前 180 秒。企劃網頁的日夜表也要寫 180。拓荒與圍城是在新旅程建立時加減這個基準，舊存檔保存的設定不會被重新計算。

小練習：先只看 Inspector 與企劃表，找到 `Night First` 的 3。若將來想改成 4，除了改 Resource，也要更新 `docs/game-spec/content.json` 的數值、文件修訂與審訂摘要，再記錄審訂。未同步時，專案檢查會擋住發佈，提醒你處理規格。

網站內容從 JSON 生成；不要直接改產出的 HTML，下一次建置就會被覆蓋。這和 Godot 使用 Resource 當數值來源相同：清楚決定誰是來源，避免三個地方各有一套答案。

尚無實際操作回饋，本課不代表你已掌握 Resource 或發行流程。
