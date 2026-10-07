---
status: open
priority: 3
needs: [user]
blocked-by: []
written: 2026-09-27
---

# Handoff: the payload's own `CLAUDE.md` is also a nested file here

- **Written**: 2026-09-27, split out of `queue-state-per-brief.md`,
  landed that day, at the user's request: keep `claude/CLAUDE.md` where it is for now, learn how big the
  problem is, and explore the alternatives in a deeper session.
- **Kind**: an investigation, then a decision. `needs: user` because the
  user wants to be in that session.

## The problem

`claude/CLAUDE.md` is the source of `~/.claude/CLAUDE.md`, and by its
name also this repo's nested instruction file for `claude/`. A session
here that Reads under `claude/` can load it a second time, beside the
deployed copy. `.claude/settings.json` has held it off since `5b6221b`
(2026-09-24) with `claudeMdExcludes: ["**/claude/CLAUDE.md"]`, which
travels into worktrees with the rest of the file.

What the exclude still costs: `claude/` cannot have a layer file of its
own, its natural path being the payload. Every other directory can.

## How big it was

Measured 2026-09-27 over 297 main-session transcripts, 2026-09-11 to
2026-09-27, the retention window:

- **13 double loads in 10 sessions**, 2026-09-14 to 2026-09-24, each the
  whole file, 188 lines and 9,913 bytes, about 2,500 tokens. Two sessions
  loaded it again after `/compact`.
- **None since the exclude**, in 8 sessions that Read under `claude/`.
- **It is older than the window.** The ledger's 2026-09-24 entry
  (`docs/evidence/root-claude-md.md` § "Editing conventions") counts 15
  `nested_traversal` loads of this file in the `InstructionsLoaded` log
  from 2026-08-28 on.
- Before the exclude, 32 sessions Read under `claude/`, on every CLI
  version from 2.1.268 to 2.1.281, and all but 3 are accounted for. The
  12 whose first Read there was `claude/CLAUDE.md` itself never loaded it
  again: a direct Read seems to count as the load. Of the 20 that Read
  another file first, 10 loaded it, and 7 were the exclude's own probes
  of 2026-09-24, run with an exclude on by design, the "excluded" rows of
  that ledger table. **The 3 left did not load it and are unexplained**:
  sessions `8112123e`, `f6ea275d` and `44c05720`, 2026-09-13 and 09-16.
- **Identical content does not stop it.** On 2026-09-24 the repo copy was
  byte-identical to the deployed one and still loaded twice, per the same
  ledger entry.

Worth settling first, cheaply: whether a direct Read of a nested
`CLAUDE.md` does suppress its later nested load, by a probe in
`scripts/test-instruction-loading.py`, and what the 3 transcripts share.

**2026-10-06.** Three loader fixes bear on these figures. 2.1.281
stopped `CLAUDE.md` and rules files from an `--add-dir` directory inside
the working directory being sent twice in headless and SDK sessions;
2.1.286 stopped subagents spawned with worktree isolation loading the
project `CLAUDE.md` and its imports a second time from the worktree copy
on their first file read; 2.1.287 stopped a folder's `CLAUDE.md` being
attached a second time after a resume or a compaction. The measurements
above ran on 2.1.268 to 2.1.281, so they predate the last two and reach
2.1.281 only at their end. None of the three names a nested file loaded
twice in one uninterrupted session, this brief's case, though 2.1.287
bears on the two loads after `/compact`.

## What others do

Surveyed 2026-09-27; the first two read in the repos themselves.

- **Exclude the mirror**, as here: `lambdakilo/dotclaude` sets
  `"claudeMdExcludes": ["**/dotclaude/CLAUDE.md"]` in the settings it
  deploys, so it holds at user scope, keyed to the clone's name.
- **Never name the source `CLAUDE.md`**: `trailofbits/claude-code-config`,
  the most-starred config repo found, keeps `claude-md-template.md`; two
  chezmoi repos keep `dot_claude/CLAUDE.md.tmpl`. Nothing to exclude.
- **Load it twice without noticing**: two chezmoi repos keep a literal
  `CLAUDE.md` in a renamed directory, which does not help, since loading
  keys on the filename.
- None of those repos gives its own directories layer files. Anthropic's
  `claude-quickstarts` and `claude-for-legal` do, one per subproject;
  `claude-code` and `skills` carry no `CLAUDE.md` at all.

## Options for the session

1. **Keep the exclude.** Nothing to do; `claude/` gets no layer file.
2. **Rename the source**, e.g. `claude/global-CLAUDE.md`, deployed to
   `~/.claude/CLAUDE.md`; drop the exclude, and `claude/CLAUDE.md` is
   free for a layer file. Sized 2026-09-27: 32 files name
   `claude/CLAUDE.md` outside the dated audits, among them
   `link-claude.ps1`, `lint-claude-md.py`, `.pre-commit-config.yaml`,
   `.claude/settings.json`, and the bodies of `commit`, `land` and
   `learn`, which then need behaviour retests. The deploy must never copy
   the new layer file over the user-scope one; its verify step can
   compare hashes.
3. **Move the exclude to user scope**, as `lambdakilo` does. It then holds
   in any clone, and costs a pattern tied to a directory name.

**Not a symlink.** The memory docs say Cowork sessions skip a
`~/.claude/CLAUDE.md` that is a symlink or hard link, and root
`CLAUDE.md` records a symlinked `settings.json` breaking upstream three
times.
