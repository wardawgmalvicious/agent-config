# Fabric Task Prompt

Use when asking Codex to work on Microsoft Fabric or Power BI artifacts.

```text
Work on this Fabric task:

Goal:
<describe the desired outcome>

Target surface:
<Warehouse | Lakehouse SQL Endpoint | Fabric SQL Database | Semantic Model/TMDL | Notebook/Spark | Pipeline | KQL/Eventhouse | Data Agent | Variable Library>

Known target context:
- Workspace: <name or checked-in variable, not a hardcoded ID unless already in repo config>
- Item: <name or checked-in variable>
- Environment: <dev/test/prod>
- Data sensitivity: <public/internal/client/confidential>

Constraints:
- Inspect local files first.
- Use official Microsoft docs or Azure/Fabric tooling for current platform behavior.
- Do not hardcode secrets, endpoints, workspace IDs, item IDs, or tokens.
- Ask before production writes, refreshes, permission changes, infrastructure changes, or destructive operations.

Validation:
- State the exact command, query, API call, or local validation you will use.
- If validation cannot run, explain why and what remains unverified.
```
