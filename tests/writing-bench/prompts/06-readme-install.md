<!-- bench: artifact=README section / expected mode=technical -->

OSS ツール imgpack（画像を一括で WebP 化する CLI）の README に「インストールと初回実行」セクションを追記してください。読者は imgpack を初めて見る一般的なソフトウェアエンジニアです。

事実:

- インストール方法は 3 通り: Homebrew（`brew install imgpack`）、Cargo（`cargo install imgpack`）、GitHub Releases のバイナリ
- macOS で Releases バイナリを使う場合だけ、初回に Gatekeeper の隔離解除（`xattr -d com.apple.quarantine ./imgpack`）が要る
- 初回実行: `imgpack init` が設定ファイル `~/.config/imgpack/config.toml` を生成する
- 動作確認: `imgpack convert sample.png` が `sample.webp` を出力し、標準出力に圧縮率を表示すれば成功
- 対応 OS は macOS と Linux。Windows は WSL のみサポート
