<!-- bench: artifact=design doc / expected mode=technical / diagram trigger=sequence / temptation=scope mixing -->

次のメモから、セッション管理変更の設計ドキュメントを docs/design/session-revocation.md として書いてください。メモには今回のスコープ外の話も混ざっています。

メモ:

- 今のセッションはステートレス JWT のみで、ログアウトしても有効期限まで使えてしまう。監査指摘 SEC-112
- 対応: JWT はそのまま、Redis に失効リスト（jti をキー、TTL はトークン残存時間）を置く。検証フローは「署名検証 → 失効リスト照合 → 通過」
- ログアウト時: クライアント → 認証 API → Redis へ jti 登録 → 204 を返す
- 失効リスト照合が Redis 障害で失敗した場合はフェイルオープン（許可）とする。SEC-112 の指摘範囲はログアウト無効化のみで、可用性を優先する判断
- ついでにパスワードポリシーも見直したい（別チケット SEC-118 になる予定）
- あと将来的にはセッション一覧画面もほしい
