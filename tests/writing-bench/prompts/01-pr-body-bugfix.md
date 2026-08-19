<!-- bench: artifact=PR body / expected mode=technical / budget=pr -->

以下の変更内容で GitHub の PR 本文を書いてください。

変更の事実:

- zsh の起動が体感で遅くなっていた。計測すると平均 412ms、うち 310ms が `compinit` の毎回実行によるもの
- `.zcompdump` が 24 時間以内なら `compinit -C` でキャッシュを使うよう分岐を追加（`home/private_dot_zshrc.tmpl` の 1 箇所、8 行の変更）
- 変更後の計測は平均 118ms（10 回実行の平均、`hyperfine 'zsh -i -c exit'`）
- 副作用: 新しい補完定義の反映が最大 24 時間遅れる。すぐ反映したいときは `rm ~/.zcompdump` で強制再生成できる
- テスト: `just test` 通過
