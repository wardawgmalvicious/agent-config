#!/usr/bin/env python3
"""Show, per folder of a repo, what its past Claude Code sessions did there.

    uv run --no-project <skill>/scripts/folder-sessions.py               # the repo you are in
    uv run --no-project <skill>/scripts/folder-sessions.py --folder docs  # folders under docs/
    uv run --no-project <skill>/scripts/folder-sessions.py --depth 2 --min 3
    uv run --no-project <skill>/scripts/folder-sessions.py --json        # for a session to parse

<skill> is the scope-instructions skill's folder, ~/.claude/skills/scope-instructions
once deployed; --no-project keeps uv from syncing the Python project of
whatever repo it runs in.

For each folder it reports how many sessions Read, Wrote or Edited a file
there, how many edited, how many only through a subagent, and how many
compacted; whether each session opened the folder's README before any
other file there, only later, or never, and whether a prompt the user
typed named that README first; and which nested CLAUDE.md files and rules
loaded on a call there. That is the evidence for moving guidance: a README
is the agent's choice to open, a nested file or a paths: rule is not. In a
client Fabric repo 5 of 9 sessions working in a folder with a README
opened it late or never (2026-09-24).

A session belongs to the repo when it was launched in it or in one of its
worktrees under .claude/worktrees/, whose paths fold back into the repo's,
since only those sessions load its nested files. The session running this
is left out, by CLAUDE_CODE_SESSION_ID, since its own audit Reads every
instruction file; so are sessions named "probe: ...", unless --probes.

Only Read, Write, Edit and NotebookEdit calls count as working in a
folder. A README a prompt @-mentions, which arrives as a `file`
attachment, counts as opened first and named by the user; another file
mentioned is context, not work. A README viewed with a single-file `cat`
reads as never opened, and an edit made through Bash is not seen, so
README misses are an upper bound. A load is pinned to the call whose
result it follows, by the transcript's parentUuid links, so one beside
parallel calls can land on a sibling's result. A nested CLAUDE.md or
AGENTS.md that follows no file call here, as one an @-mention brings
does, is pinned to its own folder. A rule after a Bash call, which since
2.1.293 can load as a Read does, after another tool, after a file outside
the repo or after no call is pinned to no folder, and the summary counts
each kind: on this repo on 2026-10-15, 295 followed a Bash call.

It reads ~/.claude/projects/<project>/*.jsonl and each session's
subagents/ itself, though the docs call that format internal and liable
to change in any release (sessions page, 2026-10-15). The records keyed
on, as of 2.1.293: `cwd`, `version`, `uuid` and `parentUuid` on every
record; assistant `tool_use` blocks and user `tool_result` blocks;
`nested_memory` attachments for a nested CLAUDE.md or a rule,
`hook_additional_context` opening "Contents of ...AGENTS.md:" for a nested
AGENTS.md; and `compact_boundary` system records. When the format changes
this fails rather than reporting nothing: transcripts for the repo on disk
but no `cwd` or no message read from them exits 2. Exits 1 when no session
ran in the repo. It reaches back only as far as transcripts are kept,
cleanupPeriodDays, 30 days by default, and prints the day the oldest one
was written. No dependencies.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
from collections import Counter
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

FILE_TOOLS = {"Read": "file_path", "Write": "file_path", "Edit": "file_path",
              "NotebookEdit": "notebook_path"}
EDIT_TOOLS = {"Write", "Edit", "NotebookEdit"}
INSTRUCTION_NAMES = {"claude.md", "claude.local.md", "agents.md"}
AGENTS_CONTEXT = re.compile(r"Contents of (.+?AGENTS\.md):")
REMINDER = re.compile(r"<system-reminder>.*?</system-reminder>", re.S)
WORKTREES = ".claude/worktrees/"
MAX_HOPS = 8  # parentUuid steps from a load back to its tool result; 5 seen (2026-10-15)


@dataclass
class Touch:
    """One file call, or one instruction file that loaded after a file call."""
    order: int
    kind: str  # "read", "edit" or "load"
    rel: str  # the file's repo-relative key; for a load, the loaded file as shown
    after: str = ""  # for a load: the key of the file whose call it followed
    by_user: bool = False  # a read that is a prompt's @-mention, not Claude's choice


@dataclass
class Session:
    session_id: str
    cwd: str = ""
    name: str = ""
    versions: set[str] = field(default_factory=set)
    messages: int = 0
    compactions: int = 0
    unpinned: Counter = field(default_factory=Counter)  # why a load is pinned to no folder
    main: list[Touch] = field(default_factory=list)
    sub: list[Touch] = field(default_factory=list)
    prompts: list[tuple[int, str]] = field(default_factory=list)  # (order, folded text)


class Paths:
    """Spells every path one way and remembers how each was first written."""

    def __init__(self, root: Path) -> None:
        self.root = self.key(str(root))
        self.home = self.key(str(Path.home()))
        self.shown: dict[str, str] = {}

    @staticmethod
    def key(path: str) -> str:
        """Forward slashes, a /c/ drive as c:, case folded on Windows."""
        p = path.replace("\\", "/")
        if re.match(r"^/[a-zA-Z]/", p):
            p = f"{p[1]}:{p[2:]}"
        p = p.rstrip("/")
        return p.casefold() if os.name == "nt" else p

    def inside(self, path: str) -> bool:
        k = self.key(path)
        return k == self.root or k.startswith(self.root + "/")

    def relative(self, path: str) -> str | None:
        """The key relative to the repo, a worktree's prefix dropped; None outside it."""
        if not self.inside(path):
            return None
        rest = self.key(path)[len(self.root):].lstrip("/")
        written = path.replace("\\", "/").rstrip("/")
        written = written[len(written) - len(rest):] if rest else ""
        if rest.startswith(WORKTREES):
            rest = rest.split("/", 3)[3] if rest.count("/") >= 3 else ""
            written = written.split("/", 3)[3] if written.count("/") >= 3 else ""
        keys, words = rest.split("/"), written.split("/")
        if len(keys) == len(words):  # the folders too, so they print as written
            for i in range(1, len(keys) + 1):
                self.shown.setdefault("/".join(keys[:i]), "/".join(words[:i]))
        return rest

    def show(self, rel: str) -> str:
        return self.shown.get(rel, rel)

    def loaded(self, path: str) -> str:
        rel = self.relative(path)
        if rel is not None:
            return self.show(rel)
        written = path.replace("\\", "/")
        if self.key(path).startswith(self.home + "/"):
            return "~/" + written[len(self.home) + 1:]
        return written


