---
status: open
priority: 3
needs: []
blocked-by: []
written: 2026-09-30
---

# Handoff: a warehouse view's line endings, and `az rest` on a long-running call

- **Written**: 2026-09-30, from what two inbox notes still held, both
  from sessions in a client Fabric estate: finding 5 of one dated
  2026-09-29, and learning 3 of one dated 2026-09-24, whose first two
  learnings landed the day it was written (`8a59243`, `f3032cf`).
- **Kind**: an edit to `claude/rules/fabric-git-serialization.md`, and
  one sentence in `skills/fabric/fabric-rest-api/SKILL.md`. Two
  independent items, and neither needs a tenant. Nothing is drafted.

## Evidence status, per item

| Item | Status |
| --- | --- |
| 1, a view's tail is CRLF | Measured 2026-09-29, all 10 views of one warehouse |
| 1, two workspaces write the header differently | Recorded in the client repo's CI workflow; two dated incidents; not re-measured by the note's session |
| 1, the half-stripped header | Recorded in that repo's `.gitattributes`; mechanism as that file states it |
| 2, `az rest` shows no response header | Observed once, 2026-09-24; its option list confirmed here 2026-09-30 |

## 1. A view file's CRLF lines, and a header two workspaces write two ways

`fabric-git-serialization.md` § "Line endings" says the auto-generated
view header is CRLF and the surrounding body LF, and its editing bullets
say to carry the `-- Auto Generated (Do not modify) <hash>` header
forward verbatim. A client Fabric repo adds three things.

- **The two lines before a view's closing `GO` end CRLF too.** The body
  between is LF, and the file has no final newline. Three CRs a file,
  on every one of the 10 views measured.
- **Two workspaces in one estate write the header differently**: a
  sandbox workspace LF, the Dev workspace CRLF. On a mismatch the Dev
  sync rewrites the header and leaves the old line behind, short one
  dash: `- Auto Generated …`. That line fails with
  `Incorrect syntax near '-'` and blocks every later sync (2026-08-17,
  2026-08-19). Deleting that one line fixes it.
- **A second cause leaves the same line.** The live view's
  `sys.sql_modules` definition embeds the header comment, and the portal
  half-strips it on export. This one returns after every sync, until the
  view is re-created in each affected warehouse with `CREATE OR ALTER`,
  "starting from `CREATE`" in the note's words: read here as a statement
  whose text opens at `CREATE`, with no header above it. Confirm that
  reading against the client repo before writing it.

That repo's CI fails a pull request on any line starting
`- Auto Generated`, and on a view whose first line lacks its CR. Neither
check depends on the repo's stack, so the rule can suggest both beside
its `.gitattributes` advice.

**Edit.** § "Line endings: every Fabric repo needs a `.gitattributes`".
Write each claim at the strength its row above allows. `git grep -n
'Auto Generated'` finds the rule's one line on carrying the header
forward and nothing on the leftover line, `sys.sql_modules` or a view's
tail, in the rule or under `skills/fabric/` (2026-09-30).

The rule has no Copilot port.
[copilot-client-repo-findings.md](copilot-client-repo-findings.md),
item 4, holds that decision, and the same client repo's hand-written
guide already carries the view-header endings for Copilot.

## 2. `az rest` cannot follow a Fabric long-running operation

**Problem.** `az rest --method post --resource
https://api.fabric.microsoft.com --url …/items/{id}/getDefinition
--query 'definition.parts[].path' -o tsv` printed nothing and exited 0.
A session read that as an item with no definition before it saw why.

**Cause.** `getDefinition` answered `202 Accepted` with an empty body.
`az rest` prints the body and nothing else, so `Location` and
`x-ms-operation-id` never reach the caller, the operation cannot be
polled from it, and a `--query` over an empty body is empty without a
word.

**Confirmed here** 2026-09-30, Azure CLI 2.90.0: `az rest --help` lists
`--body`, `--headers`, `--method`, `--output-file`, `--resource`,
`--skip-authorization-header`, `--uri` and `--uri-parameters`, and no
option for response headers. Only the global `--debug` log shows them.

**The route.** For any call that may answer 202, `getDefinition`, a
definition update or a create, use a client that shows headers:
`curl -sS -D <file> -X POST -d '' -H @-` with the bearer header on stdin.
Read `x-ms-operation-id`, poll `GET /v1/operations/{id}` to `Succeeded`,
then `GET /v1/operations/{id}/result`. In the note's session the first
poll was already `Succeeded`. `az rest` stays fine for synchronous
reads: `/deploymentPipelines`, `/stages` and `/stages/{id}/items` each
answered 200 with a body.

**Generalization.** The skill's 201-or-202 rule, "Always branch on
status code", binds a CLI wrapper too. `az rest` hides the status, so it
cannot branch.

**Edit.** `fabric-rest-api/SKILL.md` § "Long-Running Operations (LRO)":
one sentence. `git grep -n 'az rest' -- skills/fabric/fabric-rest-api`
finds nothing (2026-09-30).

**Weight.** The note calls it lower value than the two learnings that
landed, added on its session's own initiative, and says the user has
not weighed in. `f3032cf`'s message left it "in the inbox for a separate
look". It is a yes or a no in the diff.

## Not checked

- Item 1's CRs, on a second warehouse or a second estate.
- Whether a Fabric workspace setting decides the header's line ending,
  or something about how each workspace was created.
- Item 2 on a newer Azure CLI, and whether `az rest --debug`'s log is
  stable enough to read an operation id from. The note did not try it.

## Verification

- `uv run --with pyyaml scripts/lint-frontmatter.py` on the rule and
  the skill.
- After the merge, `./scripts/link-claude.ps1 -SkillGroups
  workflow,social,meta` from the main checkout, never bare, then `cmp`
  the deployed rule against the repo's.
- `skills/fabric/` is pruned from user scope on this machine, so item
  2's edit reaches a session only where a `-ClaudeDir` run linked the
  group (root `CLAUDE.md` § "Branching and concurrent sessions").
  `skill-status.py` lists `fabric-rest-api` as a reference skill,
  `untested`, so the edit leaves no retest behind.
- Learn's long-running-operation page, re-read before the sentence
  quotes a header name.
- `pre-commit run --all-files`.

## Scrubbing

This repo is public. The estate's workspaces appear as "a sandbox
workspace" and "the Dev workspace", its warehouse and views unnamed, and
its repo as "a client Fabric repo". The error text and the header line
are the platform's.

## Re-measure before acting

- `git log -1 --format=%h -- claude/rules/fabric-git-serialization.md`:
  `7584a46` on 2026-09-30, the rule's twelfth commit.
- The client repo's views, CI workflow and `.gitattributes`, read from
  the main checkout before the worktree is entered
  ([../CLAUDE.md](../CLAUDE.md)): count CRs with `tr -cd '\r' < file |
  wc -c`, never `grep -c`.
- `az version`: 2.90.0 on 2026-09-30.
- [fabric-event-schema-set.md](fabric-event-schema-set.md) is the other
  open Fabric brief, and shares no file with this one.
