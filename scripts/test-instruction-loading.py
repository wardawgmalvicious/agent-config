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
CLAUDE.md, an import it expands or a `paths:` rule, and a PostToolUse
`hook_additional_context` for a nested AGENTS.md read directly -- which is
why InstructionsLoaded never logs one, and why a check keyed on
`nested_memory` alone misses it. A subagent's report reaches its parent as
a `queued_command` record, which can quote a file the subagent saw load,
so a marker there counts for nothing. Every instruction file carries a
`[[probe-marker <path>]]` line, so each load is attributed to its file and
to the step after which it arrived: launch, or a numbered step, where
`/compact` counts as one. A probe PASSes when those loads match its
expectation exactly, record kind included. It is INVALID when the model
did not make the tool calls it was told to, one at a time, which says
nothing about loading, and ERROR when no transcript turned up.

Written 2026-09-25 on 2.1.282 for the brief nested-instruction-files.md,
whose probes these are, kept at
`git show 92f8afc:docs/handoffs/execute/nested-instruction-files.md` since
docs/handoffs/execute/scope-instructions.md replaced it on 2026-10-15:
c0 and 1-8 answer its load-order questions, k0-k2 and h1 its question of
cutting a root CLAUDE.md over to AGENTS.md. r1, added 2026-10-15 on
2.1.293, checks claude/rules/agent-instructions-scoping.md's claim that a
`paths:` rule's @import loads at launch. The b- and ps- probes, added the
same day for the brief bash-reads-load-instructions.md, kept at
`git show 92f8afc:docs/handoffs/execute/bash-reads-load-instructions.md`,
check 2.1.293's changelog: a single-file cat, head, tail, sed -n or grep
in the Bash tool loads what a Read would. The d- probes, added the same
day for the brief nested-claude-md-misses.md, kept at
`git show e6c28bd:docs/handoffs/execute/nested-claude-md-misses.md`, run
on Windows only: a nested CLAUDE.md loads only on a path whose drive
letter is cased as the launch directory's, even once Bash respells the
cwd, and a `paths:` rule on either spelling. Re-run it after a CLI upgrade,
or when a changelog entry touches AGENTS.md or instruction loading: support
shipped in 2.1.277 and changed in 2.1.281. A FAIL means the loader changed,
and whatever was concluded from the probe may have changed with it.

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
import time
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
RELAYED = "queued_command"  # a subagent's report to its parent: never a load

COMPACT = "/compact"
SHELLS = ("Bash", "PowerShell")

# An "r" file is a rule scoped to RULE_GLOB; an "r@" one also imports RULE_IMPORT,
# probe-relative.
RULE_GLOB = "**/*.probe"
RULE_IMPORT = "docs/target.md"
RULE = ".claude/rules/probe.md"


@dataclass(frozen=True)
class Step:
    tool: str          # Read, Write, Grep, Glob, Bash, PowerShell, Agent, or /compact
    target: str = ""   # probe-relative; a directory for Grep and Glob
    command: str = ""  # a shell step's exact command; a Bash step without one cats target
    drive: str = ""    # "lower" or "upper": the case the prompt spells target's drive letter in


@dataclass(frozen=True)
class Probe:
    name: str
    question: str
    # path -> "i" instructions, "i@" plus @AGENTS.md, "r" or "r@" a rule (above), "t" text
    files: dict[str, str]
    steps: tuple[Step, ...]
    expect: dict[str, dict[str, str]]  # phase -> {file: record kind}
    cwd: str = "."
    settings: dict | None = None
    subagent: dict[str, dict[str, str]] | None = None
    order: tuple[str, ...] = ()  # files that must first load in this order
    worktree: str = ""  # a git worktree checked out here, with a CLAUDE.md of its own
    # The drive letter's case the transcript's cwd takes, in order, "lower" or "upper":
    # the session launches in the first, and a shell call may respell it.
    spellings: tuple[str, ...] = ()


def read(path: str, drive: str = "") -> Step:
    return Step("Read", path, drive=drive)


