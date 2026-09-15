"""Tiny stand-in for a generator that writes per-service bundles under out_dir."""
import shutil
from pathlib import Path

MARKERS = ("contract.json", "snapshot.json")


def is_own_output_dir(child, participants):
    if child.is_symlink() or not child.is_dir():
        return False
    if child.name in participants:
        return True
    return any((child / m).exists() for m in MARKERS)


def remove_own_output_dirs(out_dir, participants, keep=()):
    if not out_dir.is_dir():
        return
    for child in out_dir.iterdir():
        if child.name in keep:
            continue
        if is_own_output_dir(child, participants):
            shutil.rmtree(child)


def write_bundle(service_dir, fail=False):
    if service_dir.is_symlink():
        raise OSError(f"{service_dir} is a symlink")
    service_dir.mkdir(parents=True, exist_ok=True)
    (service_dir / "overlays").mkdir(exist_ok=True)
    (service_dir / "overlays" / "x.yaml").write_text("x")
    if fail:
        raise OSError("simulated write failure")
    for m in MARKERS:
        (service_dir / m).write_text("fresh")


def reject(out_dir, reason, participants):
    out_dir.mkdir(parents=True, exist_ok=True)
    remove_own_output_dirs(out_dir, participants)
    (out_dir / "rejection.json").write_text(reason)
    return 1


def main(out_dir, services, open_services, fail_write_for=()):
    out_dir = Path(out_dir)
    confirmed = ()
    if sorted(services) != sorted(open_services):
        return reject(out_dir, "service set mismatch", confirmed)
    confirmed = tuple(services)
    try:
        for s in services:
            write_bundle(out_dir / s, fail=s in fail_write_for)
    except OSError as e:
        return reject(out_dir, str(e), confirmed)
    remove_own_output_dirs(out_dir, participants=services, keep=services)
    return 0
