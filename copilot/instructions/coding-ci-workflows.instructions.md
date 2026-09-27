---
name: 'CI Workflow Conventions'
description: 'GitHub Actions workflows and pre-commit configs: token permissions, SHA pinning, trigger and concurrency traps, script injection, and skips that report success'
applyTo: '**/.github/workflows/*.yml,**/.github/workflows/*.yaml,**/.pre-commit-config.yaml'
---

# CI Workflow Conventions

Applies to GitHub Actions workflow files, and to `.pre-commit-config.yaml`
where it shares a failure with them.

## Only what a green run hides

This rule says nothing about YAML syntax or what a schema check catches.
Each section below is a case where the file is valid, the run is green
or quietly cancelled, and the thing you wanted did not happen. Measured
2026-09-27 on one repo's three new workflows, written with care and no
rule loaded: OIDC throughout, yet one had no `permissions:` block, every
action was pinned to a tag, two shared a concurrency group, a deploy job
skipped by `if:` would report success, and the federated credential
trusted a subject form the repo's tokens no longer carry. Sources are
docs.github.com's own pages, read 2026-09-27; features still rolling out
behind a flag say so.

## Token permissions

- **Write a `permissions:` block in every workflow.** Without one,
  `GITHUB_TOKEN` gets the enterprise, organization or repository
  default, which the file cannot show: a new organization defaults to
  read on `contents` and `packages`, and an older one may grant
  read/write.
- **Naming any scope sets every unnamed one to `none`.** A block of
  `id-token: write` alone, for OIDC, leaves `contents: none`, while
  `actions/checkout` needs `contents: read`; the docs' own OIDC example
  lists both.
- The workflow's block applies first, then a job's. Grant a write scope
  on the one job that needs it.

## Pin actions to a full commit SHA

- **A tag is mutable**: it "can be moved or deleted if a bad actor gains
  access to the repository storing the action", and a full-length SHA is
  "currently the only way to use an action as an immutable release".
  Nothing in your diff changes when a tag moves.
- Keep the version readable as a trailing comment:
  `uses: actions/checkout@<40-hex-sha> # v4`. Repository, organization
  and enterprise policies can require SHA pins, still rolling out.
- **`rev:` in `.pre-commit-config.yaml` is the same property**: a tag
  clones whatever it names today. `pre-commit autoupdate --freeze`
  stores "frozen" hashes instead.

## Triggers

- **`pull_request_target` runs with the base repository's token and
  secrets**, read/write even from a public fork, while the workflow and
  an unqualified checkout come from the default branch. Checking out the
  pull request's head is the setup; the compromise completes at the next
  step that runs what it checked out, the "pwn request". `workflow_run`
  with an untrusted checkout is the same hazard. Use `pull_request`,
  which gets no secrets from a fork, and never build or run a pull
  request's code where a secret is in reach.
- **In a public repository with no Actions event policy,
  `pull_request_target` is blocked by a default policy**, in evaluate
  mode now and enforced from 2026-11-02. The docs do not say what a
  blocked run shows.
- **An event made with `GITHUB_TOKEN` starts no workflow run**, except
  `workflow_dispatch` and `repository_dispatch`. A workflow that pushes
  a commit or opens a pull request with it triggers nothing downstream,
  and nothing reports that.
- **`schedule` runs only on the default branch**, can be delayed or
  dropped at the top of the hour under load, and in a public repository
  is disabled after 60 days without activity. None of these leaves a
  failed run, because there is no run. Schedule off the hour.

## Concurrency

- **No `concurrency:` means runs overlap**: two deploys race, and the
  older can finish last.
- **A group without `cancel-in-progress` still cancels.** One run waits
  per group, and "any existing `pending` job or workflow in the same
  concurrency group will be canceled" when a newer one queues. Two
  workflows sharing a group, say a manual infrastructure run and a
  push-triggered deploy, cancel each other's waiting runs, and a
  cancelled run notifies no one. Share a group only where the two must
  serialize, and expect the older waiting run to be dropped. A `queue:
  max` property, keeping up to 100 waiting, is still rolling out.

## Expressions in `run:` are code

- **`${{ }}` is substituted into the script before the shell parses
  it**, so an attacker-set value runs as code. The docs' untrusted
  `github` fields typically end in `body`, `default_branch`, `email`,
  `head_ref`, `label`, `message`, `name`, `page_name`, `ref` or `title`,
  and `zzz";echo${IFS}"hello";#` is a valid branch name.
- **Pass the value through `env:` and quote the variable.** Do the same
  for a `workflow_dispatch` input, which anyone who can run the workflow
  sets.

```yaml
- name: Check the title
  env:
    TITLE: ${{ github.event.pull_request.title }}
  run: printf '%s\n' "$TITLE"
```

## Skips that read as success

- **A job skipped by `if:` reports Success**, and does not block a merge
  even as a required check. A job whose `needs:` failed is skipped the
  same way, so a deploy that never ran shows nothing red of its own. A
  required job with `needs:` runs under `if: always()` and fails itself
  on `needs.<job>.result`.
- **A workflow skipped by a `paths:`, `branches:` or commit-message
  filter leaves its required check Pending**, "Waiting for status to be
  reported", and the pull request cannot merge. Never require a workflow
  that can be skipped: require a job that always runs and decides
  inside.
- **A `paths:` filter reads only part of a large diff.** If the files it
  matches fall outside the first 300 changed files (3,000 where rolled
  out), the workflow does not run; past 1,000 commits in a push, or when
  the diff times out, it always runs.
- **A secret a run cannot see is an empty string**, not an error.
  `GITHUB_TOKEN` aside, no secret reaches a run from a fork, and an
  unset secret expands to `''`. A secret cannot appear in `if:`
  directly: set it in a job-level `env:` and test that.
- **In pre-commit, a `files:` or `types:` pattern that matches nothing
  prints `(no files to check)Skipped`**, which scans as a pass. A hook
  whose own script is outside its `files:` skips when only that script
  changes, even when the change fails files already committed (measured
  2026-09-26).

## OIDC subject claims

- **The token's `sub` depends on the trigger.** A job that names an
  environment gets `repo:<owner>/<repo>:environment:<name>`, a pull
  request event without one `repo:<owner>/<repo>:pull_request`, and
  anything else `repo:<owner>/<repo>:ref:refs/heads/<branch>`. A
  federated credential matches one string exactly, so one written for
  `main` rejects the same job run from a pull request, and the error
  comes from the cloud's login, not from GitHub.
- **A repository created after 2026-07-15 uses an immutable `sub`**
  carrying owner and repository IDs, as in
  `repo:octo-org@123456/octo-repo@456789:ref:refs/heads/main`, and so
  does one renamed or transferred since. Older repositories keep the
  old form unless opted in. A credential written in the old form never
  matches the new one.

## Checking a change

Read the diff for five things: a workflow with no `permissions:`, a
`uses:` or `rev:` that is not a full SHA, a `${{ }}` inside `run:`, a
concurrency group shared across workflows, and a required check that an
`if:` or a filter can skip.
