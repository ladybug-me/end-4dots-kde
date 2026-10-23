#!/usr/bin/env python3
"""Fail when a QML component shadows a FINAL member of its base type."""
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
QMLLINT_PATHS = ("/usr/lib/qt6/bin/qmllint",)
BATCH = 40
FATAL_RE = re.compile(r"shadows final member", re.IGNORECASE)


def qmllint() -> str | None:
    """The qmllint to run, or None when the machine has no Qt tooling."""
    override = shutil.which("qmllint")
    if override:
        return override
    for candidate in QMLLINT_PATHS:
        if Path(candidate).is_file():
            return candidate
    try:
        import PySide6
    except ImportError:
        return None
    for name in ("qmllint", "qmllint.exe"):
        bundled = Path(PySide6.__file__).parent / name
        if bundled.is_file():
            return str(bundled)
    return None


def qml_files(source_root: str) -> list[str]:
    return sorted(str(p.relative_to(ROOT)) for p in (ROOT / source_root).rglob("*.qml"))


def shadows_final(exe: str, files: list[str]) -> tuple[list[str], str]:
    offenders: list[str] = []
    with tempfile.TemporaryDirectory() as tmp:
        report = Path(tmp) / "qmllint.json"
        for start in range(0, len(files), BATCH):
            batch = files[start : start + BATCH]
            result = subprocess.run(
                [
                    exe,
                    "--only-explicit-categories",
                    "--property-override",
                    "warning",
                    "--json",
                    str(report),
                    *batch,
                ],
                capture_output=True,
                text=True,
                cwd=ROOT,
                errors="replace",
            )
            if not report.is_file():
                return [], f"qmllint wrote no report: {(result.stderr or result.stdout or '').strip()[:400]}"
            try:
                parsed = json.loads(report.read_text(encoding="utf-8"))
            except (json.JSONDecodeError, OSError) as error:
                return [], f"could not read qmllint's report: {error}"
            report.unlink()

            for entry in parsed.get("files", []):
                for warning in entry.get("warnings", []):
                    if warning.get("id") != "property-override":
                        continue
                    if not FATAL_RE.search(warning.get("message", "")):
                        continue
                    offenders.append(
                        f"{entry.get('filename')}:{warning.get('line')}: {warning.get('message', '').strip()}"
                    )
    return offenders, ""


def main() -> int:
    args = sys.argv[1:]
    source_root = "shell"
    if "--source-root" in args:
        index = args.index("--source-root")
        if index + 1 >= len(args):
            print("--source-root needs a directory", file=sys.stderr)
            return 2
        source_root = args[index + 1]

    print("=== QML final-member shadow check ===")

    exe = qmllint()
    if not exe:
        print("qmllint is not installed, and without it this check cannot see base types")
        print("Install Qt's declarative tools (qt6-declarative on Arch), or pip install PySide6")
        return 1

    files = qml_files(source_root)
    if not files:
        print(f"No QML files under {source_root}")
        return 0

    print(f"Checking {len(files)} file(s) with {exe}")
    offenders, failure = shadows_final(exe, files)
    if failure:
        print(f"\n{failure}")
        return 1
    if offenders:
        print("\nA component cannot declare a member its base type declares as FINAL:")
        for offender in offenders:
            print(f"  {offender}")
        print(f"\n{len(offenders)} declaration(s) shadow a final member; QML cannot instantiate these")
        return 1

    print("No component shadows a final member")
    return 0


if __name__ == "__main__":
    sys.exit(main())
