#!/usr/bin/env python3
"""
Caelestia upstream-sync tool.

Keeps the repository in sync with the upstream caelestia-kde repo
(https://github.com/ladybug-me/caelestia-kde, dev branch), tracked as
the `upstream` git remote.

Checks all files across the repository EXCEPT `shell/`, while INCLUDING
`shell/plugin/`.

Commands:
    fetch                 fetch upstream and refresh the mirror branch
    report                classify repo files vs upstream/dev (the sync report)
    bring PATH...         copy upstream paths into repo (then you adapt)
    bring --force PATH... overwrite an existing local file with upstream

See docs/upstream-sync.md for the full process.
"""

import argparse
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

UPSTREAM_REMOTE = "upstream"
UPSTREAM_URL = "https://github.com/ladybug-me/caelestia-kde.git"
UPSTREAM_BRANCH = "dev"
UPSTREAM = f"{UPSTREAM_REMOTE}/{UPSTREAM_BRANCH}"
LOCAL_TREE = "HEAD"
MIRROR_BRANCH = "mirror/upstream"


def is_included_path(path: str) -> bool:
    """Return True if path should be tracked by this sync tool.

    Includes all files in the repository EXCEPT `shell/`,
    while explicitly INCLUDING `shell/plugin/`.
    """
    if path == "shell/plugin" or path.startswith("shell/plugin/"):
        return True
    if path == "shell" or path.startswith("shell/"):
        return False
    return True


def git(*args: str, cwd: str = ROOT) -> str:
    """Run git and return stdout, raising on failure."""
    proc = subprocess.run(
        ["git", *args], cwd=cwd, capture_output=True, text=True, encoding="utf-8"
    )
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr)
        raise SystemExit(proc.returncode)
    return proc.stdout


def git_bytes(*args: str, cwd: str = ROOT) -> bytes:
    proc = subprocess.run(["git", *args], cwd=cwd, capture_output=True)
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr.decode(errors="replace"))
        raise SystemExit(proc.returncode)
    return proc.stdout


def ls_tree(tree: str) -> dict[str, str]:
    """Return {path: blob_hash} for every included file under `tree`."""
    out = git("ls-tree", "-r", tree)
    result: dict[str, str] = {}
    for line in out.splitlines():
        if "\t" not in line:
            continue
        meta, path = line.split("\t", 1)
        parts = meta.split()
        if len(parts) != 3:
            continue
        _mode, obj_type, blob = parts
        if obj_type in {"blob", "commit"} and is_included_path(path):
            result[path] = blob
    return result


def kind(path: str) -> str:
    """Rough file category used only to make the report scannable."""
    name = os.path.basename(path)
    ext = os.path.splitext(path)[1].lower()
    if path.startswith((".github", ".vscode", "nix")) or name in {"flake.nix", "flake.lock", "crowdin.yml"}:
        return "meta"
    if ext in {".cpp", ".hpp", ".h", ".c", ".cc", ".frag", ".vert", ".cmake"} or name == "CMakeLists.txt":
        return "cpp"
    if ext in {".sh", ".bash"} or path.startswith(("scripts/", "installer/", "tests/")):
        return "script"
    if path.startswith("assets/") or ext in {
        ".ttf", ".otf", ".webp", ".png", ".svg", ".jpg", ".jpeg", ".gif", ".pam",
    }:
        return "asset"
    if ext == ".qml":
        return "qml"
    return "other"


def hypr_paths(tree: str) -> set[str]:
    """Paths under `tree` whose content mentions Hypr (Hyprland coupling)."""
    try:
        proc = subprocess.run(
            ["git", "grep", "-l", "-i", "-e", "Hypr", tree],
            cwd=ROOT,
            capture_output=True,
            text=True,
            encoding="utf-8",
        )
        if proc.returncode not in (0, 1):
            return set()
        out = proc.stdout
    except Exception:
        return set()

    result: set[str] = set()
    for line in out.splitlines():
        p = line.strip()
        if not p:
            continue
        if ":" in p:
            p = p.split(":", 1)[1]
        if is_included_path(p):
            result.add(p)
    return result


def ensure_remote() -> None:
    remotes = git("remote").splitlines()
    if UPSTREAM_REMOTE not in remotes:
        print(f"Adding remote '{UPSTREAM_REMOTE}' -> {UPSTREAM_URL} ...")
        git("remote", "add", UPSTREAM_REMOTE, UPSTREAM_URL)
    else:
        url = git("remote", "get-url", UPSTREAM_REMOTE).strip()
        if "caelestia-kde" not in url:
            print(f"Updating remote '{UPSTREAM_REMOTE}' URL to {UPSTREAM_URL} ...")
            git("remote", "set-url", UPSTREAM_REMOTE, UPSTREAM_URL)


