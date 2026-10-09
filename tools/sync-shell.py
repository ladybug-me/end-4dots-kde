#!/usr/bin/env python3
"""
Caelestia-KDE upstream sync tool for end-4dots-kde.

Keeps this repository in sync with the upstream caelestia-kde repository
(tracked as the `upstream` remote, branch `dev`, or submodule `upstreams/caelestia-kde`).

Protects end-4 customizations, adapts shared C++ plugins/scripts/tests/CI,
and automates future syncing.

Commands:
    fetch                 fetch upstream remote and update upstreams/caelestia-kde
    report                classify repository paths vs upstream
    sync [--dry-run]      automatically sync safe upstream changes & re-apply adaptations
    bring PATH...         copy specific upstream paths into repository
    diff PATH             show diff between local file and upstream version
"""

import argparse
import fnmatch
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import sys
from typing import NamedTuple

DEFAULT_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_UPSTREAM_REMOTE = "upstream"
DEFAULT_UPSTREAM_BRANCH = "upstream/dev"
UPSTREAM_SUBMODULE = "upstreams/caelestia-kde"

# Paths that are strictly specific to end-4dots-kde and must never be overwritten
PROTECTED_PATTERNS = (
    ".gitmodules",
    "tools/sync-shell.py",
    "packaging/aur/README.md",
    "README.md",
    "src/dots/*",
    "src/dots",
    "src/dots-extra/*",
    "src/dots-extra",
    "src/yet-another-monochrome-icon-set",
    "src/yet-another-monochrome-icon-set/*",
    "installer/uv/*",
    "installer/uv",
    "scripts/02-packages.sh",
    "scripts/lib/uv_tool.sh",
    "tests/test_shortcuts_model.sh",
    "shell/modules/common/*",
    "shell/modules/common",
    "shell/modules/ii/*",
    "shell/modules/ii",
    "shell/modules/settings/*",
    "shell/modules/settings",
    "shell/modules/waffle/*",
    "shell/modules/waffle",
    "shell/panelFamilies/*",
    "shell/panelFamilies",
    "shell/defaults/*",
    "shell/defaults",
    "shell/translations/*.json",
    "shell/translations/tools/*",
    "shell/translations/tools",
    "shell/settings.qml",
    "shell/welcome.qml",
    "shell/GlobalShortcut.qml",
    "shell/GlobalStates.qml",
    "shell/killDialog.qml",
    "shell/ReloadPopup.qml",
    "shell/assets/*",
    "shell/components/*",
    "shell/utils/*",
    "shell/scripts/thumbnails/*",
    "shell/scripts/thumbnails",
    "shell/scripts/videos/*",
    "shell/scripts/videos",
    "shell/scripts/images/*",
    "shell/scripts/images",
    "upstreams/*",
    "upstreams",
)

# New/shared services from upstream that are allowed to sync
SHARED_ALLOWED_SERVICES = {
    "shell/services/AiToolCalls.qml",
    "shell/services/DesktopLayout.qml",
    "shell/services/QuickShare.qml",
    "shell/services/QuickShareSetup.qml",
}

# Paths that are based on upstream but contain intentional adaptations
ADAPTED_FILES = {
    "shell/CMakeLists.txt",
    "shell/shell.qml",
    "shell/services/Kwin.qml",
    "shell/modules/Shortcuts.qml",
    "shell/plugin/src/Caelestia/Services/kwinactivewindowbridge.cpp",
    "scripts/08-build-shell.sh",
    "scripts/10-autostart.sh",
    "scripts/02a-submodules.sh",
    "scripts/03-deploy-configs.sh",
    "packaging/aur/caelestia-kde/PKGBUILD",
    "packaging/aur/caelestia-kde/caelestia-autostart",
    "src/bin/caelestia",
    "tests/test_ai_assistant.sh",
    "tests/test_ai_toolcalls.sh",
    "tests/test_bar_workspaces.sh",
    "tests/test_hotspot_toggle.sh",
    "tests/test_nexus_page_switch.sh",
    "tests/test_quickshare_ui.sh",
    "tests/test_uninstall_button.sh",
}