def long_path(path: str) -> str:
    if os.name != "nt":
        return path
    import ctypes

    buf = ctypes.create_unicode_buffer(32768)
    n = ctypes.windll.kernel32.GetLongPathNameW(path, buf, len(buf))
    return buf.value if 0 < n < len(buf) else path


def repo_root(given: str | None) -> Path:
    if given:
        top = str(Path(given).resolve())
    else:
        try:
            top = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                                 text=True, check=True).stdout.strip()
        except (OSError, subprocess.CalledProcessError):
            top = os.getcwd()
    top = top.replace("\\", "/")
    if "/" + WORKTREES in top:  # a worktree's sessions are its repo's
        top = top.split("/" + WORKTREES)[0]
    return Path(long_path(top))


def project_dirs(projects: Path, root: Path) -> list[Path]:
    """The project directories a session in the repo can write to.

    Claude Code names one after the launch directory, "non-alphanumeric
    characters replaced by -" and cut at 200 with a hash (sessions page,
    2026-10-15), so the repo's own, its subfolders' and its worktrees' all
    start with the repo's name; the cwd check in main() drops the rest. The
    drive letter's case differs between them, c-- and C--, on Windows.
    """
    prefix = re.sub(r"[^A-Za-z0-9]", "-", str(root))[:200].casefold()
    try:
        return sorted(d for d in projects.iterdir()
                      if d.is_dir() and d.name.casefold().startswith(prefix))
    except OSError:
        return []