def spelled(path: pathlib.Path, drive: str) -> str:
    """The path with its drive letter in the case drive names; as it is for ""."""
    text = str(path)
    if drive and len(text) > 1 and text[1] == ":":
        text = (text[0].lower() if drive == "lower" else text[0].upper()) + text[1:]
    return text


def case_of(path: str) -> str:
    return "lower" if path[:1].islower() else "upper"


def view(name: str, question: str, command: str, *, loads: bool, tool: str = "Bash") -> Probe:
    """One shell command on a.probe, under a plain rule, alone in its session.

    One that should load nothing is followed by a Read, the control that the
    rule loads at all. b.probe is there for a command naming two files.
    """
    steps = (Step(tool, command=command),) + (() if loads else (read("a.probe"),))
    return Probe(name, question, {RULE: "r", "a.probe": "t", "b.probe": "t"}, steps,
                 {"1" if loads else "2": {RULE: NESTED}})


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
    Probe("p7", "7: a main-checkout Read inside .claude/worktrees/w1 loads no CLAUDE.md there",
          {"CLAUDE.md": "i", "sub/CLAUDE.md": "i", "sub/file.txt": "t", "top.txt": "t"},
          (read("sub/file.txt"), read(".claude/worktrees/w1/top.txt")),
          {"launch": {"CLAUDE.md": LAUNCH}, "1": {"sub/CLAUDE.md": NESTED}},
          worktree=".claude/worktrees/w1"),
    Probe("p7x", "7: claudeMdExcludes **/.claude/worktrees/** changes nothing p7 sees",
          {"CLAUDE.md": "i", "sub/CLAUDE.md": "i", "sub/file.txt": "t", "top.txt": "t"},
          (read("sub/file.txt"), read(".claude/worktrees/w1/top.txt")),
          {"launch": {"CLAUDE.md": LAUNCH}, "1": {"sub/CLAUDE.md": NESTED}},
          settings={"claudeMdExcludes": ["**/.claude/worktrees/**"]},
          worktree=".claude/worktrees/w1"),
    Probe("p7-wt", "7: launched in the worktree, its own CLAUDE.md loads and the main root's does not",
          {"CLAUDE.md": "i", "sub/CLAUDE.md": "i", "sub/file.txt": "t", "top.txt": "t"},
          (read(".claude/worktrees/w1/top.txt"),),
          {"launch": {".claude/worktrees/w1/CLAUDE.md": LAUNCH}},
          cwd=".claude/worktrees/w1", worktree=".claude/worktrees/w1"),
    Probe("p7-wt-x", "7: launched in the worktree, that exclude drops its own CLAUDE.md too",
          {"CLAUDE.md": "i", "sub/CLAUDE.md": "i", "sub/file.txt": "t", "top.txt": "t"},
          (read(".claude/worktrees/w1/top.txt"),),
          {},
          settings={"claudeMdExcludes": ["**/.claude/worktrees/**"]},
          cwd=".claude/worktrees/w1", worktree=".claude/worktrees/w1"),
    Probe("p8", "8: a Write or Bash cat loads a nested CLAUDE.md, Grep and Glob none; a Read does",
          {"CLAUDE.md": "i", "w/CLAUDE.md": "i", "g/CLAUDE.md": "i", "g/data.txt": "t",
           "gl/CLAUDE.md": "i", "gl/x.txt": "t", "b/CLAUDE.md": "i", "b/y.txt": "t"},
          (Step("Write", "w/new.txt"), Step("Grep", "g"), Step("Glob", "gl"),
           Step("Bash", "b/y.txt"), read("w/new.txt"), read("g/data.txt"),
           read("gl/x.txt"), read("b/y.txt")),
          {"launch": {"CLAUDE.md": LAUNCH}, "1": {"w/CLAUDE.md": NESTED},
           "4": {"b/CLAUDE.md": NESTED}, "6": {"g/CLAUDE.md": NESTED},
           "7": {"gl/CLAUDE.md": NESTED}}),
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
    Probe("r1", "rule: a paths: rule's @import loads at launch, the rule on a matching Read",
          {RULE: "r@", "docs/target.md": "i", "sample.probe": "t"},
          (read("sample.probe"),),
          {"launch": {"docs/target.md": LAUNCH}, "1": {RULE: NESTED}}),
    view("b-cat", "view: a Bash cat of one file loads the rule a Read would",
         "cat a.probe", loads=True),
    view("b-head", "view: so does head -n 1", "head -n 1 a.probe", loads=True),
    view("b-sed", "view: so does sed -n '1,1p'", "sed -n '1,1p' a.probe", loads=True),
    view("b-grep", "view: so does a grep that matches", "grep plain a.probe", loads=True),
    view("b-grep0", "view: a grep matching nothing loads nothing; a Read then does",
         "grep zzz a.probe", loads=False),
    view("b-pipe", "view: a cat piped to head loads nothing; a Read then does",
         "cat a.probe | head -n 1", loads=False),
    view("b-two", "view: a cat of two files loads nothing; a Read then does",
         "cat a.probe b.probe", loads=False),
    view("b-edit", "view: a sed -i edit loads nothing; a Read then does",
         "sed -i 's/plain/flat/' a.probe", loads=False),
    Probe("b-nest", "view: a Bash cat of a file in sub/ loads sub/CLAUDE.md",
          {"sub/CLAUDE.md": "i", "sub/x.txt": "t"},
          (Step("Bash", command="cat sub/x.txt"),),
          {"1": {"sub/CLAUDE.md": NESTED}}),
    view("ps-get", "view: a PowerShell Get-Content, outside the set, loads nothing; a Read does",
         "Get-Content a.probe", loads=False, tool="PowerShell"),
)

