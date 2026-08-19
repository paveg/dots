<!-- bench: artifact=design doc / expected mode=technical / diagram trigger=state -->
社内向けの設計ドキュメントを docs/design/cache-layer.md として書いてください。

決まっていること:
- 商品検索 API のレスポンス改善のため Redis のキャッシュ層を導入する。現状 p95 が 820ms、目標は 200ms 以下
- キャッシュエントリは「未取得 → 取得中 → 有効 → 失効」の 4 状態を持つ。取得中の同時リクエストは 1 本に合流させる（thundering herd 対策）
- TTL は 300 秒。商品情報の更新イベントを受けたら該当キーを即時失効させる
- 検討して捨てた案: (a) アプリ内メモリキャッシュ — 複数レプリカ間で失効が同期できない、(b) CDN キャッシュ — 認証付きレスポンスのため不可
- 未決事項: Redis のクラスタ構成は SRE チームと調整中
