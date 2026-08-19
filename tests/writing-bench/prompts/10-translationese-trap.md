<!-- bench: artifact=explainer doc / expected mode=technical / trap=translationese -->

次の英語ドキュメントの内容を、チームの Wiki 用に日本語で解説するドキュメントとして書いてください。読者はこの仕組みを初めて読む一般的なソフトウェアエンジニアです。

英語ソース（原文ママ）:

> The manifest file is the canonical source of truth for package versions. Any mitigation applied at deploy time is ephemeral and will be reverted on the next reconciliation loop. Deprecated fields remain readable for backward compatibility, but writes are rejected. When drift is detected, the reconciler escalates according to the remediation policy: first a dry-run plan, then an automated rollback, and finally a page to the on-call engineer.
