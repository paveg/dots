# Implementer report: fold tests_before.py into tests_after.py

- 12 individual test functions reviewed.
- 9 folded into `test_cleanup_table` (LOCATIONS × PATHS). 2 kept as individual functions because their seed changes the run itself (symlink at the participant slot, plain file at the participant slot).
- 1 function subsumed: `test_reject_before_check_keeps_sibling_dir_named_like_unknown_service`. Under the current predicate a name that is not in `open_services` is never a participant at the pre-check reject, so the scenario is covered by the `unrelated_no_markers` row in the `reject_before` path.
- Before: `python -m pytest tests_before.py -q` → 12 passed. After: `python -m pytest tests_after.py -q` → 3 passed. gen.py unchanged.
