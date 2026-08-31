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