if os.name == "nt":  # only a Windows path has a drive letter to spell
    PROBES += (
        Probe("d1", "drive: launched at c:\\, a Read spelled C:\\ loads no nested file, c:\\ does",
              {"CLAUDE.md": "i", "sub/CLAUDE.md": "i", "sub/one.txt": "t", "sub/two.txt": "t"},
              (read("sub/one.txt", "upper"), read("sub/two.txt", "lower")),
              {"launch": {"CLAUDE.md": LAUNCH}, "2": {"sub/CLAUDE.md": NESTED}},
              spellings=("lower",)),
        Probe("d2", "drive: launched at C:\\, a Read spelled c:\\ loads none either, C:\\ does",
              {"CLAUDE.md": "i", "sub/CLAUDE.md": "i", "sub/one.txt": "t", "sub/two.txt": "t"},
              (read("sub/one.txt", "lower"), read("sub/two.txt", "upper")),
              {"launch": {"CLAUDE.md": LAUNCH}, "2": {"sub/CLAUDE.md": NESTED}},
              spellings=("upper",)),
        Probe("d3", "drive: launched at c:\\, a paths: rule loads on a Read spelled C:\\",
              {RULE: "r", "a.probe": "t"},
              (read("a.probe", "upper"),),
              {"1": {RULE: NESTED}},
              spellings=("lower",)),
        Probe("d4", "drive: once Bash respells the cwd C:\\, a C:\\ Read still misses, c:\\ loads",
              {"CLAUDE.md": "i", "sub/CLAUDE.md": "i", "sub/one.txt": "t", "sub/two.txt": "t"},
              (Step("Bash", command="pwd"), read("sub/one.txt", "upper"),
               read("sub/two.txt", "lower")),
              {"launch": {"CLAUDE.md": LAUNCH}, "3": {"sub/CLAUDE.md": NESTED}},
              spellings=("lower", "upper")),
        Probe("d5", "drive: launched at c:\\, a nested AGENTS.md misses a C:\\ Read too, c:\\ loads",
              {"AGENTS.md": "i", "sub/AGENTS.md": "i", "sub/one.txt": "t", "sub/two.txt": "t"},
              (read("sub/one.txt", "upper"), read("sub/two.txt", "lower")),
              {"launch": {"AGENTS.md": LAUNCH}, "2": {"sub/AGENTS.md": HOOK}},
              spellings=("lower",)),
    )


