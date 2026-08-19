<!-- bench: artifact=PR body / expected mode=technical / budget=pr / diagram trigger=sequence -->
以下の機能追加の PR 本文を書いてください。

変更の事実:
- CLI からの画像アップロードに事前署名 URL 方式を追加した
- 流れ: CLI が API サーバへアップロード要求 → API サーバが S3 の事前署名 URL を発行して CLI に返す → CLI が S3 に直接 PUT → 完了後 CLI が API サーバへ完了通知 → API サーバがメタデータを DB に記録
- これまでは CLI → API サーバ → S3 の中継方式で、100MB 超のファイルで API サーバのメモリが逼迫していた
- 事前署名 URL の有効期限は 15 分。期限切れは CLI 側で再要求する
- フラグ `--legacy-upload` で旧方式にフォールバックできる（2 リリース後に削除予定）
