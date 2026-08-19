<!-- bench: artifact=PR body / expected mode=technical / budget=pr / diagram trigger=before-after -->

以下のリファクタリングの PR 本文を書いてください。

変更の事実:

- これまで通知処理は `NotificationService` 1 クラスに集約されていて、メール・Slack・Webhook の分岐が 1 つの `send()` メソッド内の if 連鎖だった（420 行）
- 今回 `Notifier` インターフェースを切り、`MailNotifier` / `SlackNotifier` / `WebhookNotifier` の 3 実装に分割。`NotificationService` はルーティングだけを持つ 60 行になった
- 分割に伴い、リトライ制御は各 Notifier から `RetryPolicy` へ外出しした
- 挙動は変えていない。既存の統合テスト 47 件はすべて通過し、追加で各 Notifier の単体テストを 12 件書いた
- 移行は一括置換ではなく、旧 `send()` を 1 リリースの間 deprecated として残す
