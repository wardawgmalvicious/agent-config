---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-15
---

# Handoff: trace why a nested CLAUDE.md does not load

- **Written**: 2026-10-15, moved out of `scope-instructions.md`, whose
  pilot it does not wait on. "The script" below is that skill's
  `skills/meta/scope-instructions/scripts/folder-sessions.py`. Not
  re-measured since.
- **Kind**: an investigation, with nothing drafted. The 12 transcripts
  it rests on leave disk from about 2026-10-19 (§ "Re-measure before
  acting").

## The finding

Found while checking the script on this repo, 2026-10-15. Of 50 fresh
VS Code sessions launched in the main checkout that Read a file under
`docs/handoffs/` and never touched `docs/handoffs/CLAUDE.md` itself, 12
hold no `nested_memory` record of it and no copy of its text, on
2.1.289 to 2.1.296, every one of those Reads successful; one made 31.
Ruled out: worktree paths (all 12 touched the main checkout's files),
a resume or a compaction before the first touch (all 12 fresh), a
refused call. The cause is not traced.

The script's own reading of it, as fixed that day: the nested file in
61 of 105 sessions working under `docs/handoffs/`.

## Leads not yet tried

- **2.1.292's not-loaded line.** That release added a transcript line
  "when a nested one isn't loaded"
  (`docs/audits/2026-10-06/claude-code/00-audit-report.md`). Its record
  kind was in none of the 60 transcripts `scope-instructions.md`
  sampled, so nothing here reads it yet. Search the 12 for it first:
  those on 2.1.292 or later may say why.
- **The drive letter's case.** The VS Code session that wrote this
  brief, `6759858f` on 2.1.296, recorded its `cwd` three ways:
  `c:\Repos\…` 30 times, `C:\Repos\…` 65 and `/c/Repos/…` 18.
  `EnterWorktree` has refused a path that differed from git's only in
  that case (`execute/README.md` § "Every brief takes a worktree",
  2026-09-30). A lookup comparing a Read's path with the project root
  case-sensitively would find no nested file for one spelling. Compare
  the 12's `cwd` and `file_path` spellings with the 38 that loaded it.

## Where it lands

Traced, it is a learning about how Claude Code loads nested files:
`/learn` takes it into `claude/rules/agent-instructions-scoping.md`, and
a probe that reproduces it joins `scripts/test-instruction-loading.py`.
A harness bug also wants an upstream report, the user's to file.
`scope-instructions` claims nothing from it; its step 7 probe guards a
new file.

## Not checked

- CLI sessions: the 50 were VS Code sessions only.
- A `paths:` rule or a nested `AGENTS.md` loading on the same Reads.
- How the 12 spread across 2.1.289 to 2.1.296.

## Scrubbing

This repo's own sessions only, so their ids may be cited, as the
`nested-instruction-files.md` log at `92f8afc` cites its probes'.

## Re-measure before acting

The 12 transcripts are going. `cleanupPeriodDays` is 15, and the oldest
transcript here holding 2.1.289 was last written 2026-10-04, so the
first of them can leave disk from about 2026-10-19 and the last by
about 2026-10-30. Re-find them first and cite their ids: VS Code
sessions carry `"entrypoint":"claude-vscode"` on their records. Once
they are gone, re-derive the rate on fresh sessions, where a cause that
stands should recur.

```bash
grep -n cleanupPeriodDays claude/settings.json ~/.claude/settings.json   # 15 and 15 on 2026-10-15
grep -l -F '"version":"2.1.289"' ~/.claude/projects/c--Repos-Personal-agent-config/*.jsonl | xargs ls -tr --time-style=+%F -l | head -1   # last written 2026-10-04
```
