# Handoff: re-probe the drift-audit tool premises

- **Audit run**: 2026-10-06
- **Source**: `claude-code`
- **Window**: floor `2026-08-30` (base `f1af9b1f`, 2026-08-28) → head
  `fbe20e00` (2026-10-06)
- **Covers recommended actions**: 13
- **Kind**: probe of two tool behaviours `drift-audit`'s own text relies
  on, then a self-referential edit to that skill
- **Target**: `.claude/skills/drift-audit/SKILL.md`

## The problem

`drift-audit`'s `SKILL.md` carries two premises about tools that this
window's releases may have changed: § 1's account of a Glob call that
answered "No files found" with its files present, and § 4b's model of
WebFetch summarizing any page above ~30–40 KB. Each steers how a run
fetches, so a stale one misleads every run.

## D-1 — the Glob miss in § 1

**Symptom.** § 1:
> List them with `Glob`, pattern `*.md`, `path` this skill's
> `references/sources/` directory: a pattern carrying a directory,
> `references/sources/*.md` under the skill's own directory, answered
> `No files found` with all six files present when that `path` sat
> inside the working directory (2026-10-06, CLI 2.1.291).

**Cause.** Unknown. Candidates in the window:

- `CHANGELOG.md` 2.1.292: "Fixed Grep and Glob reporting no matches
  when the file or folder they were given could not be read; Claude now
  retries once or tells you".
- `CHANGELOG.md` 2.1.260: "Glob/Grep: Fixed the search path being
  probed on disk before the permission check; a missing path is now
  reported after permission is decided, as Read does".

Seen in the same session while this brief was being written, on
2.1.291: the Grep tool, given `path` `docs/audits` and `glob`
`*/*/00-audit-report.md`, answered "No matches found" for a pattern
present in `docs/audits/2026-10-06/vscode-agent/00-audit-report.md`.
One hypothesis fits both misses and is untested: the tools hand the
pattern to ripgrep, whose globs follow gitignore rules, so a pattern
carrying a `/` is anchored at the working directory rather than at
`path`.
**Fix.** Probe on the current CLI: the § 1 call as written, its failing
form, and the Grep form above, each from the repo root; record the
version and the results. Then rewrite § 1's explanation to what the
probe shows, keeping the call that works.

## D-2 — WebFetch's handling of large pages in § 4b

**Symptom.** § 4b:
> `WebFetch` passes responses through a small LLM that summarizes pages
> above ~30–40 KB.

and its completeness check re-fetches by section when a broad fetch
comes back summarized.
**Cause.** Seen during the 2026-10-06 audit on 2.1.291: three
code.claude.com pages of 50.3, 55.6 and 76.2 KB came back as raw
markdown, saved to a tool-results file with a 2 KB preview ("Output too
large … Full output saved to"), not summarized, while six smaller pages
from the same host were answered by the summarizer. `CHANGELOG.md`
2.1.290:
> Fixed WebFetch silently dropping page text past 100,000 characters; it
> now says how much was unread and takes an `offset` to read on

**Fix.** Probe with § 4b's own broad prompt: one What's New page § 4b
was written for, from the `fabric` source, and one code.claude.com page
of similar size. Separate whether the raw path depends on the host, the
size or the content type. Then correct § 4b's premise and its
completeness check to the result.

## Constraint on the fix

Self-referential: the next `/drift-audit` run is the behavioural check.
Run the gates that apply here and record the rest as deferred to that
run, as `drift-update` does for such briefs.

## Verification

1. Each probe's output, with the CLI version, kept in the commit message
   or in a dated note where § 1 and § 4b cite their evidence.
2. § 1 and § 4b each name the CLI version they were re-measured on.
3. `uv run --with pyyaml scripts/lint-frontmatter.py .claude/skills/drift-audit/SKILL.md`
4. `pre-commit run --all-files`.

## Provenance

Both premises were written from measurement on or before 2026-10-06.
The WebFetch observation is the audit session's own; the Grep
observation was made in the same session while this brief was written.

## Execution log

- **Executed**: 2026-10-07 — escalated (both probes to a session of
  their own)
- **Session**: fresh (no audit or handoff run in this session; the whole
  pass, in its own worktree)
- **Files changed**: none
- **Open question**: where the probes run, put to the user, who chose a
  session of their own, from the main checkout rather than a worktree,
  so D-1's Glob sees the layout its miss happened in. A tool probe is
  more than a doc lookup, so this run made none.
- **Verification**: none of the brief's steps apply, since no file
  changed. Both premises are still in `SKILL.md`, § 1 at line 20 and
  § 4b at line 90, for the probe session to find. `pre-commit run
  --all-files` runs once at the end of the run.
- **Deferred**: both probes and the self-referential edit, steps 1 to 3
  with them; the next `/drift-audit` run is the behavioural check, as
  the constraint says.
- **Deviations**: none.
- **Needs**: a session of its own — from the main checkout, D-1's three
  Glob and Grep calls and D-2's two WebFetch fetches, with the CLI
  version recorded; then § 1 and § 4b rewritten to the results (steps 1
  to 3), and the next drift audit as the behavioural check.
- **Needs**: the next `/drift-audit` run, two adjacent findings — the
  run is the behavioural check the constraint defers: that § 1's
  slash-free `Glob` lists the registry, and, only on a run that falls
  back to the WebFetch path, that § 4b's completeness check catches the
  note and the tells. Both probes and steps 1 to 4 were done 2026-10-08
  in a session of their own, from the main checkout as the user chose,
  on CLI 2.1.292 (the VS Code extension); the probes are in the commit
  message. D-1 confirmed the brief's hypothesis, for `Glob` and `Grep`
  alike, and only under a `path` inside the working directory. D-2
  found the raw path needs a preapproved host, `text/markdown` and under
  100,000 characters, each one necessary, and targeted prompts returned
  a `fabric` section whole once in three. The 2026-10-06 sighting of
  small `code.claude.com` pages answered by the model did not reproduce:
  one of 8,570 characters came back raw. The adjacent findings: § 1's
  sizes for `claude-code` (~590 KB) and `skills-for-fabric` (~58 KB)
  are stale, 954,183 and 67,836 bytes on 2026-10-08; and both sources'
  registry entries reason from a "WebFetch summarization threshold" that
  § 4b no longer holds, though their github-mcp-only conclusion stands.
