---
status: open
priority: 3
needs: [tenant, user]
blocked-by: []
written: 2026-10-17
---

# Handoff: drop powerbi-remote-mcp once fabric-iq's DAX returns a table

- **Written**: 2026-10-17, from one audit follow-up,
  [2026-10-06/claude-code/05](../../audits/2026-10-06/claude-code/completed/05-update-the-mcp-readme-for-harness-changes.md),
  by `/triage`. Re-measured against the payload at `d56fe51`, which
  changed nothing the follow-up left open.
- **Kind**: a probe in a tenant, then an MCP template edit that takes
  the user's yes. Nothing is drafted.

## The open item

The project template carries two querying servers, `fabric-iq` and
`powerbi-remote-mcp`, and `claude/mcp/README.md` keeps the second only
until the first's `ExecuteQuery` returns a table. On 2026-10-07 it did
not, where `powerbi-remote-mcp` did on the same model and query; the
README's `fabric-iq` row holds the calls. The user's call that day: drop
`powerbi-remote-mcp` once `fabric-iq`'s DAX works, and not on a connect
alone.

Re-measured 2026-10-17: the README's Querying bullet (lines 258-264)
and both server rows (271-272) still say so, and no commit has touched
`fabric-iq` since `58aadb0` (2026-10-07). Learn's "Get started with the
Fabric IQ MCP server" lists the same six tools, and its limitations say
a large result comes back as an embedded CSV resource, which "support
for embedded resources varies" across clients. That is a lead for the
README's open question, whether a table sat in a part of the reply
Claude Code does not show, and unconfirmed for a one-row result: the
page names it only for large responses.

## Where it runs

A tenant whose home region runs every Fabric workload, with
`AZURE_CONFIG_DIR` pinned first, on the current CLI: `fabric-iq`'s
`ExecuteQuery` of a small `EVALUATE`, then one whose result is large
enough to come back as the CSV resource. Record the CLI version, what
each reply held, and whether Claude Code showed a table.

## Decision after probing

- **A table comes back**: put the drop to the user. On a yes, remove
  `powerbi-remote-mcp` from the template and its row, and say in the
  Querying bullet that `fabric-iq` is the querying server. Dropping it
  also drops the generate-DAX tool, which `fabric-iq` does not list:
  name that in the question.
- **Still no table**: record the version and the reply in the
  `fabric-iq` row, and keep both servers. If the reply holds an
  embedded resource Claude Code does not render, say so there.

## Where it lands

`claude/mcp/.mcp.project.template.json`, the `powerbi-remote-mcp`
entry (line 134 on 2026-10-17), on the user's yes only: an MCP config
never moves on a brief's word. `claude/mcp/README.md` § "Servers
(project scope)", the Querying bullet and both rows, and the
`fabric-iq` row of the timeout table in § "Per-server timeout" (line
619). Both deploy with
`./scripts/link-claude.ps1 -SkillGroups workflow,social,meta`, then
`diff claude/mcp/README.md ~/.claude/mcp/README.md` prints nothing.

## Not checked

The probe itself: no tenant in this run. Learn was read on 2026-10-17.

## Re-measure before acting

```bash
grep -n "fabric-iq\|powerbi-remote-mcp" claude/mcp/.mcp.project.template.json   # 2026-10-17: 126 and 134
git log --format='%h %ad %s' --date=short -S fabric-iq -- claude/mcp/   # 2026-10-17: newest 58aadb0
```
