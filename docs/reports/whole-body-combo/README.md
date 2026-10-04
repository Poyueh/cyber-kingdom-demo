# 全身連斬驗證

## 根因與修正

v003 的來源圖固定骨盆和雙腳位置，肩胸形變很少，揮劍主要靠手臂。執行期已正確切換整個角色圖格；問題在原稿的動作設計，不是只有手臂節點播放。

v004 重新生成三段原地與踏斬各 8 格，共 48 個完整姿勢。以轉肩、沉腰、承重、回挑與蹬地帶動劍；保留紅披風和青色義肢。每段固定比例，原生人物約 60px 高，靴底基準代替骨盆固定；沒有拆腿、拉伸或程序變形。修改圖格權重，不改傷害、攻擊範圍、消耗、核心連斬或存檔規則。

來源、逐圖提示詞與掛點見 art/concepts/knight-combo-v004/；重建器 tools/prepare_whole_body_combo.py。主場景與前導使用相同 appearance 資源。每個姿勢的完整邊界與掛點記錄於 atlas-checks.json。

## 原生驗收

Godot 4.7.2 Compatibility，macOS M3 Pro，960×540。tools/review_sword_feedback.gd 使用真正 J／A／D 輸入，載入正式 frontier 場景，不存取玩家存檔。使用 --module 錄下部件隨姿勢，另以 --body-only 移除刀光觀察純角色姿勢。這是檢查姿勢的方法，不是正式遊戲設定。

native-contact.webp／native-advancing.webp／native-left.webp／native-empty.webp 為實際畫面裁切、最近鄰二倍放大；每段 84 個 60Hz 狀態，取雙幀以 30fps 播放，未放慢美化。native-contact-sheet.png 為各刀蓄力／出刀／收招代表格。指南使用同一個 contact 錄影。

native-evidence.json：四段皆播放完整三刀；原地、向左、揮空世界 X 位移皆 0。踏斬片段總位移 128.25（含連斬完成後持續移動，不能當成單刀推進距離）。有命中才停頓／鏡頭回饋，部件仍貼在背部。目視確認前腿承重、回挑抬身與第三刀壓腰均可辨識。

完整 tools/check.sh 通過：核心 2,485 斷言、連斬場景 26 項與命中回饋 18 項皆零失敗，無 SCRIPT ERROR／ERROR。完整檢查結果及發佈驗證記在 docs/STATUS.md 與 release-0.0.19 報告。未在 Windows／手機真機遊玩，動作美感仍須玩家試玩回饋。