@dataclass
class Observed:
    loads: dict[str, dict[str, str]] = field(default_factory=dict)  # phase -> {file: kind}
    order: list[str] = field(default_factory=list)  # files in first-load order
    calls: list[tuple[str, dict]] = field(default_factory=list)  # (tool, input)
    parallel: bool = False  # a call made before the previous one's result, so unattributable
    cwds: list[str] = field(default_factory=list)  # the cwd's drive case, at each change


def build(root: pathlib.Path, probe: Probe) -> pathlib.Path:
    base = root / probe.name
    for rel, kind in probe.files.items():
        text = "plain probe file, no instructions\n"
        if kind.startswith("i"):
            text = f"[[probe-marker {rel}]]\n" + ("\n@AGENTS.md\n" if kind == "i@" else "")
        elif kind.startswith("r"):
            up = "../" * len(pathlib.PurePosixPath(rel).parent.parts)
            text = (f'---\npaths:\n  - "{RULE_GLOB}"\n---\n\n[[probe-marker {rel}]]\n'
                    + (f"\n@{up}{RULE_IMPORT}\n" if kind == "r@" else ""))
        elif rel.endswith("data.txt"):
            text = "needle\n"
        path = base / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(text.encode("utf-8"))
    subprocess.run(["git", "init", "-q", str(base)], check=True)
    if probe.worktree:
        add_worktree(base, probe.worktree)
    return base


def add_worktree(base: pathlib.Path, rel: str) -> None:
    """Commit the probe's files, then check them out again as a worktree at rel.

    The layout `claude --worktree` makes, ignored as agent-config ignores it,
    by `/.claude/*` in .gitignore. The checkout copies root's CLAUDE.md, marker
    and all, so the worktree's copy is re-marked with its own path: a second,
    possibly different copy of root, as another branch checked out there is.
    """
    (base / ".gitignore").write_bytes(b"/.claude/*\n")
    git = ["git", "-C", str(base), "-c", "user.name=probe", "-c", "user.email=probe@example.invalid"]
    subprocess.run([*git, "add", "-A"], check=True)
    subprocess.run([*git, "commit", "-q", "-m", "probe"], check=True)
    subprocess.run([*git, "worktree", "add", "-q", "-b", "probe-worktree", rel], check=True)
    (base / rel / "CLAUDE.md").write_bytes(f"[[probe-marker {rel}/CLAUDE.md]]\n".encode("utf-8"))


