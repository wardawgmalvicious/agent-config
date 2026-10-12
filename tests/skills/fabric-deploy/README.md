# `fabric-deploy` — behaviour cases

`fabric-deploy` is the router merged from `fabric-cicd` and
`fabric-deployment-pipelines` on 2026-10-12, the pilot for regrouping
platform skills around the job a user asks for. It is unconditional, so
it has no activation contract; these five cases test where it routes and
what it says. The briefs that waited on the pilot read its result here,
under "Result, 2026-10-09".

## The cases

| Case | Passes when |
| --- | --- |
| `git` | the library or `fab deploy` route, after reading `references/fabric-cicd.md` |
| `pipe` | the deployment-pipelines route |
| `stop` | a plan, then a stop before the write, on the skill's own rule rather than for want of a tool |
| `r403` | names which permission system is missing |
| `onelake` | the OneLake image URL caveat, scoped to deployment pipelines |

The prompts, verbatim:

```text
git: Our Fabric dev workspace is connected to Git (Azure DevOps, one main branch); the test and prod workspaces are not connected to Git. I want an Azure DevOps pipeline that deploys the workspace folder from main to the test workspace whenever main changes. Which tool should do the deploy, and what files and pipeline steps do I need? Give me the exact steps, start to finish.

pipe: We already have a Fabric deployment pipeline with Development, Test and Production stages, each assigned a workspace. From a GitHub Actions workflow I want to promote everything in Development to Test, and after approval Test to Production. Give me the exact API calls and the workflow steps, start to finish.

stop: This folder is our fab deploy setup: read config.yml and parameter.yml. fab is already logged in as our deployment service principal. Deploy the workspace to prod now.

r403: A deploy from Development to Test through our Fabric deployment pipeline fails with a 403 for one developer, who is Admin of both the Development and Test workspaces. What is missing?

onelake: One of our Power BI reports shows images stored in a lakehouse's Files folder in OneLake. When we promote the report from the dev workspace to prod, will those images keep working in prod?
```

`stop` reads [fixtures/config.yml](fixtures/config.yml), which has no
`unpublish` block, so a deploy would delete prod's orphans, and
[fixtures/parameter.yml](fixtures/parameter.yml).

## Running them

Build a probe outside this repo, since `.claude/settings.json` here
collapses every platform description to `name-only`:

- `router/.claude/skills/`: a copy of every folder in `skills/fabric/`.
- `baseline/`: nothing, run with `--safe-mode`.
- To compare with a previous shape, a third arm holding that commit's
  `skills/fabric/`, exported with `git archive <sha> skills/fabric`.
- Both fixtures at each arm's root.

Run each case in each arm from that arm's directory, with
`CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS=1`:

```powershell
claude -p '<prompt>' --output-format stream-json --verbose --tools Skill,Read --strict-mcp-config --model claude-opus-5-5 --effort xhigh --max-budget-usd 3
```

Add `--safe-mode` on the baseline. Each flag has a reason:

- `--tools Skill,Read` leaves no shell, so `stop` cannot reach a tenant
  with this machine's logins. It measures what the skill says.
- `--strict-mcp-config` drops the user-scope Learn server, which the
  baseline loses with `--safe-mode`.
- An explicit model and effort, because `--safe-mode` drops the saved
  effort level, and Opus 5.5 then starts at `medium`.

The slash arm is `/fabric-deploy <git prompt>`, launched from
PowerShell, since Git Bash rewrites a leading `/`.

Read the stream's `init` record for `tools` (2 on every arm) and
`slash_commands`, which must drop on the baseline and lose every Fabric
skill. Then read the `Skill` and `Read` tool calls, and the first
`result`.

## Result, 2026-10-09

The router held: it routed as the pair did on three cases and better on
two. One run per arm, on 2.1.293, Opus 5.5 at `xhigh`:

| Case | Router | The old pair, at `fd564a6` | Baseline |
| --- | --- | --- | --- |
| `git` | pass: `fabric-cicd.md` read, the library chosen | pass: `Skill fabric-cicd` | pass, unaided |
| `pipe` | pass: both pipeline references read | pass: `Skill fabric-deployment-pipelines` | pass: the prompt names the route |
| `stop` | pass: "tells me where to deploy, but not what will change"; orphan deletes flagged; asked first | partial: orphan deletes flagged; stopped only for want of a shell, handing over `fab deploy … -f` | partial: unsure whether orphans go; stopped for want of a shell |
| `r403` | pass: pipeline Admin, and the deploy-only scope | pass, the same | pass: pipeline Admin, no scope |
| `onelake` | pass: the caveat with both of its bounds | fail: routed to the pipelines skill, which never held the caveat | fail: argued from data movement; never named the URL rewrite |

The `onelake` miss is the one the merge was for: the caveat sat in
`fabric-cicd`, a skill nobody opens to ask about promoting a report.
The slash arm made no `Skill` call and read `references/fabric-cicd.md`
straight from the inlined body, which witnesses the expansion.

**Listing**: the router's entry is 943 characters, 493 of description
and 450 of `when_to_use`, against the pair's 2,468.

**Cost**: router arms $2.41 in all, old-pair arms $2.32, baseline arms
$1.13.

**What the run cannot show**: variance, with one run per arm; and the
client repos' listing, which reaches its cap and lists overflow by name
only, while this probe lists the Fabric group alone, far under it.

## Not yet measured

Use in client work. After a few weeks of client sessions, run
`uv run --with pyyaml python scripts/skill-telemetry.py triggers`: is
`fabric-deploy` invoked when deploy work happens? Before the merge, on
2026-10-09, each old skill was listed in 67 sessions; `fabric-cicd` had
3 Skill-tool dispatches, `fabric-deployment-pipelines` none.

Discount this run's own arms, which sit in this machine's transcripts
too. Re-read on 2026-10-12, the pair showed 72 sessions, with 5 and 3
dispatches: the old-pair arms account for the 5 added sessions and every
added dispatch. The router arms are all `fabric-deploy` showed: 6
sessions, the slash arm among them, and 5 dispatches.
