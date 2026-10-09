---
status: open
priority: 3
needs: []
blocked-by: []
written: 2026-10-08
---

# Handoff: the narrowed TMDL globs have passed only the static check on the fabric set

- **Written**: 2026-10-08, by a `/triage` sweep, from one audit
  follow-up: the 2026-10-06 `fabric` audit's
  [brief 20](../../audits/2026-10-06/fabric/completed/20-scope-tmdl-globs-and-check-incidentals.md),
  whose "real-path activation runs" span two fixture sets. Re-measured
  against the payload at `b0a8b24`: the globs are as brief 20 left
  them, though `5395313` has since rewritten `coding-tmdl`'s body.
- **Kind**: one test run, and an edit only if it fails.

## What is open

On 2026-10-06 brief 20 narrowed `fabric-tmdl` to `**/*.SemanticModel/**`
and the two TMDL rules, `coding-tmdl` and `coding-dax`, to
`**/*.SemanticModel/**/*.tmdl`. The static check passed then; the real
path has not run since.

- **The pbip half is not this brief's.** `fabric-tmdl`'s fixtures are
  in the pbip set, and `skill-status.py --stale` lists it as
  `retest-activation`, so the `/test-skill fabric-tmdl` that clears it
  runs that set's real path, which asserts rules beside skills.
- **The fabric half is.** Assertion 10 of
  `tests/skills/fabric-triggers/expected_activations.md`, that
  `SampleOntTmdl.Ontology/database.tmdl` activates `fabric-ontology`
  and nothing else, is in the fabric set, and no stamp owes that set a
  run, since none of its skills' globs moved.

Run once, from any session:

```powershell
./scripts/test-activation.ps1 -Set fabric
```

It deploys to a throwaway probe under `$env:TEMP`, opens one cold
`claude -p` session, on `opus[1m]` unless `-Model` says otherwise,
reads every fixture in the set and asserts the transcript. Run beside
`/test-skill fabric-tmdl`, it covers both halves in one sitting.

## Where it lands

Nowhere, if it passes: delete this brief, with the run's result in the
commit message. A failure on assertion 10 means a bare `**/*.tmdl` is
back in a glob: narrow it as brief 20 did, then run it again.

## Re-measure before acting

```bash
grep -n -A3 '^paths:' claude/rules/coding-tmdl.md claude/rules/coding-dax.md skills/fabric/fabric-tmdl/SKILL.md   # no bare **/*.tmdl on 2026-10-08
```

```powershell
./scripts/test-activation.ps1 -Set fabric -StaticOnly   # passed on 2026-10-06
```
