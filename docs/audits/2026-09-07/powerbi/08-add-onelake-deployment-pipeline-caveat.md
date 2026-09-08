# Handoff: add the OneLake image-URL caveat to `fabric-cicd`

- **Audit run**: 2026-09-07 (**second** run — see Provenance)
- **Source**: `powerbi`
- **Window**: floor `2026-08-01` → head `0e80b00b` (2026-08-25)
- **Covers recommended actions**: 4 of **`00b-audit-report-rerun.md`**
  (not of `00-audit-report.md` — two audits of this window ran on this
  date; see Provenance)
- **Kind**: content addition to a skill's caveat list. Prose only — no
  JSON property names, no frontmatter change, no behaviour change. One
  grep verifies it.
- **Target**: `skills/fabric/fabric-cicd/SKILL.md`

## The problem

August 2026 made OneLake file URLs a supported image source in Power BI
reports. Those URLs embed a **workspace GUID**, and **Fabric deployment
pipelines do not rewrite them on stage promotion**. A report promoted
dev → test → prod therefore keeps loading its images from the *dev*
workspace, silently, for as long as the promoter still has access to it.

`fabric-cicd` owns the deployment-pipeline-vs-Git-deploy decision in this
repo and carries no caveat about assets whose URLs survive promotion
unrewritten. This is a correctness trap rather than a style point: the
report renders, the images appear, and nothing indicates the wrong
workspace is being read. It only surfaces when dev access is revoked or
the dev workspace is deleted, by which time the promotion is long done.

## Evidence

From the upstream page introduced by this release,
`https://learn.microsoft.com/en-us/power-bi/visuals/power-bi-onelake-files`,
under **Considerations**, verbatim:

> Deployment pipelines don't rewrite OneLake image URLs. A report
> deployed to a new stage continues to reference files in the original
> workspace. To point to images in the target stage, use parameters or
> update the URLs after deployment.

The URL form that carries the workspace GUID, from the same page:

```http
https://onelake.dfs.fabric.microsoft.com/<workspace-guid>/<item-guid>/Files/<path>/<file-name>
```

Two adjacent limits from the same Considerations list, included because
they bound how a fix should be worded:

> Publish to web and other anonymous embed scenarios don't support
> OneLake file URLs because those scenarios can't authenticate to
> OneLake.

> OneLake URLs require authentication. Report viewers who don't have
> permission to read a file don't see its image.

### Current local coverage

`skills/fabric/fabric-cicd/SKILL.md:23` carries the row:

> `| Fabric deployment pipelines (service-side) | Workspace | Dev workspace promoted stage-to-stage in the portal / REST; no local code involved |`

and `SKILL.md:25` the paragraph beginning:

> `fab deploy` **wraps fabric-cicd** and consumes the same `config.yml` /
> `parameter.yml`. Don't mix Git-driven deploys and service-side
> deployment pipelines on the same workspaces.

Neither mentions asset URLs. A grep for `deployment pipeline` across the
whole audit output directory returns nothing for this caveat, and a grep
for `onelake` across `skills/fabric/fabric-cicd/` returns nothing at all.

## What to change

One file: `skills/fabric/fabric-cicd/SKILL.md`.

Add a caveat adjacent to the deployment-pipeline discussion at lines
23–25 recording that OneLake file URLs embedded in report definitions are
**not** rewritten on stage promotion, and that the remedies upstream names
are parameters or a post-deployment URL update.

## Constraint on the fix

Two bounds, both about not overreaching past what the evidence says.

1. **The upstream text says "use parameters" without naming a
   mechanism.** It is tempting to write that `fabric-cicd`'s
   `parameter.yml` find/replace handles this — that is a plausible fit
   and this skill already documents that file, but **the audit did not
   establish it**. Either verify `parameter.yml` actually reaches report
   definition payloads for this case and say so, or write the caveat
   mechanism-neutral ("parameterize or rewrite post-deployment") and
   leave the binding open.

2. **Scope the claim to deployment pipelines.** The upstream sentence is
   specifically about deployment pipelines. It says nothing about
   whether Git integration, `fab deploy`, or the `fabric-cicd` Python
   tool rewrite these URLs. Do not generalize it to "Fabric deployment"
   as a whole.