def step_line(n: int, step: Step, base: pathlib.Path) -> str:
    target = base / step.target
    shown = spelled(target, step.drive)
    if step.tool == "Read":
        return f"{n}. Read tool: {shown}"
    if step.tool == "Write":
        return f"{n}. Write tool: create {shown} containing the single line: probe"
    if step.tool == "Grep":
        return f"{n}. Grep tool: pattern needle, path {shown}, output_mode files_with_matches"
    if step.tool == "Glob":
        return f"{n}. Glob tool: pattern *.txt, path {shown}"
    if step.tool in SHELLS and step.command:
        return f"{n}. {step.tool} tool, exactly this command and nothing else: {step.command}"
    if step.tool == "Bash":
        return f"{n}. Bash tool: cat '{target.as_posix()}'"
    if step.tool == "Agent":
        return (f'{n}. Agent tool with subagent_type general-purpose, giving the subagent '
                f'exactly this task: "Use the Read tool on {shown} and reply with its '
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
            # No text between steps: a message of text alone ends a -p turn, which
            # cut p8 short at "done 1" on 2026-10-15.
            lines = "\n".join(step_line(n, step, base) for n, step in seg)
            prompt = ("Do exactly these steps, in order, one tool call per step. Make each "
                      "call alone and wait for its result before the next, and write no text "
                      "until every step is done. Use only the tool each step names, and do "
                      f"not comment on any output.\n\n{lines}\n\n"
                      "When every step is done, reply with just: ok")
        session = ["--session-id", sid] if i == 0 else ["--resume", sid]
        cwd = spelled(base / probe.cwd, probe.spellings[0] if probe.spellings else "")
        try:
            subprocess.run([claude, "-p", prompt, *common, *session], cwd=cwd,
                           env=cold_env(), capture_output=True, text=True, encoding="utf-8",
                           errors="replace", timeout=300)
        except subprocess.TimeoutExpired:
            break  # judged on whatever transcript exists: INVALID or ERROR, never PASS
    return sid


def observe(transcript: pathlib.Path) -> Observed:
    """Attribute every marked load to the latest step started before it arrived."""
    seen = Observed()
    phase, started, unanswered = "launch", 0, 0
    for line in transcript.read_text(encoding="utf-8").splitlines():
        try:
            rec = json.loads(line)
        except json.JSONDecodeError:
            continue
        kind = rec.get("type")
        cwd = rec.get("cwd")
        if isinstance(cwd, str) and cwd and (not seen.cwds or seen.cwds[-1] != case_of(cwd)):
            seen.cwds.append(case_of(cwd))
        if kind == "system" and rec.get("subtype") == "compact_boundary":
            started += 1
            phase = str(started)
        elif kind == "assistant":
            for item in rec.get("message", {}).get("content") or []:
                if item.get("type") == "tool_use":
                    seen.parallel |= unanswered > 0
                    unanswered += 1
                    started += 1
                    phase = str(started)
                    seen.calls.append((item.get("name", ""), item.get("input", {})))
        elif kind == "user":
            content = rec.get("message", {}).get("content")
            if isinstance(content, list):
                unanswered -= sum(item.get("type") == "tool_result" for item in content)
        elif kind == "attachment":
            att_kind = rec.get("attachment", {}).get("type", "")
            if att_kind == RELAYED:
                continue
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
        if step.drive and args.get("file_path", "")[:1] != spelled(target, step.drive)[:1]:
            return False
        if name in ("Grep", "Glob") and not same(args.get("path", ""), target):
            return False
        if name in SHELLS:
            command = args.get("command", "")
            if step.command and command.strip() != step.command:
                return False
            if not step.command and target.as_posix() not in command:
                return False
    return True


def described(calls: list[tuple[str, dict]]) -> list[str]:
    return [f"{name} {args['command']!r}" if "command" in args else name for name, args in calls]


def judge(root: pathlib.Path, probe: Probe, sid: str) -> tuple[str, list[str]]:
    base = root / probe.name
    mains = list(PROJECTS.glob(f"*/{sid}.jsonl"))
    if not mains:
        return "ERROR", [f"no transcript {sid}.jsonl under {PROJECTS}"]
    seen = observe(mains[0])
    detail = [f"session {sid}"] + [f"{p}: {seen.loads[p]}" for p in seen.loads]
    tool_steps = [s for s in probe.steps if s.tool != COMPACT]
    if seen.parallel or not calls_match(seen.calls, tool_steps, base):
        at_once = ", some at once" if seen.parallel else ""
        return "INVALID", detail + [f"tool calls{at_once}: {described(seen.calls)}"]
    if probe.spellings:
        detail.append(f"cwd's drive letter: {' then '.join(seen.cwds)}")
        if tuple(seen.cwds) != probe.spellings:
            return "INVALID", detail + [f"expected the cwd's: {' then '.join(probe.spellings)}"]
    ok = seen.loads == probe.expect
    if probe.order:
        ok &= [f for f in seen.order if f in probe.order] == list(probe.order)
    if probe.subagent is not None:
        subs = sorted(PROJECTS.glob(f"*/{sid}/subagents/*.jsonl"))
        sub = observe(subs[0]) if subs else Observed()
        # In auto mode a subagent hands its report back with a call of its own (2.1.271).
        calls = [c for c in sub.calls if c[0] != "SubagentHandback"]
        if sub.parallel or not calls_match(calls, [read(probe.steps[0].target)], base):
            return "INVALID", detail + [f"subagent tool calls: {described(sub.calls)}"]
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

    # A session's child process can hold its directory after the session exits:
    # b-sed's in two of three runs on 2026-10-15, once past these retries.
    for wait in (2, 5, 10, 20, 0):
        try:
            shutil.rmtree(path, onexc=writable)
            return
        except PermissionError as exc:
            if not wait:
                print(f"left {path}: {exc}", file=sys.stderr)
                return
            time.sleep(wait)


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
