# IPO Supply/Demand Rubric — thresholds and scoring

Used by Phase 3 of `ipo-workflow.md`. Produces a **directional** demand level
(公募割れ警戒 / 中立 / プレミアム期待). Never output a predicted initial price.

## Factors and thresholds

| Factor | ポジ (初値プレミアム寄り) | ネガ (公募割れ寄り) |
|---|---|---|
| 吸収金額 (公開株数×公開価格上限 + OA) | 小型 < ¥100億 | 大型 > ¥500億 |
| 売出 vs 公募 | 公募中心（成長投資に充当） | 売出中心（既存株主の換金） |
| 親会社/VC/創業者の放出 | 残存保有大 + ロックアップ | 全株売出・退出 |
| ロックアップ | 180日 or 解除価格条件(例 1.5倍)あり | 90日・条件なし・対象が薄い |
| オーバーアロットメント/グリーンシュー | 標準的 (≤15%) | 過大 |
| 公開価格の対類似企業バリュエーション | ディスカウント設定 | 類似比プレミアム |
| 事業の成長性・黒字 | 高成長 or 黒字 + 繰越欠損金の税盾 | 赤字拡大・資金使途が運転資金 |
| 地合い・同時期IPO数 | 閑散期・単独 | 大型IPO集中・地合い悪 |

## Scoring method (skill internal)

1. Score each factor ポジ(+1) / 中立(0) / ネガ(−1).
2. Weight the demand factors (吸収額・売出比率・親会社放出・ロックアップ) ×2;
   they dominate short-term IPO behavior.
3. Sum → demand level:
   - 合計 ≥ +2 → **プレミアム期待**
   - −1 〜 +1 → **中立**
   - ≤ −2 → **公募割れ警戒**
4. State which 2–3 factors drove the level. This is guidance, not a hard formula.

## Fail-loud

- If 仮条件/公開価格/吸収額 are not yet determined, mark them **未定** and give a
  provisional level with that caveat — do not invent the offer price.
- 吸収金額 must be shown as an explicit formula (公開株数 × 公開価格上限 + OA株数 × 価格),
  never a guessed lump sum.
- If a factor can't be sourced, mark it 数字取得失敗 and exclude it from the sum
  (note the exclusion).
