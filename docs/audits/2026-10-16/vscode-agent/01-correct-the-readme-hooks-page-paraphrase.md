# Handoff: correct README's paraphrase of the VS Code hooks page

- **Audit run**: 2026-10-16
- **Source**: `vscode-agent`
- **Window**: floor `c642b585` (2026-10-01, the 2026-10-06 run's head) →
  head `e6026c88` (2026-10-16)
- **Covers recommended actions**: 1
- **Kind**: factual correction to one sentence of committed prose in the
  root `README.md`, which deploys nowhere. No behaviour changes.
- **Target**: `README.md`, the "VS Code's chat" bullet, lines 187–189

## The problem

README's "VS Code's chat" bullet describes VS Code's hooks page as it
rendered on 2026-10-06: five session targets, with the Chat view and the
Agents window "as clients of either host". The page no longer says
that. Since `fdf324630` (2026-10-13) it tables four Session Target
choices, Copilot, Claude, Codex and Cloud, gives Local a note of its own
beneath the table, and has dropped the sentence about hosts and clients.

## Evidence

**The README text**, `README.md:185-189` as of 2026-10-16:

> - **VS Code's chat** — the **session target** picks the harness that
>   runs a session, and the harness, not the model, decides what it reads.
>   VS Code's hooks page lists five targets, Local, Copilot, Claude, Codex
>   and Cloud, with the Chat view and the Agents window as clients of
>   either host (rendered 2026-10-06).

**The page at the floor.** `microsoft/vscode-docs`,
`docs/agent-customization/hooks.md` at `c642b585`, § "Choose the hook
implementation for your session", verbatim:

```text
The Agent Host is the process that hosts the Copilot, Claude, and Codex harnesses. The Local harness runs in the extension host. The {% data variables.copilot.chat_view %} and {% data variables.copilot.agents_window %} are clients that display and control sessions on either host.

| Session target | Where the harness runs | Hook implementation | Configuration and event reference |
|----------------|------------------------|---------------------|-----------------------------------|
| **Local** | Extension host | {% data variables.product.prodname_vscode_shortname %} Local hooks | Use the [Local configuration](#configure-hooks-for-the-local-harness) in this article and the [Local hooks reference](/docs/agents/reference/hooks-reference.md). |
| **Copilot** | Agent Host | Shared {% data variables.copilot.copilot_sdk_short %} implementation | Use the [GitHub Copilot hooks reference](https://docs.github.com/en/copilot/reference/hooks-reference). |
| **Claude** | Agent Host | Claude Agent SDK | Use the [Claude hooks reference](https://code.claude.com/docs/en/hooks). |
| **Codex** | Agent Host or the Codex extension | Codex runtime | Use the [Codex hooks documentation](https://developers.openai.com/codex/hooks/). |
| **Cloud** | Provider infrastructure | Selected cloud agent | Use the provider documentation. For {% data variables.copilot.copilot_cloud_agent %}, see the [GitHub Copilot hooks reference](https://docs.github.com/en/copilot/reference/hooks-reference). |
```

**The page at head**, `e6026c88`, same section, verbatim:

```text
The **Session Target** UI control selects the agent harness. The harness owns the hook lifecycle and payloads.

| **Session Target** choice | Hook implementation | Configuration and event reference |
|----------------|---------------------|-----------------------------------|
| **Copilot** | Shared {% data variables.copilot.copilot_sdk_short %} implementation | Use the [GitHub Copilot hooks reference](https://docs.github.com/en/copilot/reference/hooks-reference). |
| **Claude** | Claude Agent SDK | Use the [Claude hooks reference](https://code.claude.com/docs/en/hooks). |
| **Codex** | Codex runtime | Use the [Codex hooks documentation](https://developers.openai.com/codex/hooks/). |
| **Cloud** | Selected cloud agent | Use the provider documentation. For {% data variables.copilot.copilot_cloud_agent %}, see the [GitHub Copilot hooks reference](https://docs.github.com/en/copilot/reference/hooks-reference). |

> [!NOTE]
> **For Local harness sessions:** Use the [Local configuration](#configure-hooks-for-the-local-harness) in this article and the [Local hooks reference](/docs/agents/reference/hooks-reference.md). These hooks have their own events, settings, and payloads.
```

The "Where the harness runs" column and the hosts-and-clients sentence
went in `fdf324630`, "Simplify agent terminology (#10452)", 2026-10-13:
the only in-window landing whose diff removes "clients that display and
control sessions on either host" (`git log --first-parent -S`).

**What did not change.** The Agent Host is still documented. At
`e6026c88`, `docs/agents/concepts/agent-host.md` exists and names it 24
times, and 13 other pages under `docs/agents/` and `docs/enterprise/`
name it too. Only the four customization pages the source fetches
stopped using the term in this window. Local is still picked by the same
control: the page's management steps read "Select the harness or Cloud
target from the **Session Target** UI control", and its section
"Configure hooks for the Local harness" stands.

## What to change

1. **`README.md`**, the "VS Code's chat" bullet, the sentence beginning
   "VS Code's hooks page lists five targets" (lines 187–189). Restate
   what the page shows when re-read: four Session Target choices in the
   table, Copilot, Claude, Codex and Cloud, and Local in a note of its
   own. Drop "with the Chat view and the Agents window as clients of
   either host", and replace "(rendered 2026-10-06)" with the date of
   the re-read.

The rest of the bullet is out of scope: brief 02 edits its **Local**
sub-bullet, and the **Claude** and **Copilot** sub-bullets cite
measurements, not this page.

## Constraint on the fix

- Re-read the live page before editing,
  https://code.visualstudio.com/docs/agent-customization/hooks. The
  audit read the docs repo at head, which the site can lag; describe
  what the site shows, and date it.
- **Do not write that VS Code removed the Agent Host.** The evidence
  establishes only that the hooks page stopped describing hosts.
- Do not count the targets as four without Local. It left the table,
  not the product.

## Verification

1. `grep -n "either host" README.md` — no output.
2. `grep -n "hooks page" README.md` — one hit, the edited sentence,
   naming Copilot, Claude, Codex and Cloud and Local's note, dated
   2026-10-16 or later.
3. `pre-commit run --all-files`.

## Sequencing note

Brief 02 edits the same bullet's **Local** sub-bullet, lines 198–203.
Kept apart because each is checked against a different upstream page,
this one against the hooks page and brief 02 against the AI settings
reference, and brief 02 alone deploys a user-scope rule. Either order
works: find each target by its quoted text, since the other's edit can
move its lines.

## Provenance

Recommended action 1 of the 2026-10-16 `/drift-audit vscode-agent` run,
found in its base-to-head diff of the source's four `files` on a
scratchpad clone of `microsoft/vscode-docs`. The attribution to
`fdf324630` and the Agent Host counts (`git grep -c` over
`docs/**/*.md` at head) were read from the same clone while this brief
was written.
