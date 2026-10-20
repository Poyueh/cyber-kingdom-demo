# 防禦與騎乘美術

以內建 image_gen 製作，三份完整提示詞在 prompts.json；mounted.png、mounted-unarmed.png、guard.png 為原稿。正式素材：art/characters/mounted-v002 及 sword-guard-v001。tools/prepare_defense_mount.py 只做統一比例最近鄰像素化、透明度量化、等格裁切與足底定位，不繪製身體或合成腿部。每個完整循環固定比例，避免忽胖忽瘦。
