# v0.0.43 日月與天空融合驗收

比較 `dawn`、`noon`、`sunset`、`moonrise`、`midnight`、`predawn` 的 before／after 截圖：原本實色圓盤改為帶天空色的分層盤面、窄幅像素柔邊與圈外抖色光暈，晨光和晚霞分開調色。`planet-0.png` 至 `planet-6.png` 是實際七星球巡覽；保留背景原畫與前景遮擋，不宣稱重畫背景固定亮點。

原生 GPU 像素驗證 10 項通過：三比例日月 6 項，日／月圈外光暈 2 項，日轉夜／夜轉日端點連續性 2 項。960×300 的日／月輪廓為 28×28／18×18，960×700 為 64×64／40×40，1500×400 為 36×36／24×24；兩交界最大色差均為 0。量測渲染結果，不以公式推算代替畫面。

同來源 6249841 的實際 macOS PCK 重跑 10 項皆通過，另保存六個完整遊戲時點 `v43-*-packaged.png`。呈現直接讀取既有時鐘，不新增累積時間或存檔欄位。完整回歸與發行結果另見 release-0.0.43。

native-sky-proof.gd 使用原生 Godot --script 執行，也可搭配成品 --main-pack。native-world-proof.gd 依賴開發用 tests 基底；cyber43-packaged-world.gd 為相同場景的獨立版本。驗收不建立玩家旅程；Windows 與手機尚未真機驗收。
