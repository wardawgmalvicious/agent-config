# Handoff: a CI-workflow rule for YAML

- **Written**: 2026-09-10, out of the session that built
  [payload-coverage.py](../../../scripts/payload-coverage.py). YAML came
  up as a wanted rule and the measurement argued for deferring it.
- **Kind**: one coding rule.
- **Status**: **deferred 2026-09-10 — not declined.** Wanted, and
  blocked on evidence rather than on anything in this queue. Deferred on
  an external trigger, the way
  [item-type-skill-fabric-plan.md](item-type-skill-fabric-plan.md) is.
- **Run in**: a session where CI work is actually happening, so the rule
  is measured against workflows being written rather than recalled.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## Why it is deferred: there is not enough surface to measure

Measured 2026-09-10 across every git repo on this machine, personal and
client. **Eleven `.yml` / `.yaml` files exist in total**, and all eleven
are uncovered — no rule or skill in the payload declares a glob matching
any of them. Re-derive with:

```bash
uv run --with pyyaml --with wcmatch python scripts/payload-coverage.py \
    --sweep <repo-root>
```

They decompose three ways, and the decomposition is the finding:

| Kind | Count |
| --- | --- |
| GitHub Actions workflows | 7 |
| `.pre-commit-config.yaml` | 2 |
| GitHub repo config (`dependabot`, `secret_scanning`) | 2 |

Eleven files is not a corpus. `coding-markdown.md` worked because 215
authored files could be counted — the 76-char wrap, `-` over `*` at
4268:1, `**bold**` over `__bold__` at 4737:22 were all *measured*, and
that is the only reason the rule states them as house convention rather
than as taste. **Nothing comparable is available here.** A YAML rule
written today would be an imported style guide, which is the one thing
the markdown rule deliberately was not.

## The scoping decision, so it is not re-litigated

**Scope it to CI workflow semantics, not to YAML syntax.**

YAML syntax guidance — indent two spaces, quote ambiguous scalars, avoid
tabs — is training-data-shaped and would fail the test every rule here
has to pass: would the model have got this wrong without the rule? The
Norway problem is the one syntax item with real teeth, and it is one
line, not a rule.

What has teeth is the CI half, where the failure modes are specific,
silent, and not guessable from the schema:

- **Permissions.** A workflow with no `permissions:` block inherits the
  repo default, which may be write. Least-privilege is per job.
- **Action pinning.** A tag is mutable; a commit SHA is not. This is a
  supply-chain property and the difference is invisible in a diff.
- **Trigger choice.** `pull_request_target` runs with the base repo's
  secrets against the fork's code. `pull_request` does not.
- **Concurrency.** Without a `concurrency:` group, pushes stack and a
  later run can finish before an earlier one.
- **Expression injection.** Interpolating `github.event.*` directly into
  a `run:` block executes attacker-controlled text; the fix is passing
  it through `env:`.
- **Silent skips.** A `paths:` filter that matches nothing produces a
  green check on a job that never ran — the same failure class as this
  repo's own note that a missed pre-commit `files:` pattern reports
  `Skipped` and scans as a pass.

Every one of those is a case where the workflow is valid YAML, the run
is green, and the thing you wanted did not happen. That is the content
worth a rule.

## The re-open condition

**A workflow being written or debugged, not merely being present.** Six
of the seven workflows counted above already exist and have not needed
this rule; their existence is not the trigger and never was. Re-open
when CI work is the session's actual subject — a new workflow, a
failing one, or a repo whose CI is being set up.

At that point the corpus is still small, so **drill the docs rather than
counting files.** Note which tool: GitHub Actions documentation lives on
`docs.github.com`, so `microsoft-learn-mcp` does not reach it — this is
the case where the Learn MCP leverage that makes Azure repos tractable
does not apply. WebFetch against the Actions security-hardening and
workflow-syntax pages is the path.

## Glob, when it is written

Two candidate shapes, and the choice matters more than it looks:

- `**/*.{yml,yaml}` — loads on every YAML file anywhere, including
  vendored and third-party ones. Wide, like `coding-markdown.md`.
- `**/.github/workflows/*.{yml,yaml}` plus
  `**/.pre-commit-config.yaml` — loads only where the content applies.

**Prefer the second.** The markdown rule earned its broad glob because
its content genuinely applies to any `.md` file; a rule about workflow
permissions and trigger semantics does not apply to a Docker Compose
file or a Kubernetes manifest, and loading it there is pure cost in
every session on the machine.

## Post-draft checklist

- `uv run --with pyyaml scripts/lint-frontmatter.py claude/rules/<name>.md`
- Confirm the glob against a path that must match and one that must not.
  A well-formed glob that is wrong about the world has no error path —
  the rule simply never loads, and nothing says so.
- `uv run --with pyyaml scripts/lint-instructions.py` will **fail** until
  the rule is ported to `copilot/instructions/` or recorded in
  `copilot/.source-hashes.json` as deferred with a reason. This one is a
  plausible port — CI conventions are not house voice.
- Add an entry to
  [claude/rules/README.md](../../../claude/rules/README.md).
- `./scripts/link-claude.ps1 -SkillGroups workflow` — rules deploy by
  copy and are **not live until this runs**.
