---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-16
---

# Handoff: placed-elsewhere.sh says when no session holds a name

- **Written**: 2026-10-16, by the session that landed
  `peers-paragraph-placement.md`, from a near-miss in its probe. Measured
  against `placed-elsewhere.sh` and its suite as `5b37f0e` wrote them.
- **Kind**: an edit to a deployed skill's script, live machine-wide once
  saved, and a case in its negative-case suite. Nothing is drafted.

## The gap

`placed-elsewhere.sh` prints one line for three doubts: no registry entry
under the name, two, or one whose `cwd` is missing or not a string. Each
reads "in doubt, no single registry entry with a cwd", exit 1, so a name
passed short reads exactly like a real doubt, and nothing tells the
caller its own input was wrong. The Peers paragraph of `claude/CLAUDE.md`
makes that line an unasked commit, and `land` keeps the row in this tree,
as a session it must not move HEAD under.

The probe that landed the Peers paragraph's script path met it, as
`docs/evidence/user-claude-md.md` § "Agent config source" logs under
2026-10-16: one of six Opus 5.5 arms at `--effort xhigh` passed five
names of the form `brief: <slug>` as `<slug>`, read that line for each,
exit 1, and reran them whole before its edit. Had it not, it would have
committed unasked with its peer in another clone. The `name-session` hook
names most sessions `<kind>: <slug>` (`claude/hooks/name-session.sh`
rules 1 to 4: `test-skill:`, `brief:`, `inbox:`, `worktree:`), and four
of the five live registry entries carried such a name that day. One holds
a space, so it must be quoted whole, and its prefix reads like a label.

## The method

Keep "any doubt keeps it in": a name with no entry still exits 1. Give
that case a line of its own, and where an entry's name ends in
`: <name>`, name each such entry, so the next call can pass it whole, for
example "in doubt, no registry entry named release-notes; one is named
brief: release-notes". Two entries and a bad `cwd` keep lines of their
own. The jq `FILTER` returns nothing for no entry and for two alike, so
telling them apart takes a count.

No entry is not always a short name: a session that has exited leaves
none, as each probe peer's entry went once the probe closed its input.
So exit 2, the usage error's code, would misname that case. Whether a
gone session should read as elsewhere is out of scope, since the script
keeps every doubt in.

## Where it lands

- `skills/workflow/land/scripts/placed-elsewhere.sh`: the `-z $cwd`
  branch, the `FILTER` above it and the header's "Every other outcome"
  paragraph.
- `skills/workflow/land/scripts/never-prompted.sh`, whose "no single
  registry entry still idle from its start" a short name trips the same
  way, reading the session as live.
- `tests/scripts/placed-elsewhere/test-placed-elsewhere.sh` case 4, whose
  "no entry under the name" check matches `in doubt, no single`: add a
  short name beside a `brief: <slug>` entry, checking its hint and its
  exit 1. No hook or CI runs `tests/scripts/`, so run it by hand, and
  `tests/scripts/never-prompted/` too if that script changes.
- Then `uv run --with pyyaml scripts/skill-status.py --stale`, for
  whether `land` needs a retest.

## Not checked

How often a session passes a name short: one arm of six, on one model,
effort and prompt. Whether the instructions that hand a session the
script, the Peers paragraph, `commit` § "When another session shares
this tree" and `land` step 1, would do better saying "each name quoted
whole": `claude/CLAUDE.md` is at its cap, and the script's line reaches a
session at the moment it errs.

## Re-measure before acting

```bash
grep -n 'no single registry entry with a cwd' skills/workflow/land/scripts/placed-elsewhere.sh  # line 90 on 2026-10-16
grep -n 'no entry under the name' tests/scripts/placed-elsewhere/test-placed-elsewhere.sh       # line 182 on 2026-10-16
grep -n 'no single registry entry' skills/workflow/land/scripts/never-prompted.sh               # line 86 on 2026-10-16
```