# Upstream paths that are part of Caelestia UI but replaced by end-4 UI
UPSTREAM_UI_REPLACED_PREFIXES = (
    "shell/modules/background",
    "shell/modules/bar",
    "shell/modules/dashboard",
    "shell/modules/drawers",
    "shell/modules/launcher",
    "shell/modules/nexus",
    "shell/modules/notifications",
    "shell/modules/osd",
    "shell/modules/overview",
    "shell/modules/sidebar",
    "shell/modules/utilities",
    "shell/modules/whatsnew",
    "shell/modules/windowinfo",
    "shell/modules/session",
    "shell/modules/screenshot",
    "shell/modules/plugins",
    "shell/modules/BatteryMonitor.qml",
    "shell/modules/BluetoothReconnect.qml",
    "shell/modules/GSFLoader.qml",
    "shell/modules/ScreenCorners.qml",
    "shell/modules/ServiceLoader.qml",
    "shell/components/",
    "shell/utils/",
    "shell/assets/",
    "shell/translations/caelestia_",
    "shell/translations/README.md",
    "shell/LICENSE",
)


def git_blob_hash(data: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()


def is_protected(path: str) -> bool:
    if path.startswith("shell/services/"):
        if path.startswith("shell/services/startuptasks/"):
            return False
        if path in SHARED_ALLOWED_SERVICES:
            return False
        return True

    for pat in PROTECTED_PATTERNS:
        if fnmatch.fnmatch(path, pat) or path == pat.rstrip("/*"):
            return True
    return False


def is_upstream_ui_replaced(path: str) -> bool:
    return any(path.startswith(prefix) for prefix in UPSTREAM_UI_REPLACED_PREFIXES)


class GitError(RuntimeError):
    def __init__(self, cmd: tuple[str, ...], returncode: int, stderr: str) -> None:
        super().__init__(f"git {' '.join(cmd)} failed (exit {returncode}):\n{stderr}")
        self.cmd = cmd
        self.returncode = returncode
        self.stderr = stderr


class Repo:
    def __init__(self, root: Path) -> None:
        self.root = root

    def _raw(self, args: tuple[str, ...]) -> subprocess.CompletedProcess[bytes]:
        return subprocess.run(["git", *args], cwd=self.root, capture_output=True)

    def _checked(self, args: tuple[str, ...]) -> bytes:
        proc = self._raw(args)
        if proc.returncode != 0:
            raise GitError(args, proc.returncode, proc.stderr.decode(errors="replace"))
        return proc.stdout

    def git(self, *args: str) -> str:
        return self._checked(args).decode("utf-8")

    def git_bytes(self, *args: str) -> bytes:
        return self._checked(args)

    def ls_tree(self, tree: str) -> dict[str, str]:
        result: dict[str, str] = {}
        proc = self._raw(("ls-tree", "-r", tree))
        if proc.returncode != 0:
            return result
        for line in proc.stdout.decode("utf-8").splitlines():
            if not line:
                continue
            meta, path = line.split("\t", 1)
            mode, obj_type, blob = meta.split()
            if obj_type != "blob":
                continue
            result[path] = blob
        return result

    def working_tree(self) -> dict[str, str]:
        result: dict[str, str] = {}
        out = self.git("ls-files")
        for line in out.splitlines():
            if not line:
                continue
            file_path = self.root / line
            if file_path.is_file():
                try:
                    result[line] = git_blob_hash(file_path.read_bytes())
                except OSError:
                    pass
        return result


class Classified(NamedTuple):
    in_sync: list[str]
    auto_syncable: list[str]
    adapted: list[str]
    protected: list[str]
    upstream_only: list[str]
    repo_only: list[str]


def classify_repo(local_tree: dict[str, str], upstream_tree: dict[str, str]) -> Classified:
    in_sync: list[str] = []
    auto_syncable: list[str] = []
    adapted: list[str] = []
    protected: list[str] = []
    upstream_only: list[str] = []
    repo_only: list[str] = []

    for path, up_blob in upstream_tree.items():
        if path in local_tree:
            loc_blob = local_tree[path]
            if loc_blob == up_blob:
                in_sync.append(path)
            elif is_protected(path):
                protected.append(path)
            elif path in ADAPTED_FILES:
                adapted.append(path)
            elif is_upstream_ui_replaced(path):
                upstream_only.append(path)
            else:
                auto_syncable.append(path)
        else:
            if is_protected(path):
                protected.append(path)
            elif is_upstream_ui_replaced(path):
                upstream_only.append(path)
            else:
                auto_syncable.append(path)

    for path in local_tree:
        if path not in upstream_tree:
            if is_protected(path):
                protected.append(path)
            else:
                repo_only.append(path)

    return Classified(
        sorted(in_sync),
        sorted(auto_syncable),
        sorted(adapted),
        sorted(set(protected)),
        sorted(upstream_only),
        sorted(repo_only),
    )


def resolve_upstream_tree(repo: Repo, upstream_ref: str) -> str:
    submodule_path = repo.root / UPSTREAM_SUBMODULE
    if submodule_path.exists() and (submodule_path / ".git").exists():
        proc = subprocess.run(
            ["git", "-C", str(submodule_path), "rev-parse", "HEAD"],
            capture_output=True,
            text=True,
        )
        if proc.returncode == 0:
            commit = proc.stdout.strip()
            check = repo._raw(("rev-parse", "--verify", commit))
            if check.returncode == 0:
                return commit
    return upstream_ref


def do_fetch(repo: Repo) -> None:
    print("Fetching upstream remote ...")
    try:
        repo.git("fetch", DEFAULT_UPSTREAM_REMOTE)
        print(f"Updated {DEFAULT_UPSTREAM_REMOTE}")
    except GitError as e:
        print(f"Warning: could not fetch remote '{DEFAULT_UPSTREAM_REMOTE}': {e.stderr.strip()}")

    submodule_path = repo.root / UPSTREAM_SUBMODULE
    if submodule_path.exists() and (submodule_path / ".git").exists():
        print(f"Pulling {UPSTREAM_SUBMODULE} ...")
        proc = subprocess.run(["git", "-C", str(submodule_path), "pull", "--ff-only", "origin", "dev"])
        if proc.returncode == 0:
            print(f"Updated {UPSTREAM_SUBMODULE}")


def do_report(repo: Repo, upstream_ref: str, full: bool) -> None:
    target_ref = resolve_upstream_tree(repo, upstream_ref)
    local_tree = repo.working_tree()
    up_tree = repo.ls_tree(target_ref)

    c = classify_repo(local_tree, up_tree)

    print(f"=== SYNC REPORT: repository vs upstream ({target_ref}) ===")
    print(f"Total local files: {len(local_tree)}   Total upstream files: {len(up_tree)}")
    print(f"  In sync       : {len(c.in_sync)}")
    print(f"  Auto-syncable : {len(c.auto_syncable)}  (safe upstream additions/updates)")
    print(f"  Adapted files : {len(c.adapted)}  (shared infrastructure with end-4 patches)")
    print(f"  Protected     : {len(c.protected)}  (end-4 dotfiles, services, components)")
    print(f"  Upstream UI   : {len(c.upstream_only)}  (Caelestia UI replaced by end-4)")
    print()

    if c.auto_syncable:
        print(f"--- AUTO-SYNCABLE ({len(c.auto_syncable)}) ---")
        for p in c.auto_syncable[: (len(c.auto_syncable) if full else 30)]:
            print(f"  + {p}")
        if not full and len(c.auto_syncable) > 30:
            print(f"  ... {len(c.auto_syncable) - 30} more (use --full)")
        print()

    if c.adapted:
        print(f"--- ADAPTED FILES ({len(c.adapted)}) ---")
        for p in c.adapted:
            print(f"  * {p}")
        print()


def apply_end4_post_sync_patches(repo: Repo) -> None:
    bridge_cpp = repo.root / "shell/plugin/src/Caelestia/Services/kwinactivewindowbridge.cpp"
    if bridge_cpp.exists():
        content = bridge_cpp.read_text(encoding="utf-8")
        target_needle = '{ QStringLiteral("height"), w->height() },'
        if target_needle in content and '{ QStringLiteral("at"), QVariantList{ w->x(), w->y() } },' not in content:
            replacement = (
                '{ QStringLiteral("height"), w->height() }, '
                '{ QStringLiteral("at"), QVariantList{ w->x(), w->y() } },\n'
                '        { QStringLiteral("size"), QVariantList{ w->width(), w->height() } },'
            )
            content = content.replace(target_needle, replacement, 1)
            bridge_cpp.write_text(content, encoding="utf-8")
            print("  Re-applied patch: kwinactivewindowbridge.cpp ('at' and 'size' properties)")

    build_shell_sh = repo.root / "scripts/08-build-shell.sh"
    if build_shell_sh.exists():
        content = build_shell_sh.read_text(encoding="utf-8")
        if "Caelestia/Services/QuickShare" not in content and "Caelestia/Services" in content:
            content = content.replace(
                "    Caelestia/Services\n",
                "    Caelestia/Services\n    Caelestia/Services/QuickShare\n",
                1,
            )
            build_shell_sh.write_text(content, encoding="utf-8")
            print("  Re-applied patch: scripts/08-build-shell.sh (Caelestia/Services/QuickShare module)")


def do_sync(repo: Repo, upstream_ref: str, dry_run: bool) -> None:
    target_ref = resolve_upstream_tree(repo, upstream_ref)
    local_tree = repo.working_tree()
    up_tree = repo.ls_tree(target_ref)
    c = classify_repo(local_tree, up_tree)

    print(f"Syncing from upstream ({target_ref}) ...")
    if dry_run:
        print("[DRY RUN - no files will be written]")

    synced_count = 0
    for path in c.auto_syncable:
        if is_protected(path) or is_upstream_ui_replaced(path) or path in ADAPTED_FILES:
            continue
        if not dry_run:
            dest = repo.root / path
            dest.parent.mkdir(parents=True, exist_ok=True)
            content = repo.git_bytes("show", f"{target_ref}:{path}")
            dest.write_bytes(content)
        print(f"  sync: {path}")
        synced_count += 1

    if not dry_run:
        apply_end4_post_sync_patches(repo)

    print(f"\nSuccessfully synchronized {synced_count} files from upstream.")


def do_bring(repo: Repo, upstream_ref: str, paths: list[str], force: bool) -> None:
    target_ref = resolve_upstream_tree(repo, upstream_ref)
    for path in paths:
        path = path.strip().lstrip("/")
        up_blob = repo.git("ls-tree", target_ref, "--", path).strip()
        if not up_blob:
            print(f"skip {path}: not present in upstream ({target_ref})")
            continue

        dest = repo.root / path
        if dest.exists() and not force:
            print(f"skip {path}: file exists locally (use --force to overwrite)")
            continue

        dest.parent.mkdir(parents=True, exist_ok=True)
        content = repo.git_bytes("show", f"{target_ref}:{path}")
        dest.write_bytes(content)
        print(f"brought {path}")


def do_diff(repo: Repo, upstream_ref: str, path: str) -> None:
    target_ref = resolve_upstream_tree(repo, upstream_ref)
    path = path.strip().lstrip("/")
    proc = subprocess.run(["git", "diff", f"{target_ref}:{path}", "--", path], cwd=repo.root)
    if proc.returncode != 0:
        sys.exit(proc.returncode)


def main() -> None:
    parser = argparse.ArgumentParser(description="Caelestia-KDE upstream sync tool for end-4dots-kde")
    parser.add_argument("--root", type=Path, default=DEFAULT_ROOT, help="repository root directory")
    parser.add_argument("--upstream", default=DEFAULT_UPSTREAM_BRANCH, help="upstream branch/ref (default: upstream/dev)")
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("fetch", help="fetch upstream and refresh submodule")

    rep = sub.add_parser("report", help="classify repository paths vs upstream")
    rep.add_argument("--full", action="store_true", help="show all auto-syncable files")

    syn = sub.add_parser("sync", help="automatically sync safe upstream changes")
    syn.add_argument("--dry-run", action="store_true", help="preview actions without writing files")

    br = sub.add_parser("bring", help="copy specific upstream path(s)")
    br.add_argument("--force", action="store_true", help="force overwrite local files")
    br.add_argument("paths", nargs="+", help="path(s) to bring from upstream")

    df = sub.add_parser("diff", help="show diff against upstream")
    df.add_argument("path", help="path to compare against upstream")

    args = parser.parse_args()
    repo = Repo(args.root.resolve())

    try:
        if args.cmd == "fetch":
            do_fetch(repo)
        elif args.cmd == "report":
            do_report(repo, args.upstream, args.full)
        elif args.cmd == "sync":
            do_sync(repo, args.upstream, args.dry_run)
        elif args.cmd == "bring":
            do_bring(repo, args.upstream, args.paths, args.force)
        elif args.cmd == "diff":
            do_diff(repo, args.upstream, args.path)
    except GitError as error:
        sys.stderr.write(f"{error}\n")
        raise SystemExit(error.returncode) from error


if __name__ == "__main__":
    main()
