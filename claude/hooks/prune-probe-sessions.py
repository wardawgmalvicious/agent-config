# /// script
# requires-python = ">=3.12"
# dependencies = ["claude-agent-sdk>=0.2.163"]
# ///
"""Delete the session data of probe sessions two days after they last ran.

A probe is a throwaway Claude Code session started to observe Claude Code:
a /test-skill arm, a test-activation.ps1 or test-instruction-loading.py run,
a cold `claude -p` put to a repo, a background session checking a hook.
Two marks identify one:

  - its working directory is inside the temp folder, where every probe root
    lives and real work never does; or
  - its name starts with "probe:", which a probe started from a real repo
    takes with `-n "probe: <what>"`. The name is confirmed in the transcript,
    because the SDK falls back to the AI-generated title when none was set.

A probe goes whole: its transcript and `<id>/` sidecar under
~/.claude/projects, ~/.claude/session-env/<id> and file-history/<id>, and its
scratch folder under <temp>/claude. Then go folders left holding no file:
a probe's project folder, whose memory/ is always empty, and the scratch
folders of sessions Claude Code's own cleanupPeriodDays already removed,
which it leaves behind empty (2,458 of them on 2026-10-06). A folder holding
even one file stays, so no project's memory is ever touched.

Two days of grace, from the transcript's last write: a probe's transcript is
the witness the test that started it reads after it ends, so a probe cannot
delete itself and a fresh one is never touched.

Sessions come from the Agent SDK's list_sessions(), the documented reader,
which honours CLAUDE_CONFIG_DIR; that is how the tests point it at a fake
store. Reports by default; deletes only with --apply, which the SessionStart
hook prune-probe-sessions.sh passes once a day. With --apply each deletion
is a line in ~/.claude/logs/prune-probe-sessions.log.

    uv run --script claude/hooks/prune-probe-sessions.py              # report
    uv run --script ~/.claude/hooks/prune-probe-sessions.py --apply   # delete
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import stat
import sys
import tempfile
import time
from datetime import datetime, timezone
from pathlib import Path

GRACE_DAYS = 2.0
UUID = re.compile(r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")
CUSTOM_TITLE = re.compile(r'"customTitle":"((?:[^"\\]|\\.)*)"')


def long_path(path: str) -> str:
    """Expand a Windows 8.3 short name, so TEMP's short profile folder matches a cwd."""
    if os.name != "nt":
        return path
    import ctypes

    buf = ctypes.create_unicode_buffer(32768)
    n = ctypes.windll.kernel32.GetLongPathNameW(path, buf, len(buf))
    return buf.value if 0 < n < len(buf) else path


def key(path: str | os.PathLike) -> str:
    """A path as compared here: normalized, and case-folded on Windows."""
    return os.path.normcase(os.path.normpath(str(path)))


def temp_roots(given: list[str]) -> list[str]:
    """The temp folder in every spelling a cwd might record, as keys."""
    local = os.environ.get("LOCALAPPDATA")
    candidates = given or [
        tempfile.gettempdir(),
        os.environ.get("TEMP", ""),
        os.environ.get("TMP", ""),
        os.path.join(local, "Temp") if local else "",
    ]
    roots: list[str] = []
    for c in candidates:
        if c and os.path.isdir(c) and key(long_path(c)) not in roots:
            roots.append(key(long_path(c)))
    return roots


def inside(path: str | None, roots: list[str]) -> bool:
    """Whether path, a recorded cwd, is one of roots or inside one."""
    if not path:
        return False
    p = key(long_path(path))
    return any(p == r or p.startswith(r.rstrip(os.sep) + os.sep) for r in roots)


def planned(path: str | os.PathLike, gone: set[str]) -> bool:
    """Whether path or a folder above it is already planned for deletion."""
    p = key(path)
    while True:
        if p in gone:
            return True
        parent = os.path.dirname(p)
        if parent == p:
            return False
        p = parent


def holds_a_file(root: Path, gone: set[str]) -> bool:
    """Whether root holds a file that is not already planned for deletion."""
    for dirpath, _, files in os.walk(root):
        for f in files:
            if not planned(os.path.join(dirpath, f), gone):
                return True
    return False


def named_probe(transcripts: list[Path]) -> bool:
    """Whether the last name set in the transcript starts with "probe:"."""
    for path in transcripts:
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        titles = CUSTOM_TITLE.findall(text)
        if titles and titles[-1].lower().startswith("probe:"):
            return True
    return False


def tree_size(path: Path) -> int:
    if path.is_file():
        return path.stat().st_size
    total = 0
    for dirpath, _, files in os.walk(path):
        for f in files:
            try:
                total += os.path.getsize(os.path.join(dirpath, f))
            except OSError:
                pass
    return total


def mtime(path: Path) -> float:
    try:
        return path.stat().st_mtime
    except OSError:
        return time.time()


def writable_retry(func, path, _exc) -> None:
    """rmtree's onexc: clear a read-only bit, as git leaves on objects, and retry once."""
    os.chmod(path, stat.S_IWRITE)
    func(path)


def remove(path: Path) -> None:
    if path.is_dir() and not path.is_symlink():
        shutil.rmtree(path, onexc=writable_retry)
    else:
        path.unlink()


