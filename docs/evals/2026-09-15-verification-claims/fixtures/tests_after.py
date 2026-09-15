import sys, tempfile
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import gen

def _seed_markers(d):
    d.mkdir(parents=True); [ (d / m).write_text("stale") for m in gen.MARKERS ]

# (label, seed(out_dir), survives(out_dir), expected per path)
LOCATIONS = [
    ("nonparticipant_markers", lambda o: _seed_markers(o / "other"), lambda o: (o / "other").exists(),
     {"success": False, "reject_before": False}),
    ("unrelated_no_markers", lambda o: ((o / "notes").mkdir(), (o / "notes" / "memo.md").write_text("k")), lambda o: (o / "notes" / "memo.md").is_file(),
     {"success": True, "reject_before": True, "reject_after": True}),
    ("nonparticipant_overlays_only", lambda o: (o / "half" / "overlays").mkdir(parents=True), lambda o: (o / "half").exists(),
     {"success": True, "reject_before": True, "reject_after": True}),
    ("symlink_child", lambda o: (_seed_markers(o.parent / "outside"), (o / "ghost").symlink_to(o.parent / "outside")), lambda o: (o / "ghost").is_symlink(),
     {"success": True, "reject_before": True, "reject_after": True}),
]
PATHS = [
    ("success", ["svc"], ["svc"], (), 0),
    ("reject_before", ["svc"], [], (), 1),
    ("reject_after", ["svc", "other"], ["svc", "other"], ("other",), 1),
]

def test_cleanup_table():
    for path, services, open_services, fail_for, expected_rc in PATHS:
        with tempfile.TemporaryDirectory() as t:
            out = Path(t) / "out"; out.mkdir(); _seed_markers(out / "svc")
            applied = []
            for label, seed, survives, exp in LOCATIONS:
                if path in exp:
                    seed(out); applied.append((label, survives, exp[path]))
            rc = gen.main(out, services, open_services, fail_write_for=fail_for)
            assert rc == expected_rc, (path, rc)
            if expected_rc == 0:
                assert (out / "svc" / "contract.json").read_text() == "fresh", path
            else:
                assert (out / "rejection.json").is_file(), path
                assert not (out / "svc").exists(), path
                if path == "reject_after":
                    assert not (out / "other").exists(), path
            for label, survives, exp in applied:
                assert survives(out) == exp, (path, label)

def test_symlink_participant_is_rejected_without_writing_outside():
    with tempfile.TemporaryDirectory() as t:
        out = Path(t) / "out"; out.mkdir(); outside = Path(t) / "outside"; outside.mkdir()
        (out / "svc").symlink_to(outside)
        assert gen.main(out, ["svc"], ["svc"]) == 1
        assert not any(outside.iterdir()) and (out / "svc").is_symlink()

def test_plain_file_at_participant_slot_is_rejected():
    with tempfile.TemporaryDirectory() as t:
        out = Path(t); (out / "svc").write_text("not a dir")
        assert gen.main(out, ["svc"], ["svc"]) == 1
        assert (out / "rejection.json").is_file()
