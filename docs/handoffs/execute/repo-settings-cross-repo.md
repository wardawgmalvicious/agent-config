---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-09-30
---

# Handoff: `repo-settings.ps1` for the repos it cannot reach

- **Written**: 2026-09-30, from an inbox note of 2026-09-23. Its session
  was in a personal public repo, deleting and recreating it to purge
  leaked client names from pushed history. Re-measured against the
  payload at `0b1e82c`; the user answered its open question on
  2026-09-27.
- **Kind**: edits to `scripts/repo-settings.ps1`, its first negative-case
  suite, a settings snapshot per repo kept in this one, and a recreate
  runbook. Nothing is drafted.

## The incident, twice

`scripts/repo-settings.ps1` exists because GitHub keeps a repo's settings
on the server and nowhere else. This repo was recreated on 2026-09-10 to
purge leaked names, every toggle reset to GitHub's defaults, and nothing
recorded the old values (`3032d7f`). **On 2026-09-23 the same operation
ran on another personal repo, for the same reason, and the script was not
reached for**: nothing in that repo knew it existed. A description and
ten topics were rebuilt by hand with `gh repo edit`, chosen in the
moment, and every other setting took GitHub's default.

The recreate was right, and is still the only remedy for a pushed leak:
`refs/pull/N/head` pins every commit a pull request touched, and GitHub
serves unreachable objects by SHA until a collection on no schedule
(`docs/evidence/user-claude-md.md` § "Git identity is folder-scoped").
What failed is reach. `link-claude.ps1` deploys no script and only this
repo has a `.github/repo-settings.json`, so every other repo stands where
this one did before 2026-09-10, and a recreate is the one moment its old
values are already gone.

## Decided

**The user, 2026-09-27: the snapshots live centrally, in this repo, and
the script runs cross-repo with `-Repo` and `-Path`.** Two alternatives
are closed: a `link-claude.ps1` switch dropping the script and a seeded
file into each repo, and a bare pointer with nothing structural, which
the second incident argues against. An order came with the decision: the
crossed-pair guard first (item 1), since central snapshots are what make
a crossed pair likely, and a pointer where a recreate is documented
(item 6).

**The note's fourth learning has landed.** `claude/mcp/README.md` records
that `github-mcp`'s `delete_repository` cannot confirm from Claude Code
while `gh repo delete <owner>/<repo> --yes` works (`66ddcdc`, `7323c9a`,
2026-09-23). `66ddcdc` declined the note's proposed home, `land` step 2,
since `land` never deletes a repository. Nothing of it is left.

## Evidence status, per item

| Item | Status |
| --- | --- |
| 1, a crossed `-Export` | Read from the source 2026-09-23 and 2026-09-30; not run |
| 1, a crossed `-Apply` | Read from the source 2026-09-30; not run, and never to be run on a real pair |
| 2, what a snapshot publishes | Reasoned 2026-09-30 from this repo's visibility; the repo count measured |
| 3, no write side | Measured 2026-09-23 |
| 3, a read side | Measured 2026-09-23, re-run here 2026-09-30 |
| 4, `gh repo edit`'s reach | Measured 2026-09-23 from its help, against the snapshot's keys |
| 6, the recreate order | Observed once, in the 2026-09-23 recreate |
| The script runs cross-repo | Measured 2026-09-23: `-Export` then `-Check` on another repo of the same owner, `-Repo` and `-Path` both given, `31 setting(s) already match`, exit 0 |
| `gh` stays folder-scoped inside it | Measured 2026-09-23: under `pwsh -NoProfile`, `gh` resolved to `~\scripts\gh.ps1` and `gh api user -q .login` returned the expected account |

## 1. A crossed `-Repo` and `-Path`, refused in every mode

**Problem.** Read from the script at `0b1e82c`:

- `-Repo` defaults to the origin remote of the script's own repo, and
  `-Path` to that repo's `.github/repo-settings.json`; both hang off
  `$PSScriptRoot`, whatever the working directory. The note had them
  defaulting from the working directory's repo. Its point stands: the
  two default independently, so naming one leaves the other on this
  repo.
