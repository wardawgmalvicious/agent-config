# skill-overlap routing gate test

Exercises [skill-overlap.py](../../../scripts/skill-overlap.py)'s `routing`
subcommand — the one signal in that script that gates a commit.

```bash
bash tests/scripts/skill-overlap/test-routing.sh
```

Each case builds a minimal payload in a temp directory and runs the script
against it. The script derives its repo root from its own location, so a copy
of `scripts/` beside a `skills/` tree is a complete fixture: no session, no
network, and nothing written inside this repo.

## Why a fixture rather than the live tree

**The repo passing says nothing.** It passes because every description here
routes to a skill that exists — which is exactly what a gate wired up wrong
and firing on nothing would also produce. The only case that distinguishes
them is a payload with a genuinely dangling reference, and this repo must not
contain one.

That is the same argument
[tests/hooks/identity-guard/](../../hooks/identity-guard/) makes, and the
suite is built the same way.

## What it asserts

| Case | Fixture | Expected |
| --- | --- | --- |
| Resolvable route | a description naming an installed skill | exit 0 |
| **Dangling route** | a description naming a missing skill | **exit 1** |
| Prose mention | the same missing name in the body, not the description | exit 0 |
| Accepted override | a description naming `powerbi-report-planning` | exit 0 |
| Derived allowlist | a description naming a file in `claude/rules/` | exit 0 |

The third row is the one that is easy to get backwards. A body may
legitimately discuss a skill that was deliberately not installed, so a prose
hit is reported and never gates; only the surface triggers are matched
against can fail.

The fifth row exercises the derived half of the allowlist through its
cheapest arm — a rule file. The MCP-server and drift-audit-source arms are
the same mechanism and are not separately fixtured.

## When to re-run

After any edit to `scripts/skill-overlap.py` or
`scripts/_skill_inventory.py`, and after changing the `files:` pattern on
the `lint-skill-routing` hook. A `files:` pattern that misses prints
`(no files to check) Skipped`, which scans as a pass, so prove it against a
path that must match and one that must not:

```bash
pre-commit run lint-skill-routing --files skills/fabric/fabric-cli/SKILL.md  # Passed
pre-commit run lint-skill-routing --files README.md                          # Skipped
```

Both were run when the hook was added, 2026-09-15.