def texts_of(content: object) -> list[str]:
    if isinstance(content, str):
        return [content]
    if isinstance(content, list):
        return [b.get("text", "") for b in content
                if isinstance(b, dict) and b.get("type") == "text"]
    return []


def parse(path: Path, s: Session, into: list[Touch], paths: Paths, main: bool) -> None:
    """Add one transcript's file calls and the loads they caused to the session."""
    parents: dict[str, str] = {}  # uuid -> parentUuid
    results: dict[str, str] = {}  # uuid of a tool-result record -> its tool_use_id
    calls: dict[str, tuple[str, str]] = {}  # tool_use_id -> (tool, repo-relative key or "")
    with path.open(encoding="utf-8", errors="replace") as fh:
        for order, line in enumerate(fh):
            try:
                rec = json.loads(line)
            except ValueError:
                continue
            if not isinstance(rec, dict):
                continue
            kind = rec.get("type")
            uuid = rec.get("uuid")
            if isinstance(uuid, str) and isinstance(rec.get("parentUuid"), str):
                parents[uuid] = rec["parentUuid"]
            if main:
                s.cwd = s.cwd or rec.get("cwd") or ""
                if isinstance(rec.get("version"), str):
                    s.versions.add(rec["version"])
                if kind == "custom-title":
                    s.name = rec.get("customTitle") or s.name
            if kind == "system" and rec.get("subtype") == "compact_boundary" and main:
                s.compactions += 1
            elif kind == "user":
                s.messages += 1
                content = (rec.get("message") or {}).get("content")
                ids = []
                if isinstance(content, list):
                    ids = [b.get("tool_use_id") for b in content
                           if isinstance(b, dict) and b.get("type") == "tool_result"]
                if ids and isinstance(uuid, str):
                    results[uuid] = ids[0]
                elif main and not rec.get("isMeta") and not rec.get("isCompactSummary"):
                    for t in texts_of(content):
                        t = REMINDER.sub("", t).replace("\\", "/").casefold()
                        if t.strip():
                            s.prompts.append((order, t))
            elif kind == "assistant":
                s.messages += 1
                for b in (rec.get("message") or {}).get("content") or []:
                    if not (isinstance(b, dict) and b.get("type") == "tool_use"):
                        continue
                    arg = FILE_TOOLS.get(b.get("name", ""))
                    target = (b.get("input") or {}).get(arg) if arg else None
                    rel = paths.relative(target) if isinstance(target, str) else None
                    calls[b.get("id", "")] = (b.get("name", ""), rel or "")
                    if rel:
                        verb = "edit" if b["name"] in EDIT_TOOLS else "read"
                        into.append(Touch(order, verb, rel))
            elif kind == "attachment":
                a = rec.get("attachment") or {}
                if a.get("type") == "file" and isinstance(a.get("filename"), str):
                    rel = paths.relative(a["filename"])  # a prompt's @-mention puts it in context
                    if rel:
                        into.append(Touch(order, "read", rel, by_user=True))
                    continue
                loaded, call = None, a.get("toolUseID")
                if a.get("type") == "nested_memory" and isinstance(a.get("path"), str):
                    loaded = a["path"]
                elif a.get("type") == "hook_additional_context":
                    m = AGENTS_CONTEXT.search(str(a.get("content")))
                    loaded = m.group(1) if m else None
                if not loaded:
                    continue
                hop = rec.get("parentUuid")
                for _ in range(MAX_HOPS):
                    if call or not isinstance(hop, str):
                        break
                    call, hop = results.get(hop), parents.get(hop)
                tool, after = calls.get(call or "", ("", ""))
                own = paths.relative(loaded)
                if not after and own and own.rsplit("/", 1)[-1].casefold() in INSTRUCTION_NAMES:
                    after = own  # a nested file belongs to its own folder, whatever loaded it
                if after:
                    into.append(Touch(order, "load", paths.loaded(loaded), after))
                elif main:
                    s.unpinned["a file outside the repo" if tool in FILE_TOOLS
                               else tool or "no call"] += 1


