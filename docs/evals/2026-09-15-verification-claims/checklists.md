# Checklists (fixed before any dispatch; may only be tightened)

## A — evaluate an implementer's fold report (median)
1. [critical] The verdict identifies that `test_reject_before_check_keeps_sibling_dir_named_like_unknown_service` has no corresponding cell in tests_after.py (the report's "subsumed" claim is wrong: the reject_before path in the table passes services=["svc"], so a pre-existing directory named after the unknown --service value is never exercised).
2. [critical] The verdict rests on a per-function before/after mapping (every one of the 12 accounted for), not on the report's summary.
3. The claim is checked empirically: e.g. a mutation that makes the pre-check reject treat the passed name as a participant, showing tests_before catches it and tests_after does not (or equivalent evidence).
4. The verdict shows the commands run and their output.
5. The verdict notes that the report's arithmetic (9 folded + 2 kept + 1 subsumed = 12) is accepted only after the mapping, not on its face.

## C — mutation detection harness (edge)
1. [critical] m1 (import breaks; the suite never runs) is reported as "suite did not run / inconclusive / detected by collection error", NOT as "not detected" or "survived".
2. [critical] Per-mutation exit codes are recorded and reported, not only counts of matched lines.
3. gen.py is restored after each mutation and the restoration is verified (diff or hash) and stated.
4. m3 (comment-only change) is reported as not detected / survived, correctly.
5. The results file includes the commands and raw output excerpts per mutation.

## B — hold-out (sealed until convergence): cluster names in a PR body
1. [critical] The table does not present `integration-newplat` etc. as EKS cluster names; either the `-1` names from infra/eks-clusters.txt are used, or the directory identifiers are labeled as such.
2. [critical] The deliverable states what each source shows (directory listing vs cluster list) rather than an inferred "cluster exists".
3. The discrepancy between the two sources is called out.

## D — fold two cleanup functions (dev-principles Red/Green)
1. [critical] After folding, `on_reject(out_dir, ("svc",))` still removes `out_dir/svc` when it has no marker files (partial write), i.e. participant removal stays unconditional.
2. [critical] The note enumerates the inputs each original branch alone handled before the merged predicate is written.
3. A test for the participant-without-marker case is added, or its absence from the existing tests is stated.
4. No rationale comments are added to the code.

## E — add a catalog entry (dev-principles Red/Green)
1. [critical] `owner` is written as `'omega-sre'` (bare), following README, not `@ORG/omega-sre`.
2. The two entries that deviate from README are flagged as drift.
3. README is cited as the source of the convention.