def do_fetch() -> None:
    ensure_remote()
    print(f"Fetching {UPSTREAM_REMOTE} {UPSTREAM_BRANCH} ...")
    try:
        git("fetch", UPSTREAM_REMOTE, UPSTREAM_BRANCH)
    except SystemExit:
        local_dir = os.path.join(ROOT, "caelestia-kde")
        if os.path.isdir(os.path.join(local_dir, ".git")):
            print(f"Fetch failed; attempting local fetch from {local_dir} ...")
            git("fetch", local_dir, f"refs/remotes/origin/{UPSTREAM_BRANCH}:refs/remotes/{UPSTREAM_REMOTE}/{UPSTREAM_BRANCH}")
        else:
            raise
    git("branch", "-f", MIRROR_BRANCH, UPSTREAM)
    rev = git("rev-parse", "--short", UPSTREAM).strip()
    print(f"{MIRROR_BRANCH} -> {rev}")


def do_report(full: bool) -> None:
    local_files = ls_tree(LOCAL_TREE)
    up_files = ls_tree(UPSTREAM)

    in_sync: list[str] = []
    missing: list[str] = []
    local_only: list[str] = []
    diverged: list[str] = []

    for path, blob in up_files.items():
        if path not in local_files:
            missing.append(path)
        elif local_files[path] == blob:
            in_sync.append(path)
        else:
            diverged.append(path)
    for path in local_files:
        if path not in up_files:
            local_only.append(path)

    up_hypr = hypr_paths(UPSTREAM)
    local_hypr = hypr_paths(LOCAL_TREE)

    def flag(path: str) -> str:
        tags = kind(path)
        if path in up_hypr or path in local_hypr:
            tags += ",hypr"
        return tags

    print(f"=== SYNC REPORT: repo (excluding shell/ except shell/plugin/) vs {UPSTREAM} ===")
    print(f"local files: {len(local_files)}   upstream files: {len(up_files)}")
    print(f"  in sync   : {len(in_sync)}")
    print(f"  local-only: {len(local_only)}  (never touched by sync)")
    print(f"  missing   : {len(missing)}  (bring down + adapt)")
    print(f"  diverged  : {len(diverged)}  (triage each)")
    print()

    print(f"--- MISSING ({len(missing)}) ---")
    shown_missing = missing if full else missing[:60]
    for p in shown_missing:
        print(f"  [{flag(p):<9}] {p}")
    if not full and len(missing) > 60:
        print(f"  ... {len(missing) - 60} more (use --full)")
    print()

    print(f"--- DIVERGED ({len(diverged)}) ---")
    shown_diverged = diverged if full else diverged[:60]
    for p in shown_diverged:
        print(f"  [{flag(p):<9}] {p}")
    if not full and len(diverged) > 60:
        print(f"  ... {len(diverged) - 60} more (use --full)")
    print()

    print("Bring a missing file with:  python3 tools/sync-shell.py bring <path>")


def do_bring(paths: list[str], force: bool) -> None:
    for path in paths:
        norm_path = os.path.normpath(path).lstrip("./")
        if not is_included_path(norm_path):
            print(f"skip {norm_path}: excluded path (shell/ is excluded except shell/plugin/)")
            continue

        up_blob = git("ls-tree", UPSTREAM, "--", norm_path).strip()
        if not up_blob:
            print(f"skip {norm_path}: not present in {UPSTREAM}")
            continue

        exists = bool(git("ls-tree", LOCAL_TREE, "--", norm_path).strip())
        if exists and not force:
            print(f"skip {norm_path}: already exists locally (use --force to overwrite)")
            continue
        if exists and force:
            print(f"overwrite {norm_path}")

        content = git_bytes("show", f"{UPSTREAM}:{norm_path}")
        dest = os.path.join(ROOT, norm_path)
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        with open(dest, "wb") as fh:
            fh.write(content)
        git("add", norm_path)
        print(f"brought  {norm_path}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Caelestia upstream-sync tool (github.com/ladybug-me/caelestia-kde dev branch)"
    )
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("fetch", help="fetch upstream dev and refresh the mirror branch")

    rep = sub.add_parser("report", help="classify repo files vs upstream/dev")
    rep.add_argument("--full", action="store_true", help="show every missing and diverged file")

    br = sub.add_parser("bring", help="copy upstream paths into local repo")
    br.add_argument("--force", action="store_true", help="overwrite existing files")
    br.add_argument(
        "paths",
        nargs="+",
        help="paths relative to repo root, e.g. scripts/08-build-shell.sh or shell/plugin/src/foo.cpp",
    )

    args = parser.parse_args()
    if args.cmd == "fetch":
        do_fetch()
    elif args.cmd == "report":
        do_report(args.full)
    elif args.cmd == "bring":
        do_bring(args.paths, args.force)


if __name__ == "__main__":
    main()