def find_probes(config: Path, transcripts: dict[str, list[Path]], roots: list[str],
                cutoff: float, keep: set[str]) -> tuple[list[dict], list[Path]]:
    """Probe sessions idle past the cutoff, and every path each one owns."""
    from claude_agent_sdk import list_sessions  # deferred: --help works without it

    probes: list[dict] = []
    owned: list[Path] = []
    for info in list_sessions():
        sid = info.session_id
        paths = transcripts.get(sid, [])
        if sid in keep or not paths:
            continue
        last = max([mtime(p) for p in paths] + [info.last_modified / 1000])
        if last > cutoff:
            continue
        if inside(info.cwd, roots):
            reason = "cwd in the temp folder"
        elif (info.custom_title or "").lower().startswith("probe:") and named_probe(paths):
            reason = 'named "probe: ..."'
        else:
            continue
        mine = [q for p in paths for q in (p, p.with_suffix(""))]
        mine += [config / "session-env" / sid, config / "file-history" / sid]
        for root in roots:
            mine += Path(root, "claude").glob(f"*/{sid}")
        mine = [p for p in mine if p.exists()]
        probes.append({
            "session_id": sid,
            "title": info.custom_title or info.summary or "",
            "cwd": info.cwd or "",
            "reason": reason,
            "last_active": datetime.fromtimestamp(last, timezone.utc).isoformat(timespec="seconds"),
            "bytes": sum(tree_size(p) for p in mine),
        })
        owned += mine
    return probes, owned


def find_empties(projects: Path, transcripts: dict[str, list[Path]], roots: list[str],
                 cutoff: float, keep: set[str], probe_ids: set[str],
                 gone: set[str]) -> list[Path]:
    """Folders that would hold no file once the probes go.

    Project folders a probe emptied or whose name encodes a temp-folder cwd;
    scratch folders under <temp>/claude whose session has no transcript left;
    and a scratch project folder once nothing in it remains.
    """
    empties: list[Path] = []
    touched = {key(p.parent) for p in map(Path, gone) if p.suffix == ".jsonl"}
    encoded = [re.sub(r"[^A-Za-z0-9]", "-", r).lower() for r in roots]
    for proj in sorted(projects.iterdir()):
        if not proj.is_dir() or planned(proj, gone):
            continue
        name = proj.name.lower()
        if key(proj) not in touched and not any(name.startswith(e + "-") for e in encoded):
            continue
        if not holds_a_file(proj, gone):
            empties.append(proj)
            gone.add(key(proj))
    for root in roots:
        base = Path(root, "claude")
        if not base.is_dir():
            continue
        for proj in sorted(base.iterdir()):
            if not proj.is_dir() or planned(proj, gone):
                continue
            for d in sorted(proj.iterdir()):
                if (
                    d.is_dir()
                    and UUID.match(d.name)
                    and d.name not in keep
                    and (d.name not in transcripts or d.name in probe_ids)
                    and not planned(d, gone)
                    and mtime(d) <= cutoff
                    and not holds_a_file(d, gone)
                ):
                    empties.append(d)
                    gone.add(key(d))
            if all(planned(child, gone) for child in proj.iterdir()):
                empties.append(proj)
                gone.add(key(proj))
    return empties


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--apply", action="store_true", help="delete; without it, only report")
    ap.add_argument("--grace-days", type=float, default=GRACE_DAYS,
                    help="idle days before a probe goes (default 2)")
    ap.add_argument("--keep", action="append", default=[], metavar="SESSION_ID",
                    help="never touch this session")
    ap.add_argument("--temp-dir", action="append", default=[], metavar="DIR",
                    help="the temp folder (default: the system's, in each spelling)")
    ap.add_argument("--verbose", action="store_true", help="list every empty folder too")
    args = ap.parse_args(argv)
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    config = Path(os.environ.get("CLAUDE_CONFIG_DIR") or Path.home() / ".claude")
    projects = config / "projects"
    if not projects.is_dir():
        print(f"no session store at {projects}")
        return 0
    roots = temp_roots(args.temp_dir)
    cutoff = time.time() - args.grace_days * 86400
    keep = set(args.keep)
    transcripts: dict[str, list[Path]] = {}
    for path in projects.glob("*/*.jsonl"):
        transcripts.setdefault(path.stem, []).append(path)

    probes, owned = find_probes(config, transcripts, roots, cutoff, keep)
    gone = {key(p) for p in owned}
    probe_ids = {p["session_id"] for p in probes}
    empties = find_empties(projects, transcripts, roots, cutoff, keep, probe_ids, gone)

    total = sum(p["bytes"] for p in probes)
    print(f"probe sessions idle {args.grace_days:g} days or more: {len(probes)}, "
          f"{total / 1e6:.1f} MB")
    for p in sorted(probes, key=lambda x: x["last_active"]):
        print(f"  {p['last_active'][:10]}  {p['title'][:40]:40}  {p['session_id']}"
              f"  [{p['reason']}]")
    print(f"folders holding no file: {len(empties)}")
    if args.verbose:
        for e in empties:
            print(f"  {e}")
    if not args.apply:
        print("report only: nothing deleted; --apply deletes")
        return 0

    errors = 0
    for path in owned + empties:
        try:
            if path.exists():
                remove(path)
        except OSError as exc:
            errors += 1
            print(f"error: {path}: {exc}", file=sys.stderr)
    stamp = datetime.now(timezone.utc).isoformat(timespec="seconds")
    log = config / "logs" / "prune-probe-sessions.log"
    try:
        log.parent.mkdir(parents=True, exist_ok=True)
        with log.open("a", encoding="utf-8", newline="\n") as fh:
            for p in probes:
                fh.write(json.dumps({"ts": stamp, "event": "probe-session", **p}) + "\n")
            fh.write(json.dumps({"ts": stamp, "event": "run", "sessions": len(probes),
                                 "bytes": total, "empty_folders": len(empties),
                                 "errors": errors}) + "\n")
    except OSError as exc:
        errors += 1
        print(f"error: {log}: {exc}", file=sys.stderr)
    print(f"deleted {len(probes)} probe sessions and {len(empties)} empty folders; {errors} errors")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