def folders_of(rel: str, depth: int) -> list[str]:
    parts = rel.split("/")[:-1]
    return ["/".join(parts[:i]) for i in range(1, min(depth, len(parts)) + 1)]


@dataclass
class Folder:
    path: str
    readme: str | None = None
    instruction: list[str] = field(default_factory=list)
    worked: int = 0
    edited: int = 0
    subagent_only: int = 0
    compacted: int = 0
    first: int = 0
    named: int = 0
    later: int = 0
    never: int = 0
    loads: Counter = field(default_factory=Counter)


def describe(root: Path, rel: str) -> Folder:
    """A folder with the README and instruction files on disk in it now."""
    folder = Folder(rel)
    try:
        names = sorted(p.name for p in (root / rel).iterdir() if p.is_file())
    except OSError:
        return folder
    readmes = [n for n in names if n.casefold() == "readme.md"]
    folder.readme = f"{rel}/{readmes[0]}" if readmes else None
    folder.instruction = [n for n in names if n.casefold() in INSTRUCTION_NAMES]
    return folder


def tally(sessions: list[Session], root: Path, depth: int) -> dict[str, Folder]:
    out: dict[str, Folder] = {}
    for s in sessions:
        mine: dict[str, list[Touch]] = {}  # the session's own calls, by folder
        mentioned: dict[str, list[Touch]] = {}  # files a prompt @-mentioned, by folder
        for t in s.main:
            if t.kind != "load":
                for f in folders_of(t.rel, depth):
                    (mentioned if t.by_user else mine).setdefault(f, []).append(t)
        theirs = {f for t in s.sub if t.kind != "load" for f in folders_of(t.rel, depth)}
        for f in theirs - set(mine):
            out.setdefault(f, describe(root, f)).subagent_only += 1
        for f, touches in mine.items():
            folder = out.setdefault(f, describe(root, f))
            folder.worked += 1
            folder.edited += any(t.kind == "edit" for t in touches)
            folder.compacted += s.compactions > 0
            if folder.readme:
                key = folder.readme.casefold()
                reads = [t for t in touches if t.kind == "read" and t.rel.casefold() == key]
                handed = [t for t in mentioned.get(f, []) if t.rel.casefold() == key]
                mark = key.rsplit(".", 1)[0]  # "docs/readme" matches a path typed out
                if handed and handed[0].order <= touches[0].order:
                    folder.first += 1
                    folder.named += 1
                elif reads and reads[0] is touches[0]:
                    folder.first += 1
                    folder.named += any(o < reads[0].order and mark in p for o, p in s.prompts)
                elif reads or handed:
                    folder.later += 1
                else:
                    folder.never += 1
            folder.loads.update({t.rel for t in s.main
                                 if t.kind == "load" and f in folders_of(t.after, depth)})
    return out


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--repo", help="the repo's root (default: the git root of the working directory)")
    ap.add_argument("--folder", action="append", default=[],
                    help="only this folder and those under it; repeatable")
    ap.add_argument("--depth", type=int, default=3, help="deepest folder level counted (default 3)")
    ap.add_argument("--min", type=int, default=2,
                    help="fewest sessions a folder needs to be shown (default 2)")
    ap.add_argument("--limit", type=int, default=30, help="most folders to show (default 30)")
    ap.add_argument("--days", type=float, help="only transcripts written in the last N days")
    ap.add_argument("--probes", action="store_true", help='include sessions named "probe: ..."')
    ap.add_argument("--json", action="store_true", help="print the folders as JSON")
    args = ap.parse_args(argv)
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    root = repo_root(args.repo)
    paths = Paths(root)
    projects = Path(os.environ.get("CLAUDE_CONFIG_DIR") or Path.home() / ".claude") / "projects"
    asking = os.environ.get("CLAUDE_CODE_SESSION_ID")  # this audit's own Reads
    transcripts = [p for d in project_dirs(projects, root) for p in sorted(d.glob("*.jsonl"))
                   if p.stem != asking]
    if args.days is not None:
        cutoff = time.time() - args.days * 86400
        transcripts = [p for p in transcripts if p.stat().st_mtime >= cutoff]

    sessions: list[Session] = []
    any_cwd = False
    oldest = None
    for path in transcripts:
        s = Session(path.stem)
        parse(path, s, s.main, paths, main=True)
        any_cwd = any_cwd or bool(s.cwd)
        if not s.cwd or not paths.inside(s.cwd):
            continue
        if s.name.casefold().startswith("probe:") and not args.probes:
            continue
        for sub in sorted((path.parent / path.stem / "subagents").glob("*.jsonl")):
            parse(sub, s, s.sub, paths, main=False)
        sessions.append(s)
        mtime = path.stat().st_mtime
        oldest = mtime if oldest is None else min(oldest, mtime)

    if transcripts and (not any_cwd or (sessions and not any(s.messages for s in sessions))):
        print(f"error: read {len(transcripts)} transcripts for {root} and found no session "
              "directory or no message in them; the transcript format may have changed",
              file=sys.stderr)
        return 2
    if not sessions:
        print(f"no session under {projects} ran in {root}", file=sys.stderr)
        return 1

    folders = tally(sessions, root, args.depth)
    wanted = [Paths.key(w).strip("/") for w in args.folder]
    shown = [f for f in folders.values()
             if f.worked + f.subagent_only >= args.min
             and (not wanted or any(f.path == w or f.path.startswith(w + "/") for w in wanted))]
    shown.sort(key=lambda f: (-f.worked, f.path))
    shown = shown[:args.limit]
    versions = sorted({v for s in sessions for v in s.versions},
                      key=lambda v: [int(x) if x.isdigit() else 0 for x in v.split(".")])
    reach = datetime.fromtimestamp(oldest).strftime("%Y-%m-%d") if oldest else "?"
    span = f"versions {versions[0]} to {versions[-1]}" if versions else "no version recorded"
    unpinned: Counter = Counter()
    for s in sessions:
        unpinned.update(s.unpinned)

    if args.json:
        print(json.dumps({
            "repo": str(root), "sessions": len(sessions), "oldest_transcript": reach,
            "versions": versions, "unpinned_loads": dict(unpinned.most_common()),
            "folders": [{
                "folder": paths.show(f.path),
                "readme": paths.show(f.readme.casefold()) if f.readme else None,
                "instruction_files": f.instruction, "worked": f.worked, "edited": f.edited,
                "subagent_only": f.subagent_only, "compacted": f.compacted,
                "readme_opened": {"first": f.first, "first_named_by_user": f.named,
                                  "later": f.later, "never": f.never} if f.readme else None,
                "loaded": dict(f.loads.most_common()),
            } for f in shown],
        }, ensure_ascii=False, indent=2))
        return 0

    for f in shown:
        held = ([f.readme.rsplit("/", 1)[-1]] if f.readme else []) + f.instruction
        print(f"{paths.show(f.path)}/" + (f"  holds {', '.join(held)}" if held else ""))
        line = f"    sessions  {f.worked} working there, {f.edited} editing"
        if f.subagent_only:
            line += f", {f.subagent_only} more through a subagent only"
        print(f"{line}; {f.compacted} of the {f.worked} compacted")
        if f.readme:
            print(f"    README    {f.first} first ({f.named} of them named by the user), "
                  f"{f.later} later, {f.never} never")
        if f.loads:
            top = f.loads.most_common(4)
            more = f", {len(f.loads) - 4} more" if len(f.loads) > 4 else ""
            print("    loaded    " + ", ".join(f"{p} in {n}" for p, n in top) + more)
    why = ", ".join(f"{n} after {k}" for k, n in unpinned.most_common(4)) or "none"
    print(f"{len(shown)} of {len(folders)} folders shown, from {len(sessions)} sessions "
          f"in {root}; oldest transcript written {reach}; {span}.\n"
          f"Loads pinned to no folder: {why}. Only Read, Write and Edit count as work in a "
          "folder, so a README viewed by cat reads as never opened.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
