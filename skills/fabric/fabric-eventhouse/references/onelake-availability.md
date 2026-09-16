# Schema evolution with OneLake availability ON

Enabling OneLake availability narrows the schema-evolution surface. `SKILL.md`
carries the headline restriction; the full matrix and the off/on workaround
are here.

## With OneLake availability ON

When OneLake availability is enabled on the database or table, the supported schema-evolution surface narrows:

| Operation | Allowed with availability ON |
|---|---|
| Add column | ✅ (April 2026+) |
| Delete column | ✅ (April 2026+) |
| Alter column type | ❌ |
| Rename table | ❌ |
| Apply Row-Level Security | ❌ |
| Delete / truncate / purge data | ❌ |

Pre-April 2026 behavior required disabling availability for *any* schema change. For unsupported ops (type change, rename, RLS, data deletes) the workaround is still: turn OneLake availability **off**, perform the change, turn it back on. Toggling off soft-deletes the OneLake mirror; toggling back on backfills.

**Turn availability off with the portal toggle or
`.alter-merge table T policy mirroring with (IsEnabled=false)` — never
`.delete table policy mirroring`.** The two sound interchangeable and
are not: disabling means *"the underlying mirroring data is
soft-deleted and retained in the database"*, whereas *"deleting or
dropping the table mirroring policy will permanently delete the delta
table in OneLake."* Both quotes are Microsoft's, and its
mirroring-policy page nonetheless describes `.delete table policy
mirroring` as the way "to soft-delete the current mirroring policy",
contradicting its own warning further up the same page. Trust the
warning. Where guidance says "toggle X off", name the safe command —
the destructive verb is the better-known one.

A rename attempted while availability is on does not report this
cleanly: it surfaces as a `520` claiming to be temporary. See
`fabric-gotchas`.