- **`-Export -Repo <owner>/<other>` overwrites this repo's snapshot with
  the other repo's settings**, printing `[ok] wrote <path>` and exiting
  0. Export is an unconditional `WriteAllText`. Git recovers the file,
  since it is committed.
- **`-Apply -Repo <owner>/<other>` crosses the same way, and writes to
  GitHub**: it patches the other repo with this repo's description,
  topics and toggles. The owner guard passes, both repos having one
  owner. The note counted `-Apply` as guarded.
- `-Check`, crossed, only misreports drift.

**The note's fix does not survive the decision.** It resolved the origin
of the repo containing `-Path` and refused a mismatch with `-Repo`.
Every central snapshot sits in this repo, so that check would refuse
every cross-repo run.

**A proposed shape**, for the session to confirm or better:

- The snapshot names its repo. `-Export` writes `owner/name` into the
  file beside `_comment`, and all three modes refuse a file naming
  another repo than `-Repo`, `-Export` over an existing file included.
  `ConvertTo-FlatSetting` skips `_comment` by name, and the new key
  needs the same skip or it reports as drift.
- `-Path` defaults from `-Repo`, not beside it. This repo keeps
  `.github/repo-settings.json`, which `land`'s
  `references/integration-routes.md` names, and any other repo gets one
  file under a directory here. This repo's file gains the key in the
  same commit.
- The refusals run in pre-flight, before the first `gh` call, so item 5
  can test them with no network.
- The note's simpler fallback, `-Repo` and `-Path` given together or
  not at all, still works under the decision and guards less: a pair
  given in full can still be the wrong pair.

## 2. Which repos get a snapshot

**This repo is public, so a snapshot publishes its repo's name,
description, topics and security toggles.** The decision did not say
which repos it covers, and the script writes whatever `-Repo` names.
Raised 2026-09-30, writing this brief.

- The personal account held 7 repos that day, 3 public and 4 private
  (`gh repo list`). A private repo's snapshot says that it exists and
  how it is set up: put the list to the user before committing one.
- A client organization's repo never gets one here. Its owner is an
  organization's account name, which `claude/CLAUDE.md` § "Git identity
  is folder-scoped" keeps out of every file, and `-Export` has no guard
  of any kind. `-Apply`'s compares `gh api user -q .login` with the
  owner; the same comparison in `-Export` would refuse every repo the
  acting account does not own.

## 3. The social preview: report what cannot be applied

The header says of the image "There is no API for it". Measured, that is
half true.

- **No write side**, 2026-09-23: a full introspection of GraphQL's
  mutation fields, filtered for `opengraph|social|preview|image`,
  matched none. REST has no endpoint, and
  `PATCH /repos/{owner}/{repo}` no field.
- **A read side**: GraphQL's `usesCustomOpenGraphImage` and
  `openGraphImageUrl`. An uploaded card serves from
  `repository-images.githubusercontent.com`, a generated one from
  `opengraph.githubassets.com`. Re-run here 2026-09-30 on this repo:
  `true`, and the first host.

```graphql
{ repository(owner: "<owner>", name: "<name>") {
    usesCustomOpenGraphImage
    openGraphImageUrl } }
```

So `-Check` can report a card that `-Apply` can never set, the step a
person forgets. The repo recreated on 2026-09-23 had never had a card
uploaded in the 5.5 months of its first life. Nothing inside the repo
showed it: the PNG sat committed under `docs/social/`, and GitHub never
reads the committed file.

**Edit.** The header bullet takes the measured form. `-Check`, and the
re-check after `-Apply`, print a `[SKIP]` line when no card is set, as a
ruleset difference already prints, naming the manual upload;
`docs/social/README.md` § "Uploading it" has this repo's. Whether an
unset card counts toward `-Check`'s exit code is the session's call.

## 4. `gh repo edit` reaches part of this, and the header should say so

So that nobody simplifies the script into it. `gh repo edit --help`,
read 2026-09-23, offers: description, homepage, topics, default branch,
visibility, the three merge toggles, the squash commit message, auto
merge, update branch, delete branch on merge, issues, wiki, projects,
discussions, secret scanning and its push protection, advanced security
and the template flag.

