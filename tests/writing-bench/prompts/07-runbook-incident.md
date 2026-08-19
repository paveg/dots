<!-- bench: artifact=runbook / expected mode=technical / diagram trigger=branching procedure -->
決済ゲートウェイのタイムアウト急増時の一次対応手順書を書いてください。オンコール初参加のメンバーが深夜に一人で読む前提です。

事実:
- アラート: `payment-gateway p99 > 5s` が 5 分継続で PagerDuty 発報
- 手順: (1) ダッシュボード payment-overview で外部 PSP のステータスを確認 (2) PSP 側障害なら status ページを購読してフラグ `psp_fallback` を ON にし、二次 PSP へ切替 (3) PSP 正常なら直近デプロイを確認 (4) 30 分以内のデプロイがあれば即ロールバック (5) デプロイがなければ DB コネクションプールを確認し、枯渇時はレプリカを 1 台追加 (6) どれでも解消しなければ二次オンコールへエスカレーション
- 切替フラグは管理画面 Feature Flags から。反映まで最大 60 秒
- ロールバックは `deployctl rollback payment-gateway` 一発。実行後 p99 が 1s を下回れば収束と判断
