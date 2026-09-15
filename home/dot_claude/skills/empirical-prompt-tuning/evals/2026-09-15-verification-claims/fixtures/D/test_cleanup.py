import sys, tempfile
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import cleanup

def test_reject_removes_stale_nonparticipant():
    with tempfile.TemporaryDirectory() as t:
        out = Path(t); (out / "other").mkdir(); (out / "other" / "contract.json").write_text("s")
        cleanup.on_reject(out, ("svc",)); assert not (out / "other").exists()

def test_reject_keeps_unrelated():
    with tempfile.TemporaryDirectory() as t:
        out = Path(t); (out / "notes").mkdir(); (out / "notes" / "m").write_text("k")
        cleanup.on_reject(out, ("svc",)); assert (out / "notes").exists()

def test_success_keeps_participant():
    with tempfile.TemporaryDirectory() as t:
        out = Path(t); (out / "svc").mkdir(); (out / "svc" / "contract.json").write_text("f")
        cleanup.on_success(out, ("svc",)); assert (out / "svc").exists()
