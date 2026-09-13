# Handoff: measure the `fab api` Content-Type header

- **Audit run**: 2026-09-12
- **Source**: `skills-for-fabric`
- **Window**: floor `2026-08-20` (diff base `a5e82199`) → head `358d4d87`
  (2026-09-10T14:37Z)
- **Covers recommended actions**: 5
- **Kind**: an **investigation** — one offline measurement against the
  installed CLI — followed by a two-example edit if it comes back
  positive. `/drift-update` must hand the measurement back rather than
  guess the answer; the edit is mechanical once it is known.
- **Target**: `skills/fabric/fabric-cli/SKILL.md` (lines 139 and 155),
  and the measurement target
  `%APPDATA%\uv\tools\ms-fabric-cli\Lib\site-packages\fabric_cli`

## Context

Upstream reports a `fab api` POST failing with `UnsupportedMediaType`
until `--headers "Content-Type=application/json"` was added. This repo's
two `fab api -X post` examples carry no such header, and Microsoft Learn's
own `fab api` POST example does carry it.

What is not established is whether the header is *necessary*. The CLI may
set `Content-Type` itself, in which case both local examples are fine and
upstream hit a version or platform difference. That is one offline grep
away, and the edit should not be made before it is run: adding a header
the tool already sets is noise in a worked example, and worked examples
are what get copied.

## Evidence

**Upstream's report**, from the `v0.3.13` `CHANGELOG.md` patch
(`22cafc90`), verbatim:

> **`activator-cli`** -- the create request example now sends
> `--headers "Content-Type=application/json"` and carries a PowerShell
> variant that writes the body to `$env:TEMP` and passes it with
> `--body "@<file>"`. The section previously showed only a bash example
> with inline single-quoted JSON, so a PowerShell run failed twice before
> recovering -- once with `UnsupportedMediaType` for the missing content
> type, then with `InvalidInput` / `Unexpected character encountered
> while parsing value` when the shell mangled the inline JSON. The prose
> caveat pointing at the AVOID entry was not enough on its own, since the
> worked example is what gets copied.

Note what that bullet bundles: a missing header **and** a shell-quoting
failure. Only the first is in scope here.

**Learn passes the header.**
`https://learn.microsoft.com/fabric/database/sql/deploy-cli`, in the
Database collation section, verbatim:

```text
fab api workspaces/<workspace unique ID>/sqldatabases -X post -H "Content-Type=application/json" -i "{\"displayName\": \"<new database name>\", ...}"
```

**This repo's examples do not.** `skills/fabric/fabric-cli/SKILL.md`:

| Line | Text |
| --- | --- |
| 139 | `fab api -X post "<endpoint>" -i '<json>|<file>'    # POST with body` |
| 155 | `fab api -A powerbi "groups/$WS_ID/datasets/$MODEL_ID/refreshes" -X post -i '{"type":"Full"}'` |

**The CLI's own help hints at defaults but does not settle it.**
`fab api --help` on 2026-09-12 describes `-H` as "Additional headers in
key=value format, separated by commas. Optional" — *additional* to
something, which is why this needs the source and not the help text.

**The three other `v0.3.13` `activator-cli` fixes are already covered
here.** `fabric-activator` (authored 2026-09-12) carries
`displayName` / `DisplayName field is required`,
`fabricItemAction` / `targetItem`, and
`EventFieldSelector` / `IdentityPartAttribute` across its `SKILL.md` and
`references/`. It delegates `fab api` to `fabric-cli` rather than
restating invocation syntax, which is why the fourth fix lands on
`fabric-cli` and not on it.

## The measurement

Offline, zero side effects, no tenant. The installed package is at

```text
C:\Users\<username>\AppData\Roaming\uv\tools\ms-fabric-cli\Lib\site-packages\fabric_cli
```

— resolve it with `uv tool dir` rather than hardcoding the profile path.

```bash
grep -rn -i 'content-type' "$(uv tool dir)/ms-fabric-cli/Lib/site-packages/fabric_cli"
```

Three outcomes, with the edit each implies:

1. **The CLI sets `Content-Type: application/json` on a request with a
   body** — the local examples are correct. Make **no** change to lines
   139 and 155. Record the measurement, dated, with the CLI version
   (`fab --version`), because upstream's observation then belongs to a
   different version or path and the next reader needs to know which.
2. **The CLI sets it only on some paths** (for example only when `-i`
   takes a file, or only for the `fabric` audience) — add the header to
   whichever example falls outside the covered path, and say in one
   clause when it is needed. Do not add it to both unconditionally.
3. **The CLI never sets it** — add
   `-H "Content-Type=application/json"` to both examples, matching
   Learn's `key=value` form exactly (`=`, not `:` — that is `fab`
   syntax, not HTTP syntax).

**A live `fab api -X post` is not pre-approved and is not needed.** Both
local examples are side-effecting — line 155 triggers a semantic-model
refresh — so a "harmless endpoint" is not obviously available, and the
grep answers the question without touching a tenant. If the source is
ambiguous and a live call is the only way, bring that back to the user
rather than picking an endpoint.

## Constraint on the fix

Do not encode `UnsupportedMediaType` as the error text a reader should
expect. That string is upstream's observation from a PowerShell run
against the Activator create endpoint; this audit did not reproduce it,
and outcome 1 above would make it wrong here entirely. If the header
turns out to be needed, say the header is required and leave the error
string out unless it is measured.

Do not import the second half of upstream's bullet either — the
inline-JSON quoting failure and the `$env:TEMP` / `--body "@<file>"`
workaround. `fab` takes `-i`, not `--body`, so that part of the bullet
does not transfer verbatim, and PowerShell quoting of inline JSON is a
separate problem with its own home in the repo's PowerShell guidance.

## Verification

1. The grep above, with its output recorded and dated in whatever edit
   lands, plus `fab --version`.
2. If an edit was made:
   `grep -n 'Content-Type' skills/fabric/fabric-cli/SKILL.md` — the
   header appears in the POST examples the measurement implicated, and
   nowhere it does not apply.
3. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-cli/SKILL.md`.
4. `uv run scripts/lint-skill-overrides.py` — `fabric-cli` is in a
   collapsed group.
5. `pre-commit run --all-files`.

## Sequencing note

Independent of briefs 01–04 — no shared file, no shared verification.
It is last in the numbering because it is the smallest, not because it
is blocked.

## Provenance

Reached by the 2026-09-12 `/drift-audit` run while checking the
`v0.3.13` `activator-cli` fixes against the then-new `fabric-activator`
skill: three of the four were covered, and the fourth pointed at
`fab api` syntax, which `fabric-activator` delegates to `fabric-cli`.
The registry entry's `artifacts` list does not name `fabric-cli`, so the
bullet was only followed because the counterpart chain was walked by
hand — noted here as context for why it nearly went unreported. Widening
that list is **not** part of this brief and was not a recommended action
of the run.
