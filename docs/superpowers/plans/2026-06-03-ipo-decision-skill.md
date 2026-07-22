# ipo-decision Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a new `ipo-decision` skill (sibling to `equity-decision`) that produces a JP pre-listing IPO subscription-decision memo where supply/demand is the protagonist.

**Architecture:** Mirror `equity-decision`: a `SKILL.md` router + `references/*.md` templates + reused `scripts/`. The only new code is a company-name-based lookup of 有価証券届出書 in `fetch_edinet.py` (pre-IPO names have no secCode, so the existing secCode path can't find them). Offering numerics (仮条件/吸収額/公募・売出/ロックアップ) come from the 届出書 PDF + web with fail-loud; comps come from `fetch_yahoo.py`.

**Tech Stack:** Python 3.11 (PEP 723 inline deps: requests, lxml), `uv run`, Markdown skill files, chezmoi-managed dotfiles.

**Spec:** `docs/superpowers/specs/2026-06-03-ipo-decision-skill-design.md` (commit 198f116)

**Key reuse decision:** `ipo-decision` does NOT copy scripts. It calls the existing `equity-decision/scripts/fetch_edinet.py` and `fetch_yahoo.py` by relative path (`../equity-decision/scripts/...`). One shared `fetch_edinet.py`, extended once.

---

## File Structure

```
dot_claude/skills/
  equity-decision/
    scripts/fetch_edinet.py          # MODIFY: add match_ipo_docs() + fetch_ipo() + --ipo flag
    scripts/test_fetch_edinet_ipo.py # CREATE: unit test for match_ipo_docs()
  ipo-decision/                      # CREATE (new skill)
    SKILL.md                         # router, workflow, fail-loud, disclaimer
    references/ipo-workflow.md       # 5-phase IPO memo template
    references/ipo-supply-demand-rubric.md  # 需給スコア thresholds
```

No duplication of fetchers. `ipo-decision/SKILL.md` references `../equity-decision/scripts/` and `../equity-decision/references/dcf-rubric.md` is NOT used (IPO uses its own rubric).

---

## Task 1: Add company-name IPO doc lookup to fetch_edinet.py

**Why:** Pre-IPO filers have no `secCode`; `fetch_docs()` filters by secCode and will never find a 有価証券届出書. Add a lookup that scans recent days for docTypeCode 030 (有価証券届出書) / 040 (訂正有価証券届出書) matching `filerName`.

**Files:**

- Modify: `dot_claude/skills/equity-decision/scripts/fetch_edinet.py`
- Test: `dot_claude/skills/equity-decision/scripts/test_fetch_edinet_ipo.py`

- [ ] **Step 1: Write the failing test**

Create `dot_claude/skills/equity-decision/scripts/test_fetch_edinet_ipo.py`:

```python
from fetch_edinet import match_ipo_docs


def test_match_filters_by_doctype_and_name_nfkc():
    results = [
        {"docTypeCode": "030", "filerName": "ＧＯ株式会社", "docID": "S1", "docDescription": "有価証券届出書"},
        {"docTypeCode": "120", "filerName": "GO株式会社", "docID": "S2", "docDescription": "有報"},
        {"docTypeCode": "040", "filerName": "GO株式会社", "docID": "S3", "docDescription": "訂正届出書"},
        {"docTypeCode": "030", "filerName": "無関係株式会社", "docID": "S4", "docDescription": "有価証券届出書"},
    ]
    out = match_ipo_docs(results, "GO")
    assert {d["docID"] for d in out} == {"S1", "S3"}  # 030/040 + name (full-width ＧＯ normalized); 120 and 無関係 excluded
    assert out[0]["url"].endswith("?type=2")  # PDF url


def test_match_empty_name_returns_all_ipo_types():
    results = [
        {"docTypeCode": "030", "filerName": "A社", "docID": "S1"},
        {"docTypeCode": "160", "filerName": "A社", "docID": "S2"},
    ]
    out = match_ipo_docs(results, "")
    assert {d["docID"] for d in out} == {"S1"}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd dot_claude/skills/equity-decision/scripts && uv run --with pytest --with requests --with lxml pytest test_fetch_edinet_ipo.py -v` Expected: FAIL with `ImportError: cannot import name 'match_ipo_docs'`

- [ ] **Step 3: Add the IPO constants and pure matcher**

In `fetch_edinet.py`, add `import unicodedata` to the imports block, and add after the `TARGET_TYPES` line (~line 116):

```python
IPO_TYPES = ("030", "040")  # 030=有価証券届出書, 040=訂正有価証券届出書
IPO_DAYS_BACK = 180  # 届出書 is typically filed ~1 month pre-listing; 訂正 later


def _norm(s: str) -> str:
    return unicodedata.normalize("NFKC", s or "").replace(" ", "").lower()


def match_ipo_docs(results: list, name_substring: str) -> list[dict]:
    needle = _norm(name_substring)
    out = []
    for item in results or []:
        if item.get("docTypeCode") not in IPO_TYPES:
            continue
        if needle and needle not in _norm(item.get("filerName", "")):
            continue
        out.append({
            "docTypeCode": item.get("docTypeCode"),
            "filerName": item.get("filerName", ""),
            "docDescription": item.get("docDescription", ""),
            "submitDateTime": item.get("submitDateTime", ""),
            "docID": item.get("docID", ""),
            "url": _doc_url(item.get("docID", "")),
        })
    return out
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd dot_claude/skills/equity-decision/scripts && uv run --with pytest --with requests --with lxml pytest test_fetch_edinet_ipo.py -v` Expected: PASS (2 passed)

- [ ] **Step 5: Add the network fetch_ipo() driver**

In `fetch_edinet.py`, add after `fetch_docs()`:

```python
def fetch_ipo(name_substring: str) -> dict:
    key = get_key()
    headers = {KEY_HEADER: key}
    seen: dict[str, dict] = {}
    for day in iter_days(date.today(), IPO_DAYS_BACK):
        params = {"date": day.isoformat(), "type": "2"}
        r = requests.get(API, headers=headers, params=params, timeout=15)
        r.raise_for_status()
        payload = r.json()
        meta = str(payload.get("metadata", {}).get("status", ""))
        if meta not in ("", "200"):
            raise ValueError(f"数字取得失敗: EDINET API rejected key — {payload}")
        for doc in match_ipo_docs(payload.get("results", []), name_substring):
            if doc["docID"] and doc["docID"] not in seen:
                seen[doc["docID"]] = doc
        sleep(0.3)
    if not seen:
        raise ValueError(
            f"数字取得失敗: no 有価証券届出書/訂正 found for filerName~={name_substring!r} "
            f"in last {IPO_DAYS_BACK} days. Paste the 目論見書/届出書 URL to proceed."
        )
    docs = sorted(seen.values(), key=lambda d: d["submitDateTime"])
    return {"query": name_substring, "docs": docs}
```

- [ ] **Step 6: Wire the `--ipo` flag in main()**

In `main()`, add this branch immediately after the `--sections` branch (after line ~224):

```python
    if len(args) == 2 and args[0] == "--ipo":
        try:
            data = fetch_ipo(args[1])
        except Exception as e:
            msg = f"{e}" if str(e).startswith("数字取得失敗") else f"数字取得失敗: {e}"
            print(msg, file=sys.stderr)
            return 1
        json.dump(data, sys.stdout, ensure_ascii=False)
        return 0
```

And update the usage string in main() to:

```python
            "usage: fetch_edinet.py <4-digit-secCode> | --ipo <filerName> | --sections <docID>",
```

- [ ] **Step 7: Update the module docstring**

In the top docstring Usage block, add the line:

```
    uv run fetch_edinet.py --ipo "<filerName>"     # locate pre-IPO 有価証券届出書 (030/040) by name
```

- [ ] **Step 8: Re-run unit tests + integration smoke**

Run: `cd dot_claude/skills/equity-decision/scripts && uv run --with pytest --with requests --with lxml pytest test_fetch_edinet_ipo.py -v` Expected: PASS (2 passed)

Integration (needs EDINET key; pick a company that recently filed a 届出書, e.g. a 2026 IPO): Run: `uv run fetch_edinet.py --ipo "GO"` Expected: JSON with `docs[]` containing docTypeCode 030/040 entries and `?type=2` URLs, OR a `数字取得失敗:` line if none in window (both are acceptable, non-crash, outcomes).

- [ ] **Step 9: Commit**

```bash
cd ~/.local/share/chezmoi
git add dot_claude/skills/equity-decision/scripts/fetch_edinet.py dot_claude/skills/equity-decision/scripts/test_fetch_edinet_ipo.py
git commit -m "feat(equity-decision): add --ipo filerName lookup for pre-IPO 届出書

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Create references/ipo-supply-demand-rubric.md

**Files:**

- Create: `dot_claude/skills/ipo-decision/references/ipo-supply-demand-rubric.md`

- [ ] **Step 1: Write the file with this exact content**

```markdown
# IPO Supply/Demand Rubric — thresholds and scoring

Used by Phase 3 of `ipo-workflow.md`. Produces a **directional** demand level (公募割れ警戒 / 中立 / プレミアム期待). Never output a predicted initial price.

## Factors and thresholds

| Factor                                | ポジ (初値プレミアム寄り)           | ネガ (公募割れ寄り)          |
| ------------------------------------- | ----------------------------------- | ---------------------------- |
| 吸収金額 (公開株数×公開価格上限 + OA) | 小型 < ¥100億                       | 大型 > ¥500億                |
| 売出 vs 公募                          | 公募中心（成長投資に充当）          | 売出中心（既存株主の換金）   |
| 親会社/VC/創業者の放出                | 残存保有大 + ロックアップ           | 全株売出・退出               |
| ロックアップ                          | 180日 or 解除価格条件(例 1.5倍)あり | 90日・条件なし・対象が薄い   |
| オーバーアロットメント/グリーンシュー | 標準的 (≤15%)                       | 過大                         |
| 公開価格の対類似企業バリュエーション  | ディスカウント設定                  | 類似比プレミアム             |
| 事業の成長性・黒字                    | 高成長 or 黒字 + 繰越欠損金の税盾   | 赤字拡大・資金使途が運転資金 |
| 地合い・同時期IPO数                   | 閑散期・単独                        | 大型IPO集中・地合い悪        |

## Scoring method (skill internal)

1. Score each factor ポジ(+1) / 中立(0) / ネガ(−1).
2. Weight the demand factors (吸収額・売出比率・親会社放出・ロックアップ) ×2; they dominate short-term IPO behavior.
3. Sum → demand level:
   - 合計 ≥ +2 → **プレミアム期待**
   - −1 〜 +1 → **中立**
   - ≤ −2 → **公募割れ警戒**
4. State which 2–3 factors drove the level. This is guidance, not a hard formula.

## Fail-loud

- If 仮条件/公開価格/吸収額 are not yet determined, mark them **未定** and give a provisional level with that caveat — do not invent the offer price.
- 吸収金額 must be shown as an explicit formula (公開株数 × 公開価格上限 + OA株数 × 価格), never a guessed lump sum.
- If a factor can't be sourced, mark it 数字取得失敗 and exclude it from the sum (note the exclusion).
```

- [ ] **Step 2: Commit**

```bash
cd ~/.local/share/chezmoi
git add dot_claude/skills/ipo-decision/references/ipo-supply-demand-rubric.md
git commit -m "feat(ipo-decision): add supply/demand rubric

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Create references/ipo-workflow.md

**Files:**

- Create: `dot_claude/skills/ipo-decision/references/ipo-workflow.md`

- [ ] **Step 1: Write the file with this exact content**

````markdown
> Sibling of `equity-decision/references/equity-workflow.md`, for JP pre-listing IPOs.

# IPO Subscription Memo — 5-Phase Template

Fill this exact template for a JP pre-listing IPO (抽選参加判断). Keep total output to 80–160 lines. If a number can't be sourced, write `数字取得失敗` — never invent it.

## Template

```markdown
# {会社名} ({コード}) — IPO抽選参加メモ

_Generated: {YYYY-MM-DD} | 上場予定日 {date} | 市場 {グロース/スタンダード/プライム}_ _仮条件 {¥lo–¥hi or 未定} | 想定発行価格 {¥ or 未定}_

> リサーチ要約・投資助言ではない。最終判断は自己責任。目論見書で要検証。

## 1. 事業

{2–3行。何で稼ぐか、ビジネスモデル、成長ステージ（黒字/赤字・成長率）}

## 2. 業績（目論見書）

| 期        | 売上 | 営業益 | 営業益率 | 純利益 | 出典     |
| --------- | ---- | ------ | -------- | ------ | -------- |
| FY-2      | …    | …      | …        | …      | 目論見書 |
| FY-1      | …    | …      | …        | …      | 目論見書 |
| FY (直近) | …    | …      | …        | …      | 目論見書 |

- 黒字化: {済/未} ／ 繰越欠損金(税盾): {¥ or なし} ／ 自己資本比率: {%} ／ ROE: {%}

## 3. 需給（最重要・rubric適用）

- 公開規模: 公募 {n}株 + 売出 {n}株 + OA {n}株 → **吸収金額 = (公募+売出+OA)株 × 公開価格上限{¥} = ¥{X}億**（式を明示）
- 売出/公募比率: {売出 X% / 公募 Y%} → {既存換金主体 or 成長投資}
- 親会社/VC/創業者: 放出 {規模}・残存保有 {%}・{全株売出 or 残す}
- ロックアップ: {期間日}・解除価格条件 {あり(×1.5)/なし}・対象 {%}
- 想定バリュエーション: 公開価格ベース PER {x} / PSR {x} vs 類似上場企業 {社}（fetch_yahoo）
- **需給レベル: {公募割れ警戒 / 中立 / プレミアム期待}**（駆動factor 2–3個を明記）

## 4. リスク

- 📚 事業等のリスク（目論見書）: {要点}
- 🧾 監査・継続性: {監査法人 / GC注記有無}
- 🎯 依存: {親会社/特定顧客/規制}
- ⏳ ロックアップ解除後: {解除日と想定需給悪化}

## 5. 判断

**Thesis（参加するなら）**:

1. {需給/バリュ/成長に紐づく根拠}
2. {根拠}

**Invalidation（崩れる条件）**:

1. {testable: 仮条件が想定上限超で割高 / 大型化で需給悪化 等}
2. {testable}

**判断**: {積極参加 / 小ロット参加 / 初値売り前提で参加 / 見送り} **ロット戦略**: {抽選申込の単位・初値後の方針} **初値後にホールドするなら条件**: {…}

---

深掘りする？

1. 需給スコアを factor 単位で再計算
2. ロックアップ解除スケジュールと解除後の需給インパクト
3. 類似IPOの初値騰落率の横並び（方向感の補強・株価予想はしない）
4. 類似上場企業バリュエーション横並び
5. 上場後の KPI モニタを 5 つに絞り込む
```

## Filling rules

- 需給が主役。Verdict は Phase 3 の需給レベル × Phase 2 の業績 × 公開価格バリュエーションで決める。
- 初値の **予想株価は出さない**。方向感（公募割れ警戒/中立/プレミアム期待）まで。
- 吸収金額は式を見せて計算。仮条件未定なら「未定」と書き、確定後に再計算。
- Verdict マッピング:
  - **積極参加**: 需給=プレミアム期待 + 公開価格が類似比割安 + 黒字/高成長
  - **小ロット参加**: 中立だが業績良 or 需給良だが割高、の片肺
  - **初値売り前提で参加**: プレミアム期待だが上場後ファンダに不安（ロックアップ解除/赤字）
  - **見送り**: 公募割れ警戒 + 割高、または重大リスク（GC・全株売出の大型）
````

- [ ] **Step 2: Commit**

```bash
cd ~/.local/share/chezmoi
git add dot_claude/skills/ipo-decision/references/ipo-workflow.md
git commit -m "feat(ipo-decision): add 5-phase IPO memo template

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Create SKILL.md

**Files:**

- Create: `dot_claude/skills/ipo-decision/SKILL.md`

- [ ] **Step 1: Write the file with this exact content**

```markdown
---
name: ipo-decision
description: |
  Generate an IPO subscription-decision memo (抽選参加判断) for a Japanese pre-listing IPO.
  Walks 5 phases — business, fundamentals, supply/demand, risks, verdict — where supply/demand is the protagonist.
  Use when (1) the user asks "このIPO参加すべき？", (2) names an upcoming JP IPO / its ticker, (3) pastes a 目論見書 / 有価証券届出書 URL. v1 = JP pre-listing only (US S-1 / just-listed / pre-IPO unlisted are out of scope).
argument-hint: <会社名 or コード or 目論見書URL> [extra context]
---

# `ipo-decision` skill

Produces a JP pre-listing IPO subscription-decision memo. Sibling of `equity-decision`; for IPOs the analysis centers on **supply/demand (需給)**, not DCF.

> ⚠️ Not investment advice. Research summary from the 目論見書 and public data. Verify before subscribing.

## Scope (v1)

JP pre-listing IPO, subscription decision only. Out of scope: US/S-1, post-listing (初値後), pre-IPO unlisted/secondary. If asked for those, say so and offer the closest path.

## Inputs

| Form     | Example             | Routing                                         |
| -------- | ------------------- | ----------------------------------------------- |
| 会社名   | `GO` `キオクシア`   | `fetch_edinet.py --ipo "<name>"` → 届出書 docID |
| 新コード | `581A`              | use as name hint; confirm filer via `--ipo`     |
| URL      | 目論見書/届出書 URL | read it directly; skip the lookup               |

## Workflow

1. Locate the filing: `uv run ../equity-decision/scripts/fetch_edinet.py --ipo "<filerName>"` → pick the latest 030 (有価証券届出書) and any 040 (訂正). Open the `?type=2` PDF URL to read 業績・公募/売出株数・大株主・手取金の使途. If lookup fails, ask the user for the 目論見書 URL (do not abort).
2. Risk/audit text: `uv run ../equity-decision/scripts/fetch_edinet.py --sections <docID>` (works on the 届出書 XBRL too).
3. Offering terms not in the 届出書 (仮条件/公開価格/吸収額/ロックアップ詳細/OA): source from web with citation; if unavailable, write `数字取得失敗` and request the 目論見書.
4. Comps: `uv run ../equity-decision/scripts/fetch_yahoo.py <類似上場コード>` for relative valuation of the offer price.
5. Read `references/ipo-workflow.md`; fill the 5-phase template.
6. Apply `references/ipo-supply-demand-rubric.md` for the demand level.
7. Emit the memo, then the deep-dive menu.

## Fail-loud rules

- No hallucinated numbers. Unsourceable → `数字取得失敗`.
- 仮条件/公開価格 未確定 → write **未定**; recompute once fixed. Never invent the price.
- **No predicted initial price.** Direction only (公募割れ警戒 / 中立 / プレミアム期待).
- 吸収金額 = (公募+売出+OA)株 × 公開価格上限 — show the formula, never a guessed lump sum.
- Inherit the Yahoo distortion correction from `equity-decision/SKILL.md` when using comps (prefer IR actuals over Yahoo `operatingIncome`; mark adopted vs Yahoo).

## Disclaimer

Research summaries, not investment advice. Verify against the 目論見書 before subscribing.
```

- [ ] **Step 2: Verify the skill is discoverable (frontmatter parses)**

Run: `head -8 dot_claude/skills/ipo-decision/SKILL.md` Expected: valid YAML frontmatter with `name: ipo-decision` and a `description:`.

- [ ] **Step 3: Commit**

```bash
cd ~/.local/share/chezmoi
git add dot_claude/skills/ipo-decision/SKILL.md
git commit -m "feat(ipo-decision): add SKILL.md router

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: Regression verification (pattern + fail-loud)

**Why:** No automated harness covers the markdown skill behavior. Verify the skill reproduces the proven ad-hoc pattern (581A GO) and honors fail-loud.

**Files:** none (verification only)

- [ ] **Step 1: Apply to a live target, then sanity-check the output against the rubric**

Do NOT chezmoi apply yet (Task 6). Test against source by reading files directly. Manually walk the workflow on a real upcoming JP IPO (or re-derive 581A GO from `~/repos/github.com/paveg/stock/research/581A_go/`):

- Confirm `fetch_edinet.py --ipo` returns the 届出書 (or fails loudly with the URL request).
- Confirm the memo: (a) shows 吸収金額 as a formula, (b) gives a demand level with named drivers, (c) contains NO predicted initial price, (d) marks any missing offer term as 未定/数字取得失敗.

- [ ] **Step 2: Record the check**

Confirm in the session (no commit): each of the 4 fail-loud assertions above holds on the test memo. If any fails, fix the relevant reference/SKILL file and re-verify.

---

## Task 6: Bundle chezmoi apply (user-gated) + close out

**Why:** The earlier `equity-decision` changes (order-execution.md + SKILL.md edits) were deliberately left unapplied to bundle with this skill. Apply requires explicit user confirmation (chezmoi rule).

**Files:** none (deployment)

- [ ] **Step 1: Show the full diff/status**

```bash
cd ~/.local/share/chezmoi
git status --short
chezmoi status ~/.claude/skills
```

Expected: modified `equity-decision/SKILL.md`, new `equity-decision/references/order-execution.md`, new `ipo-decision/**`, modified `fetch_edinet.py`.

- [ ] **Step 2: Ask the user to confirm `chezmoi apply`**

Per `~/.claude/rules/chezmoi.md`, confirm before apply. Present what will deploy to `~/.claude/skills/`.

- [ ] **Step 3: Apply after confirmation**

```bash
cd ~/.local/share/chezmoi && chezmoi apply ~/.claude/skills
```

- [ ] **Step 4: Verify deployment**

Run: `ls ~/.claude/skills/ipo-decision && head -6 ~/.claude/skills/ipo-decision/SKILL.md` Expected: files present; frontmatter shows `name: ipo-decision`.

- [ ] **Step 5: Commit any remaining uncommitted skill files**

```bash
cd ~/.local/share/chezmoi
git add dot_claude/skills/equity-decision/SKILL.md dot_claude/skills/equity-decision/references/order-execution.md
git commit -m "feat(equity-decision): add order-execution reference + Yahoo distortion fail-loud

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Self-Review

**Spec coverage:**

- JP pre-IPO scope → Task 4 SKILL.md scope section ✓
- Hybrid data (EDINET 届出書 + web + comps) → Task 1 (`--ipo`), Task 4 workflow steps 1–4 ✓
- Directional 初値 only → Task 2 rubric + Task 3 template + Task 4 fail-loud ✓
- 5-phase template → Task 3 ✓
- Supply/demand rubric → Task 2 ✓
- EDINET 届出書 doctype (030/040) → Task 1 (resolved the secCode-miss via filerName lookup; `--sections` reused for risk/audit) ✓
- 吸収額 formula / 仮条件 未定 / no predicted price fail-loud → Tasks 2,3,4 ✓
- Bundle chezmoi apply with order-execution changes → Task 6 ✓

**Placeholder scan:** No TBD/TODO. All file contents given verbatim. The one runtime unknown (which live IPO to test) is inherent to Task 5 and bounded by the 581A fallback.

**Type/name consistency:** `match_ipo_docs`, `fetch_ipo`, `IPO_TYPES`, `IPO_DAYS_BACK`, `_norm` used consistently across Task 1 steps and the test. `--ipo` flag name consistent in fetch_edinet.py, test integration step, and SKILL.md workflow. Reuse path `../equity-decision/scripts/` consistent in SKILL.md.

```

```
