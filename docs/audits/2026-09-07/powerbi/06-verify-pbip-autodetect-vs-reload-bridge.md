# Handoff: verify PBIP external-change detection against the reload bridge

- **Audit run**: 2026-09-07
- **Source**: `powerbi`
- **Window**: floor `2026-08-01` → head `0e80b00b` (2026-08-25)
- **Covers recommended actions**: 7
- **Kind**: **investigation, not an edit.** May legitimately end with no
  file changed. Requires a running Power BI Desktop, so it cannot be
  completed from a headless session.
- **Target**: `skills/powerbi/powerbi-report-authoring/references/powerbi-desktop.md`
  — only if the investigation finds an interaction.

## The problem

`powerbi-desktop.md` documents an agent authoring loop that writes PBIR
files on disk and then tells Power BI Desktop to pick them up via
`powerbi-desktop reload --pid <pid>`. That loop assumes Desktop is
passive about external file changes.

As of the August 2026 release, it is not. Desktop now **detects external
changes to PBIP project files and prompts to apply them**. An unattended
prompt in the middle of a scripted reload is exactly the failure shape
the file already warns about elsewhere — its error table advises asking
the user whether "a Desktop modal dialog is blocking input".

Whether this actually breaks anything is unknown. The audit flagged it
rather than asserting it, and this brief preserves that: **find out
first, edit second.**

## Evidence

The `whats-new.md` row added at `369371ac` (2026-08-20), verbatim:

> Faster PBIP development with instant reloads and VS Code integration |
> Power BI Desktop detects external changes to PBIP project files and
> prompts you to apply them with a single click. A built-in entry point
> opens the project directly in Visual Studio Code.

The local workflow it may collide with, from `powerbi-desktop.md`:

- Line 18: "Run `powerbi-desktop reload --pid <pid>` for PBIP/PBIR
  current files."
- Line 99: advises reopening the PBIP "if model changes are not
  reflected".
- Line 131: "Run reload and screenshot operations serially for a given
  PID — never in [parallel]".
- Line 157 (`HostNotReady`), 158 (`Timeout`), 159 (`Cancelled`) — the
  existing error taxonomy, and the line that already anticipates a
  blocking dialog.

Note the shape of the risk: the new prompt fires on *external file
change*, which is precisely what the agent loop does on every iteration.
It is not an occasional dialog.

## What to investigate

Run this against a real Desktop instance with a PBIP open:

1. Establish the baseline — `powerbi-desktop status`, confirm
   `bridgeStatus: "connected"`, note the Desktop build number. The audit
   established a release month only; the build actually installed on this
   machine is what matters and is not recorded anywhere yet.
2. Modify a PBIR file externally (the ordinary agent write), and observe
   whether a prompt appears **without** issuing a reload.
3. With that prompt open, run `powerbi-desktop reload --pid <pid>` and
   record what comes back — success, `HostNotReady`, `Timeout`, or
   `Cancelled`.
4. Determine whether the prompt can be suppressed or pre-empted: a
   Desktop setting, or reloading fast enough that the prompt never
   materialises.
5. Check whether the prompt's "apply" and the bridge's reload can both
   fire, and whether that double-applies or races.

### Decision tree for the outcome

- **No interaction** (prompt does not appear for agent-driven writes, or
  does not block the bridge) — record the finding in this directory and
  change nothing. A negative result is a real result; note the Desktop
  build it was established on, because it may not hold on the next one.
- **Prompt appears but the bridge is unaffected** — add one line to the
  error table noting the prompt is benign, so a future session does not
  re-investigate.
- **Prompt blocks or races the bridge** — this becomes a real edit to the
  documented loop, and the `Cancelled` / `Timeout` / `HostNotReady` rows
  need a new cause. Consider whether the loop needs a suppression step
  before any write.

## Constraint on the fix

Do not edit `powerbi-desktop.md` on the strength of the What's New row
alone. The row describes a user-facing convenience feature; nothing in it
says how the prompt behaves under automation, and the audit performed no
empirical check. Writing a speculative caveat into a file that agents
follow literally would be worse than the current silence — it would send
sessions chasing a dialog that may never appear.

## Sequencing note

Independent of every other brief in this directory and safe to defer.
Nothing else depends on it, and it is the only brief here that cannot be
finished without a GUI session.

## Verification

1. Whatever the outcome, record the Desktop **build number** the
   investigation ran against, alongside the result.
2. If an edit lands:
   `uv run --with pyyaml scripts/lint-frontmatter.py skills/powerbi/powerbi-report-authoring/SKILL.md`,
   then `pre-commit run --all-files`.
3. If no edit lands, leave a short note in this directory recording the
   negative result and its date, so the next audit does not re-raise it
   as an open question.

## Provenance

Found by the 2026-09-07 `powerbi` drift audit against a 2026-08-01 floor.
The audit classified this bucket (a) with a **flag** action rather than
an edit, explicitly on the grounds that the interaction was plausible but
unverified — the connection to the existing modal-dialog warning in the
skill's own error table is what made it worth raising at all, and is also
the reason it stops short of a recommendation.
