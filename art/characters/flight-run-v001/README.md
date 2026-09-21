# 騰空跑姿 v001

內建 imagegen 依 stride-v001/armed.png 的角色外觀產生新的八格空手跑姿。保留銀甲、青色目鏡、金色機械雙腿與紅披風；以蹬地、抬起後腳、騰空、落地取代低姿貼地步態。生成原圖保留於 sources/generated.png，提示規格見 sources/prompt.txt。

玩家既有授權的本機 Python 流程負責 alpha 閾值、最近鄰縮小、切格、接地校正，並隨手部位置加上向後拖的劍。衝刺版以上身前傾剪切產生。這是加工後的遊戲圖，並非宣稱生成原圖可直接當作精確動畫資料。

四張圖皆 512×192、4 欄×2 列，每格 128×96。一般跑步／衝刺分別 20／28 fps，騰空格腳底比接地格高 4／7 像素。sources/.gdignore 排除原圖與預覽；遊戲預載四張 atlas，不在每幀建立圖片。

以 Pillow、NumPy 執行 sources/process.py 可重現全部 PNG 與 GIF。持劍／空手在實際 frontier 場景擷取了跑步與衝刺序列；美感和 iPhone 手感仍以玩家回饋持續調整。
