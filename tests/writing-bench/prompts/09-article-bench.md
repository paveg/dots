<!-- bench: artifact=tech article / expected mode=article / audience=engineer -->
Zenn 向けに、シェル起動時間を計測して改善した話を技術記事として書いてください。

素材ノート:
- 計測コマンド: `hyperfine 'zsh -i -c exit'`（10 回平均）— 実測
- 改善前: 412ms。内訳を `zprof` で見ると compinit 310ms、nvm 初期化 64ms — 実測
- 対策 1: compinit を 24 時間キャッシュ（`compinit -C` 分岐）→ 118ms — 実測
- 対策 2: nvm を遅延読み込み化 → 71ms — 実測
- 3 台の Mac（M1/M2/M3）で再現し、いずれも 70ms 台に収束 — 実測
- やらなかったこと: zinit などプラグインマネージャ移行。依存を増やすほどの残り伸び代がなかった
