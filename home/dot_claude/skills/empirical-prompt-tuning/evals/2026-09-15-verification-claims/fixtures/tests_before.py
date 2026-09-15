import os, sys, tempfile
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import gen

def _seed_markers(d):
    d.mkdir(parents=True); [ (d / m).write_text("stale") for m in gen.MARKERS ]

def _run(out, services, open_services, **kw):
    return gen.main(out, services, open_services, **kw)

def test_success_rewrites_participant():
    with tempfile.TemporaryDirectory() as t:
        out = Path(t); _seed_markers(out / "svc")
        assert _run(out, ["svc"], ["svc"]) == 0
        assert (out / "svc" / "contract.json").read_text() == "fresh"

def test_success_removes_stale_nonparticipant_with_markers():
    with tempfile.TemporaryDirectory() as t:
        out = Path(t); _seed_markers(out / "other")
        assert _run(out, ["svc"], ["svc"]) == 0
        assert not (out / "other").exists()

def test_success_keeps_unrelated_dir_without_markers():
    with tempfile.TemporaryDirectory() as t:
        out = Path(t); (out / "notes").mkdir(); (out / "notes" / "memo.md").write_text("k")
        assert _run(out, ["svc"], ["svc"]) == 0
        assert (out / "notes" / "memo.md").is_file()

def test_success_keeps_nonparticipant_with_overlays_only():
    with tempfile.TemporaryDirectory() as t:
        out = Path(t); (out / "half" / "overlays").mkdir(parents=True)
        assert _run(out, ["svc"], ["svc"]) == 0
        assert (out / "half").exists()

def test_success_leaves_symlink_child_alone():
    with tempfile.TemporaryDirectory() as t:
        out = Path(t) / "out"; out.mkdir(); outside = Path(t) / "outside"; _seed_markers(outside)
        (out / "ghost").symlink_to(outside)
        assert _run(out, ["svc"], ["svc"]) == 0
        assert (out / "ghost").is_symlink() and (outside / "contract.json").exists()

def test_reject_before_check_removes_marker_dirs():
    with tempfile.TemporaryDirectory() as t:
        out = Path(t); _seed_markers(out / "svc")
        assert _run(out, ["svc"], []) == 1
        assert not (out / "svc").exists() and (out / "rejection.json").is_file()

def test_reject_before_check_keeps_unrelated_dir():
    with tempfile.TemporaryDirectory() as t:
        out = Path(t); (out / "notes").mkdir(); (out / "notes" / "memo.md").write_text("k")
        assert _run(out, ["svc"], []) == 1
        assert (out / "notes" / "memo.md").is_file()

def test_reject_before_check_keeps_sibling_dir_named_like_unknown_service():
    with tempfile.TemporaryDirectory() as t:
        out = Path(t); (out / "notes").mkdir(); (out / "notes" / "memo.md").write_text("k")
        assert _run(out, ["notes"], ["svc"]) == 1
        assert (out / "notes" / "memo.md").is_file()

def test_reject_after_check_removes_partial_participant_without_markers():
    with tempfile.TemporaryDirectory() as t:
        out = Path(t)
        assert _run(out, ["svc", "other"], ["svc", "other"], fail_write_for=("other",)) == 1
        assert not (out / "other").exists() and not (out / "svc").exists()

def test_reject_after_check_writes_rejection():
    with tempfile.TemporaryDirectory() as t:
        out = Path(t)
        assert _run(out, ["svc", "other"], ["svc", "other"], fail_write_for=("other",)) == 1
        assert (out / "rejection.json").is_file()

def test_symlink_participant_is_rejected_without_writing_outside():
    with tempfile.TemporaryDirectory() as t:
        out = Path(t) / "out"; out.mkdir(); outside = Path(t) / "outside"; outside.mkdir()
        (out / "svc").symlink_to(outside)
        assert _run(out, ["svc"], ["svc"]) == 1
        assert not any(outside.iterdir()) and (out / "svc").is_symlink()

def test_plain_file_at_participant_slot_is_rejected():
    with tempfile.TemporaryDirectory() as t:
        out = Path(t); (out / "svc").write_text("not a dir")
        assert _run(out, ["svc"], ["svc"]) == 1
        assert (out / "rejection.json").is_file()