## Sequencing note

Related to but **not** bundled with brief `03`
(`03-add-onelake-image-urls.md`), which adds the OneLake image-source
model to `powerbi-report-authoring/references/image.md`. Same upstream
page, different artifact, different reviewer, different verification —
`03` is verified by a grep over `skills/powerbi`, this by a grep over
`skills/fabric`. Either can land without the other.

If both are executed in one session, the OneLake URL format block is the
one piece of text worth keeping consistent between them.

## Verification

1. `grep -rniE "deployment pipeline" skills/fabric/fabric-cicd --include=*.md`
   — the new caveat appears alongside the existing pipeline rows.
2. `grep -rniE "onelake" skills/fabric/fabric-cicd --include=*.md`
   — previously zero hits; should now return the caveat.
3. If the `parameter.yml` binding was asserted rather than left open,
   record how it was verified. If it could not be verified, confirm the
   wording stayed mechanism-neutral per Constraint 1.
4. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-cicd/SKILL.md`
   — `description` is capped at 1024 chars; if the caveat was summarized
   into it, the linter will name the field.
5. `pre-commit run --all-files`.

## Provenance

Found by the **second** `powerbi` drift audit run on 2026-09-07, against
the same 2026-08-01 floor and the same head `0e80b00b` as the first.

This finding is absent from the first run's brief set, and the reason is
worth recording because it bears on trusting it: the first run sourced
its OneLake evidence from the August release **commit message**, which
records the feature and the publish-to-web limitation but not this one.
The second run drilled the new upstream page
(`power-bi-onelake-files`) directly, where the Considerations list
carries it verbatim. So this is a drill-depth difference, not a
disagreement between the two runs — nothing in brief `03` contradicts it.

The two runs otherwise converged closely, which is the main reason to
trust both.

## Execution log

- **Executed**: 2026-09-08 — applied
- **Session**: fresh
- **Files changed**: `skills/fabric/fabric-cicd/SKILL.md`
- **Verification**: steps 1–4 ran and pass; step 5 runs once at the end of the
  brief set.
  1. `grep -rnic "deployment pipeline" skills/fabric/fabric-cicd/SKILL.md` — 5
     hits; the new caveat sits directly beneath the existing pipeline rows at
     lines 23–25, where the brief asked for it.
  2. `grep -rnic "onelake" skills/fabric/fabric-cicd/SKILL.md` — 4 hits, up from
     0 at audit time.
  3. **Constraint 1: the wording stayed mechanism-neutral, and the reason is
     recorded in the skill itself.** The `parameter.yml` binding was *not*
     asserted. Investigating it turned up a sharper point than the brief
     anticipated: `parameter.yml`'s `find_replace` does take a `file_path` glob
     (`SKILL.md:118`), so it is genuinely plausible it could reach a report
     definition — but `parameter.yml` belongs to the **Git-driven fabric-cicd
     path**, whereas the upstream sentence is about **service-side deployment
     pipelines**. Those are different mechanisms, listed as separate rows in
     this skill's own comparison table. Treating upstream's "use parameters" as
     `parameter.yml` would have conflated them, which is exactly the overreach
     Constraint 1 exists to stop. The caveat therefore says the two should not
     be assumed equivalent, which is a caution rather than a mechanism claim.
  4. Lint passes.
- **Constraint 2** observed: the caveat is scoped to deployment pipelines, and
  it says explicitly that whether Git integration, `fab deploy`, or fabric-cicd
  rewrite these URLs is *undocumented* rather than known to be "no" — so the
  claim is not generalized to "Fabric deployment" as a whole.
- **Sequencing note honoured**: brief `03` was executed in this same session,
  and the OneLake URL format block is byte-identical between
  `powerbi-report-authoring/references/image.md` and this file, as the note
  asked.
- **Deferred**: no behavioural confirmation — an edited `SKILL.md` does not
  reliably reload mid-session on Windows. A fresh session would exercise it.
- **Deviations**: none.
