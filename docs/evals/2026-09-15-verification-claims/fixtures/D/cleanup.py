import shutil
MARKERS = ("contract.json", "snapshot.json")


def remove_participant_dirs(out_dir, services):
    for service in services:
        child = out_dir / service
        if child.is_symlink():
            continue
        if child.is_dir():
            shutil.rmtree(child)


def cleanup_stale_service_dirs(out_dir, services):
    if not out_dir.is_dir():
        return
    for child in out_dir.iterdir():
        if child.is_symlink() or not child.is_dir():
            continue
        if child.name in services:
            continue
        if any((child / m).exists() for m in MARKERS):
            shutil.rmtree(child)


def on_reject(out_dir, confirmed_services):
    remove_participant_dirs(out_dir, confirmed_services)
    cleanup_stale_service_dirs(out_dir, confirmed_services)


def on_success(out_dir, services):
    cleanup_stale_service_dirs(out_dir, services)
