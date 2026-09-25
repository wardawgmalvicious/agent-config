#!/usr/bin/env python3
"""Probe how Claude Code loads CLAUDE.md and AGENTS.md, and check the answers.

    uv run scripts/test-instruction-loading.py              # every probe
    uv run scripts/test-instruction-loading.py c0 p4        # named probes only
    uv run scripts/test-instruction-loading.py --list       # the probes, no sessions
    uv run scripts/test-instruction-loading.py --keep -v    # keep the tree, print every load

Each probe builds a small git repo in a scratch directory, runs cold
`claude -p --model haiku` sessions in it, and reads the session transcript,
the only complete witness of what loaded. Three records carry a load: the
launch `instructions` record, a `nested_memory` attachment for a nested
CLAUDE.md or an import it expands, and a PostToolUse
`hook_additional_context` for a nested AGENTS.md read directly -- which is
why InstructionsLoaded never logs one, and why a check keyed on
`nested_memory` alone misses it. Every instruction file carries a
`[[probe-marker <path>]]` line, so each load is attributed to its file and
to the step after which it arrived: launch, or a numbered step, where
`/compact` counts as one. A probe PASSes when those loads match its
expectation exactly, record kind included. It is INVALID when the model
did not make the tool calls it was told to, which says nothing about
loading, and ERROR when no transcript turned up.

Written 2026-09-25 on 2.1.282 for
docs/handoffs/execute/nested-instruction-files.md, whose probes these are:
c0 and 1-8 answer its load-order questions, k0-k2 and h1 its question of
cutting a root CLAUDE.md over to AGENTS.md. Re-run it after a CLI upgrade,
or when a changelog entry touches AGENTS.md or instruction loading: support
shipped in 2.1.277 and changed in 2.1.281. A FAIL means the loader changed,
and whatever that brief concluded from the probe may have changed with it.

The scratch root sits under the system temp directory, and the run refuses
if any directory above it holds an instruction file other than
~/.claude/CLAUDE.md, which c0 shows does not count. Sessions start without
the launching session's CLAUDE* variables, tools pinned by --tools, about
0.03 USD each, three at a time. Their transcripts stay under
~/.claude/projects until cleanupPeriodDays removes them. Stdlib only.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import json
import os
import pathlib
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import uuid
from dataclasses import dataclass, field

MARK = re.compile(r"\[\[probe-marker ([^\]]+)\]\]")
PROJECTS = pathlib.Path.home() / ".claude" / "projects"
USER_CLAUDE_MD = pathlib.Path.home() / ".claude" / "CLAUDE.md"
INSTRUCTION_NAMES = ("CLAUDE.md", "CLAUDE.local.md", ".claude/CLAUDE.md",
                     "AGENTS.md", ".claude/AGENTS.md")

# Record kinds, as the transcript names the attachment carrying a load.
LAUNCH = "instructions"
NESTED = "nested_memory"
HOOK = "hook_additional_context"

COMPACT = "/compact"


@dataclass(frozen=True)
class Step:
    tool: str         # Read, Write, Grep, Glob, Bash, Agent, or /compact
    target: str = ""  # probe-relative; a directory for Grep and Glob


@dataclass(frozen=True)
class Probe:
    name: str
    question: str
    files: dict[str, str]  # path -> "i" instructions, "i@" plus @AGENTS.md, "t" text
    steps: tuple[Step, ...]
    expect: dict[str, dict[str, str]]  # phase -> {file: record kind}
    cwd: str = "."
    settings: dict | None = None
    subagent: dict[str, dict[str, str]] | None = None
    order: tuple[str, ...] = ()  # files that must first load in this order


def read(path: str) -> Step:
    return Step("Read", path)


PROBES = (
    Probe("c0", "control: with no CLAUDE.md, AGENTS.md loads, a nested one by hook",
          {"AGENTS.md": "i", "sub/AGENTS.md": "i", "sub/file.txt": "t"},
          (read("sub/file.txt"),),
          {"launch": {"AGENTS.md": LAUNCH}, "1": {"sub/AGENTS.md": HOOK}}),
    Probe("p1", "1: a root CLAUDE.md silences every AGENTS.md, nested ones included",
          {"CLAUDE.md": "i", "AGENTS.md": "i", "sub/AGENTS.md": "i", "sub/file.txt": "t"},
          (read("sub/file.txt"),),
          {"launch": {"CLAUDE.md": LAUNCH}}),
    Probe("p2-sub", "2: launched in sub/, its CLAUDE.md drops root's AGENTS.md",
          {"AGENTS.md": "i", "sub/CLAUDE.md": "i", "sub/file.txt": "t", "top.txt": "t"},
          (read("sub/file.txt"), read("top.txt")),
          {"launch": {"sub/CLAUDE.md": LAUNCH}}, cwd="sub"),
    Probe("p2-root", "2: launched at root, AGENTS.md and a nested CLAUDE.md both load",
          {"AGENTS.md": "i", "sub/CLAUDE.md": "i", "sub/file.txt": "t"},
          (read("sub/file.txt"),),
          {"launch": {"AGENTS.md": LAUNCH}, "1": {"sub/CLAUDE.md": NESTED}}),
    Probe("p3", "3: an @AGENTS.md import loads, and a nested AGENTS.md stays silent",
          {"CLAUDE.md": "i@", "AGENTS.md": "i", "sub/AGENTS.md": "i", "sub/file.txt": "t"},
          (read("sub/file.txt"),),
          {"launch": {"CLAUDE.md": LAUNCH, "AGENTS.md": LAUNCH}}),
    Probe("p4", "4: a CLAUDE.md that claudeMdExcludes skips does not count",
          {"CLAUDE.md": "i", "AGENTS.md": "i", "sub/AGENTS.md": "i", "sub/file.txt": "t"},
          (read("sub/file.txt"),),
          {"launch": {"AGENTS.md": LAUNCH}, "1": {"sub/AGENTS.md": HOOK}},
          settings={"claudeMdExcludes": ["**/p4/CLAUDE.md"]}),
    Probe("p5", "5: two nested levels load on one Read in the deeper, outer first",
          {"CLAUDE.md": "i", "a/CLAUDE.md": "i", "a/b/CLAUDE.md": "i",
           "a/b/file.txt": "t", "a/file.txt": "t"},
          (read("a/b/file.txt"), read("a/file.txt")),
          {"launch": {"CLAUDE.md": LAUNCH},
           "1": {"a/CLAUDE.md": NESTED, "a/b/CLAUDE.md": NESTED}},
          order=("a/CLAUDE.md", "a/b/CLAUDE.md")),
    Probe("p6", "6: a subagent's Read loads a nested file into the subagent only",
          {"CLAUDE.md": "i", "sub/CLAUDE.md": "i", "sub/one.txt": "t", "sub/two.txt": "t"},
          (Step("Agent", "sub/one.txt"), read("sub/two.txt")),
          {"launch": {"CLAUDE.md": LAUNCH}, "2": {"sub/CLAUDE.md": NESTED}},
          subagent={"launch": {"CLAUDE.md": LAUNCH}, "1": {"sub/CLAUDE.md": NESTED}}),
    Probe("p8", "8: Write, Grep, Glob and Bash load no nested CLAUDE.md; a Read does",
          {"CLAUDE.md": "i", "w/CLAUDE.md": "i", "g/CLAUDE.md": "i", "g/data.txt": "t",
           "gl/CLAUDE.md": "i", "gl/x.txt": "t", "b/CLAUDE.md": "i", "b/y.txt": "t"},
          (Step("Write", "w/new.txt"), Step("Grep", "g"), Step("Glob", "gl"),
           Step("Bash", "b/y.txt"), read("w/new.txt"), read("g/data.txt"),
           read("gl/x.txt"), read("b/y.txt")),
          {"launch": {"CLAUDE.md": LAUNCH}, "5": {"w/CLAUDE.md": NESTED},
           "6": {"g/CLAUDE.md": NESTED}, "7": {"gl/CLAUDE.md": NESTED},
           "8": {"b/CLAUDE.md": NESTED}}),
    Probe("k0", "cutover baseline: CLAUDE.md, root and nested, returns after /compact",
          {"CLAUDE.md": "i", "sub/CLAUDE.md": "i", "sub/one.txt": "t", "sub/two.txt": "t"},
          (read("sub/one.txt"), Step(COMPACT), read("sub/two.txt")),
          {"launch": {"CLAUDE.md": LAUNCH}, "1": {"sub/CLAUDE.md": NESTED},
           "2": {"CLAUDE.md": LAUNCH}, "3": {"sub/CLAUDE.md": NESTED}}),
    Probe("k1", "cutover: AGENTS.md alone, root and nested, returns after /compact",
          {"AGENTS.md": "i", "sub/AGENTS.md": "i", "sub/one.txt": "t", "sub/two.txt": "t"},
          (read("sub/one.txt"), Step(COMPACT), read("sub/two.txt")),
          {"launch": {"AGENTS.md": LAUNCH}, "1": {"sub/AGENTS.md": HOOK},
           "2": {"AGENTS.md": LAUNCH}, "3": {"sub/AGENTS.md": HOOK}}),
    Probe("k2", "cutover: a CLAUDE.md of @AGENTS.md at each level loads both, and after /compact",
          {"CLAUDE.md": "i@", "AGENTS.md": "i", "sub/CLAUDE.md": "i@", "sub/AGENTS.md": "i",
           "sub/one.txt": "t", "sub/two.txt": "t"},
          (read("sub/one.txt"), Step(COMPACT), read("sub/two.txt")),
          {"launch": {"CLAUDE.md": LAUNCH, "AGENTS.md": LAUNCH},
           "1": {"sub/CLAUDE.md": NESTED, "sub/AGENTS.md": NESTED},
           "2": {"CLAUDE.md": LAUNCH, "AGENTS.md": LAUNCH},
           "3": {"sub/CLAUDE.md": NESTED, "sub/AGENTS.md": NESTED}}),
    Probe("h1", "cutover: disableAllHooks does not silence a nested AGENTS.md",
          {"AGENTS.md": "i", "sub/AGENTS.md": "i", "sub/file.txt": "t"},
          (read("sub/file.txt"),),
          {"launch": {"AGENTS.md": LAUNCH}, "1": {"sub/AGENTS.md": HOOK}},
          settings={"disableAllHooks": True}),
)


@dataclass
class Observed:
    loads: dict[str, dict[str, str]] = field(default_factory=dict)  # phase -> {file: kind}
    order: list[str] = field(default_factory=list)  # files in first-load order
    calls: list[tuple[str, dict]] = field(default_factory=list)  # (tool, input)


def build(root: pathlib.Path, probe: Probe) -> pathlib.Path:
    base = root / probe.name
    for rel, kind in probe.files.items():
        text = "plain probe file, no instructions\n"
        if kind.startswith("i"):
            text = f"[[probe-marker {rel}]]\n" + ("\n@AGENTS.md\n" if kind == "i@" else "")
        elif rel.endswith("data.txt"):
            text = "needle\n"
        path = base / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(text.encode("utf-8"))
    subprocess.run(["git", "init", "-q", str(base)], check=True)
    return base


def step_line(n: int, step: Step, base: pathlib.Path) -> str:
    target = base / step.target
    if step.tool == "Read":
        return f"{n}. Read tool: {target}"
    if step.tool == "Write":
        return f"{n}. Write tool: create {target} containing the single line: probe"
    if step.tool == "Grep":
        return f"{n}. Grep tool: pattern needle, path {target}, output_mode files_with_matches"
    if step.tool == "Glob":
        return f"{n}. Glob tool: pattern *.txt, path {target}"
    if step.tool == "Bash":
        return f"{n}. Bash tool: cat '{target.as_posix()}'"
    if step.tool == "Agent":
        return (f'{n}. Agent tool with subagent_type general-purpose, giving the subagent '
                f'exactly this task: "Use the Read tool on {target} and reply with its '
                'contents verbatim. Use no other tool." Do not read that file yourself.')
    raise ValueError(f"unknown step tool {step.tool}")


def segments(probe: Probe) -> list[list[tuple[int, Step]]]:
    """Split the steps into one list per claude process, a /compact alone in its own."""
    out: list[list[tuple[int, Step]]] = [[]]
    for n, step in enumerate(probe.steps, 1):
        if step.tool == COMPACT:
            out += [[(n, step)], []]
        else:
            out[-1].append((n, step))
    return [seg for seg in out if seg]


def cold_env() -> dict[str, str]:
    # Without the launching session's identity, messaging socket and effort,
    # each probe is a fresh session rather than a child of this one.
    return {k: v for k, v in os.environ.items()
            if not k.upper().startswith("CLAUDE") and k.upper() != "MCP_CONNECTION_NONBLOCKING"}


def run_probe(root: pathlib.Path, probe: Probe, claude: str) -> str:
    base = build(root, probe)
    sid = str(uuid.uuid4())
    tools = sorted({"Read"} | {s.tool for s in probe.steps if s.tool != COMPACT})
    common = ["--model", "haiku", "--output-format", "json", "--strict-mcp-config",
              "--tools", ",".join(tools), "--allowedTools", *tools]
    if probe.settings:
        settings = root / f"{probe.name}.settings.json"
        settings.write_text(json.dumps(probe.settings), encoding="utf-8")
        common += ["--settings", str(settings)]
    for i, seg in enumerate(segments(probe)):
        if seg[0][1].tool == COMPACT:
            prompt = COMPACT
        else:
            lines = "\n".join(step_line(n, step, base) for n, step in seg)
            prompt = ("Do exactly these steps, in order, one tool call per step. After each "
                      'step print the line "done N" with its number, and only then start the '
                      "next. Use only the tool each step names, and do not comment on any "
                      f"output.\n\n{lines}\n\nWhen every step is done, reply with just: ok")
        session = ["--session-id", sid] if i == 0 else ["--resume", sid]
        try:
            subprocess.run([claude, "-p", prompt, *common, *session], cwd=base / probe.cwd,
                           env=cold_env(), capture_output=True, text=True, encoding="utf-8",
                           errors="replace", timeout=300)
        except subprocess.TimeoutExpired:
            break  # judged on whatever transcript exists: INVALID or ERROR, never PASS
    return sid


def observe(transcript: pathlib.Path) -> Observed:
    """Attribute every marked load to the latest step started before it arrived."""
    seen = Observed()
    phase, started = "launch", 0
    for line in transcript.read_text(encoding="utf-8").splitlines():
        try:
            rec = json.loads(line)
        except json.JSONDecodeError:
            continue
        kind = rec.get("type")
        if kind == "system" and rec.get("subtype") == "compact_boundary":
            started += 1
            phase = str(started)
        elif kind == "assistant":
            for item in rec.get("message", {}).get("content") or []:
                if item.get("type") == "tool_use":
                    started += 1
                    phase = str(started)
                    seen.calls.append((item.get("name", ""), item.get("input", {})))
        elif kind == "attachment":
            att_kind = rec.get("attachment", {}).get("type", "")
            for rel in MARK.findall(line):
                seen.loads.setdefault(phase, {})[rel] = att_kind
                if rel not in seen.order:
                    seen.order.append(rel)
    return seen


def calls_match(calls: list[tuple[str, dict]], steps: list[Step], base: pathlib.Path) -> bool:
    def same(a: str, b: pathlib.Path) -> bool:
        return os.path.normcase(os.path.normpath(a)) == os.path.normcase(os.path.normpath(b))

    if len(calls) != len(steps):
        return False
    for (name, args), step in zip(calls, steps):
        target = base / step.target
        if name != step.tool:
            return False
        if name in ("Read", "Write") and not same(args.get("file_path", ""), target):
            return False
        if name in ("Grep", "Glob") and not same(args.get("path", ""), target):
            return False
        if name == "Bash" and target.as_posix() not in args.get("command", ""):
            return False
    return True


def judge(root: pathlib.Path, probe: Probe, sid: str) -> tuple[str, list[str]]:
    base = root / probe.name
    mains = list(PROJECTS.glob(f"*/{sid}.jsonl"))
    if not mains:
        return "ERROR", [f"no transcript {sid}.jsonl under {PROJECTS}"]
    seen = observe(mains[0])
    detail = [f"session {sid}"] + [f"{p}: {seen.loads[p]}" for p in seen.loads]
    tool_steps = [s for s in probe.steps if s.tool != COMPACT]
    if not calls_match(seen.calls, tool_steps, base):
        return "INVALID", detail + [f"tool calls: {[c[0] for c in seen.calls]}"]
    ok = seen.loads == probe.expect
    if probe.order:
        ok &= [f for f in seen.order if f in probe.order] == list(probe.order)
    if probe.subagent is not None:
        subs = sorted(PROJECTS.glob(f"*/{sid}/subagents/*.jsonl"))
        sub = observe(subs[0]) if subs else Observed()
        if not calls_match(sub.calls, [read(probe.steps[0].target)], base):
            return "INVALID", detail + [f"subagent tool calls: {[c[0] for c in sub.calls]}"]
        detail += [f"subagent {p}: {sub.loads[p]}" for p in sub.loads]
        ok &= sub.loads == probe.subagent
    if not ok:
        detail += [f"expected {p}: {probe.expect[p]}" for p in probe.expect]
        if probe.subagent:
            detail += [f"expected subagent {p}: {probe.subagent[p]}" for p in probe.subagent]
    return ("PASS" if ok else "FAIL"), detail


def stray_instruction_files(root: pathlib.Path) -> list[pathlib.Path]:
    found = []
    for directory in root.parents:
        for name in INSTRUCTION_NAMES:
            path = directory / name
            if path.is_file() and path.resolve() != USER_CLAUDE_MD.resolve():
                found.append(path)
    return found


def remove_tree(path: pathlib.Path) -> None:
    def writable(func, target, _exc) -> None:  # git leaves read-only objects behind
        os.chmod(target, stat.S_IWRITE)
        func(target)

    shutil.rmtree(path, onexc=writable)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("names", nargs="*", help="probe names; default every probe")
    parser.add_argument("--list", action="store_true", help="list the probes and exit")
    parser.add_argument("--keep", action="store_true", help="keep the scratch tree")
    parser.add_argument("-v", "--verbose", action="store_true", help="print every load")
    args = parser.parse_args()

    unknown = set(args.names) - {p.name for p in PROBES}
    if unknown:
        parser.error(f"unknown probe(s): {', '.join(sorted(unknown))}")
    probes = [p for p in PROBES if not args.names or p.name in args.names]
    if args.list:
        for p in probes:
            print(f"{p.name:8} {p.question}")
        return 0

    claude = shutil.which("claude")
    if not claude:
        print("claude is not on PATH", file=sys.stderr)
        return 2
    root = pathlib.Path(tempfile.mkdtemp(prefix="instruction-probes-")).resolve()
    stray = stray_instruction_files(root)
    if stray:
        remove_tree(root)
        print(f"refusing: instruction files above the scratch root would confound: {stray}",
              file=sys.stderr)
        return 2
    version = subprocess.run([claude, "--version"], capture_output=True, text=True).stdout
    print(f"claude {version.strip()}; scratch {root}")

    failures = 0
    try:
        with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
            sids = {p.name: pool.submit(run_probe, root, p, claude) for p in probes}
            for p in probes:
                verdict, detail = judge(root, p, sids[p.name].result())
                failures += verdict != "PASS"
                print(f"{verdict:8} {p.name:8} {p.question}")
                if verdict != "PASS" or args.verbose:
                    for line in detail:
                        print(f"{'':17} {line}")
    finally:
        if args.keep:
            print(f"kept {root}")
        else:
            remove_tree(root)
    print(f"{len(probes)} probes, {len(probes) - failures} passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
