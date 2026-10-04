# 騎士整套重繪 v003

模式：內建 image_gen.imagegen，未使用外部付費 API。16 張採用原稿、共 160 姿勢；各圖完整提示詞保留在 `sources/*.png.prompt.txt`，需求在 `brief.md`。不採用的生成稿留在工具原始輸出位置，不進專案。

由 `tools/prepare_knight_actions_v003.py` 做已授權的本機透明輪廓清理、連通區切格、同段固定倍率最近鄰縮圖、原生圖集與掛點產出。跑步、衝刺、慢走與踏斬都是分別生成的完整身體，沒有仿射變形或拆腿重組。

原稿只供維護，`.gdignore` 與匯出流程排除原稿；正式使用 `art/characters/blacksteel-v003/`，整套原生 PNG 約 1 MB。即使原稿解析度高，遊戲只讀原生像素。預覽在 `docs/reports/knight-v003/`。