`.github/repo-settings.json` also carries what it cannot touch:

- `secret_scanning_non_provider_patterns` and
  `secret_scanning_validity_checks`;
- `dependabot.alerts` and `dependabot.security_updates`;
- `private_vulnerability_reporting`;
- `actions.permissions` and `actions.workflow_permissions`;
- `rulesets`;
- `squash_merge_commit_title` and `merge_commit_title`, where `gh`
  exposes only the message half;
- `web_commit_signoff_required`.

**Edit.** A short dated paragraph in the script's header. Re-run
`gh repo edit --help` first: the list moves with `gh`'s version.

## 5. The script's first suite

`tests/scripts/` holds a negative-case suite per script, and none for
this one (`ls tests/scripts/`, 2026-09-30). Item 1's refusals open it: a
snapshot naming another repo refused under each switch, a first
`-Export` to a fresh path allowed, this repo's bare run unchanged.
`tests/scripts/handoff-status/test-findings.sh` is the nearest pattern.

## 6. A recreate runbook, and a pointer a session elsewhere can find

**No file here describes standing a repo up**: `git grep 'repo create'`
finds nothing outside `docs/handoffs/` (2026-09-30). The 2026-09-23 run
showed that the order matters:

1. `-Export` while the settings still exist, unless a current snapshot
   is committed.
2. `gh repo delete <owner>/<repo> --yes`; the MCP tool cannot.
3. `gh repo create`, which takes `--description` and no topics, so
   `-Apply` restores both with everything else.
4. The repo's hooks, armed before the first push, or the push gate does
   not cover it. `core.hooksPath` was the step there. That repo's
   history holds a second form of the trap: hooks committed, and marked
   executable only in a later commit, a window in which a POSIX clone's
   hooks did not run and said nothing.
5. The push, then the social preview by hand, which `-Check` confirms
   once item 3 lands.

`scripts/README.md`'s entry for the script is the natural home, or a
short doc it links. The note also floated a skill.

**The pointer.** A session in another repo reads none of this repo's
files, so it finds the runbook only through something deployed. What
reaches a session at the moment a pushed leak is found:

- `claude/CLAUDE.md` § "Git identity is folder-scoped", which says only
  "Pushes are permanent";
- `commit`'s identity scan, among its commit rules in
  `skills/workflow/commit/SKILL.md`, which stops at prevention;
- `identity-guard`'s block message, which fires before a push, not
  after a leak.

Two constraints on the first: `claude/CLAUDE.md` stood at 189 of its 200
lines on 2026-09-30, and the user said on 2026-09-23 they would rather
it carry no repo path (this repo's session memory,
`global-claude-md-no-repo-refs`). Propose the home in the diff.

## Not checked

- A crossed `-Apply`, end to end. Prove its refusal on a throwaway
  repo, never on the real pair.
- Restoring rulesets. `-Apply` prints `[SKIP]` for a ruleset
  difference, so a repo that has rulesets comes back without them, by
  the script's own header. This repo has none.
- Whether every personal repo answers the merge settings. Read without
  admin rights they come back null, and the script aborts.

## Verification

- The new suite passes, and against the script before the change its
  crossed-pair cases fail.
- `./scripts/repo-settings.ps1` with no arguments still ends
  `N setting(s) already match`, exit 0.
- One cross-repo round trip on a personal repo the user names:
  `-Export`, then `-Check` exits 0.
- A fresh session in another repo, asked what to do about a name
  already pushed, names the runbook.
- `pre-commit run --all-files`.

## Scrubbing

This repo is public. The note was genericized: the second GitHub
account appears only as "the client account", and the leaked strings
were never reproduced. Item 2 is the risk this work adds.

## Re-measure before acting

- `git log -1 --format=%h -- scripts/repo-settings.ps1`: `3032d7f` on
  2026-09-30. A later commit may have landed part of this.
- `gh repo edit --help`, and the GraphQL introspection: either list can
  have grown.
- `gh repo list`, for item 2's count.
- `wc -l claude/CLAUDE.md`, for item 6's room.
