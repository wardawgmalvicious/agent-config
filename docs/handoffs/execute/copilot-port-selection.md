# Handoff: ship a Copilot port only where it can apply

- **Written**: 2026-09-26, from the user's decision that day, and from
  the client Fabric repo's inbox note of 2026-09-25, whose evidence on
  this point is carried here now that the note is deleted.
- **Kind**: edits, decided. `scripts/copy-copilot.ps1` stops shipping
  every port to every repo, `scripts/payload-coverage.py` does the
  matching, and each file that says every port ships is corrected.
  Nothing is drafted.
- **Status**: **Open, written 2026-09-26.**
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## The decision

A port ships to a repo only if its `applyTo` matches at least one of
that repo's tracked files. The match is worked out at copy time rather
than kept as a list per repo, which would drift as ports are added.
`~/.copilot` keeps every port. The user decided this on 2026-09-26, once
the client Fabric repo was found carrying the C#, M and XAML ports with
no file any of them can match, and agreed the design below the same day.

## Why `applyTo` alone does not scope a port

`copy-copilot.ps1` ships every port on the argument that `applyTo`
scopes each one, so an unmatched port "costs a reader nothing". Its
`.DESCRIPTION` says so, and the comment under `#region Resolve selected
instructions` repeats it. That is true of attaching a port and not of
listing it.

VS Code 1.139.1 (commit `04c0d99f4f`), read 2026-09-26: the instructions
collector fetches every available instruction file, attaches those that
apply, then passes the whole list to `_getCustomizationsIndex`. Whenever
a read or terminal tool is enabled, that writes each file into an
`<instructions>` block of the request, with its path, its `description`
and its `applyTo`, filtered by session type and nothing else. Every port
here carries a `description`. The block tells the model:

> When an instruction file applies to your task (based on its
> description or applyTo pattern), follow the rules specified in it.
> [...] Only load instruction files when they are relevant to the
> current task. Do not eagerly load all instructions upfront. When
> modifying or creating files, check for instructions whose applyTo
> pattern matches the file path and follow them.

So each port shipped costs an entry in every agent request, matched or
not, and the model may read one on its description alone. On VS Code's
`main`, the client Fabric repo's session found the same class's
`_addReferencedInstructions` in
`src/vs/workbench/contrib/chat/common/promptSyntax/computeAutomaticInstructions.ts`
(2026-09-26); `_getCustomizationsIndex` sits beside it in the bundle.

## What was measured

On 2026-09-26, each port's `applyTo` against every checkout under the
machine's repos root, by tracked file (`git ls-files`), leaving out a
checkout's vendored `.github/skills/`. The matcher was
`payload-coverage.py`'s, `wcmatch` with `GLOBSTAR | DOTGLOB`, checked
against `PurePosixPath.full_match`, which `lint-frontmatter.py` uses;
the two agreed on every checkout.

| Checkout | Ports it carries | Ports that match | Carried, never match |
| --- | --- | --- | --- |
| The client Fabric repo: 507 files, 162 of them vendored skills | 10, by its manifest | DAX, expressions, KQL, Python, Spark SQL, TMDL, T-SQL | C#, M, XAML |
| An older client Fabric repo: 222 files | none | DAX, expressions, Python, TMDL, T-SQL | none carried |
| A client C#/XAML repo: 204 files | none | C# (144 files), XAML (31) | none carried |
| A client Bicep/Python repo: 104 files | none | Bicep (10), Python (48) | none carried |

- **Bicep**, the eleventh port, is missing from the client Fabric repo's
  manifest only because it was ported after that repo's last copy. It
  matches nothing there either.
- **The C#/XAML repo is why the pair cannot simply be un-ported.** The
  2026-09-25 note counted 158 tracked `.cs`, `.xaml` and `.csproj` files
  there. With no `.github/instructions`, it gets both ports from
  `~/.copilot` alone, as the Bicep/Python repo gets its two.
- **No vendored skill file matches a port today**, so leaving
  `.github/skills/` out changed no count. It still belongs out: those
  files are the script's own output, and a skill that ships a `.py` one
  day would otherwise pull the Python port into every repo it reaches.
- **Dropping `DOTGLOB` changes one count and no selection.** The client
  Fabric repo's KQL port matches 31 files with it and 27 without; the
  four are an Eventhouse's child databases, which Fabric serializes
  under a `.children/` folder. Whether VS Code's `**` enters a dot-folder
  was not checked. If it does not, the KQL port never applies to those
  four files in VS Code, which is a gap in the port, not in this design.
- **User scope lists a port a second time.** `~/.copilot/instructions`
  holds all eleven ports and the hand-written
  `cross-repo-handoffs.instructions.md` (`applyTo: '**'`), and the
  Fabric profile reads it: on 2026-09-25 Copilot named that file among
  those it had loaded in the client Fabric repo. So by the collector
  above, each port the repo carries is listed twice. That is read from
  the code, not counted in a request.

## The design

Agreed with the user on 2026-09-26. Names are the executing session's
to choose.

1. **A repo target gets the ports that match.** When `-CopilotDir` sits
   in a git repo, ship a port only if its `applyTo` matches at least one
   of that repo's tracked files, leaving out the target's own `skills/`.
   Print each port held back and the reason, so a run says what it
   withheld.
2. **`~/.copilot` keeps every port.** User scope is the only route to a
   repo that carries no `.github/instructions`, like the C#/XAML and
   Bicep/Python repos above. `$IsUserScope` already names the case.
3. **The manifest does the removing.** A port in
   `.managed-instructions.json` that is no longer selected is pruned the
   way a deselected group's skills are, so the client Fabric repo's next
   copy drops C#, M and XAML. A port the repo wrote itself is never in
   the manifest, so it is never touched.
4. **One glob engine, in Python.** A mode of `payload-coverage.py` loads
   the ports' `applyTo`, split on commas, and prints the ports that
   match a repo, and `copy-copilot.ps1` calls it through `uv`. The
   script calls no Python today, so a missing `uv` or a failed call has
   to stop the run, never fall back to shipping every port unannounced.
5. **An override for the deliberate case**, such as a repo about to gain
   a file type: at least a switch that ships every port, as today.
   `-WhatIf` shows the selection.
6. **The same mode audits a target already vendored**: ports its
   manifest carries that match nothing, and ports that match but are
   absent. Only a copy run fixes either, and only when someone runs it.

A target outside any git repo, other than `~/.copilot`, has nothing to
match against. Recommended: ship every port there and say so, which is
today's behaviour; refusing is the alternative.

**The engine errs toward shipping, which is the safe side.**
`payload-coverage.py` sets `DOTGLOB` to agree with Claude Code's
`paths:` (`scripts/activation-expect.py`), so it matches a leading dot,
which VS Code's `*` does not (`claude/rules/vscode-scoping.md`, the
gotcha on leading dots). A wrong match ships a port that is only ever
listed; a wrong miss would withhold one that applies. Say so in the
mode's docstring.

**The accepted cost**: a repo that gains a file type after its last
copy lacks that port until the next run, and nothing in Copilot says so.
The skip list a run prints, and the audit in item 6, are what surface
it.

## What changes here

- `scripts/copy-copilot.ps1`: the selection, the override and the call
  into Python. The `.DESCRIPTION` paragraph that begins "Every ported
  instruction ships" and the comment under `#region Resolve selected
  instructions` argue the opposite, and the first `.EXAMPLE` says it
  vendors "every ported instruction"; rewrite all three against the
  measurement above.
- `scripts/payload-coverage.py`: the mode, with an example in the
  docstring, since `--help` prints that section.
- `.claude/rules/copilot-payload.md`: a bullet saying a repo target gets
  the ports that match and `~/.copilot` gets all of them.
- `README.md` § "Tool support": its `copilot/` paragraph says the script
  vendors the ports into `.github/instructions`, and still counts
  "eight" ports where there are eleven.
- `docs/evidence/root-claude-md.md`: a dated entry carrying the table.
- A negative case in `tests/scripts/`: a scratch repo holding only
  `Program.cs` selects the C# port and no other, and a manifest listing
  a port that no longer matches loses it.

## Outside this repo

- **The client Fabric repo** needs one copy run once this lands, to
  drop the three ports; the commit is that repo's, so it goes through
  its inbox or to the user. Its inbox already holds this repo's
  2026-09-26 note on the C# and XAML ports' links, which the same run
  settles by removing them.
- **The second listing from user scope** stays. Removing it takes a
  profile-level `chat.instructionsFilesLocations` choice, which is
  machine-config's and read by the Local harness only, or an answer from
  [copilot-harness-switches.md](copilot-harness-switches.md).

## Reproducing

The table, from this repo's root, one checkout at a time:

```bash
uv run --no-project --with pyyaml --with wcmatch python - <checkout> <<'PY'
import pathlib, subprocess, sys
import yaml
from wcmatch import glob as wg
ports = {}
for p in sorted(pathlib.Path("copilot/instructions").glob("*.instructions.md")):
    meta = yaml.safe_load(p.read_text(encoding="utf-8").split("---\n", 2)[1])
    ports[p.name.removesuffix(".instructions.md")] = [g.strip() for g in meta["applyTo"].split(",")]
out = subprocess.run(["git", "-C", sys.argv[1], "ls-files"], capture_output=True,
                     text=True, encoding="utf-8").stdout.splitlines()
files = [f for f in out if not f.startswith(".github/skills/")]
for name, globs in ports.items():
    n = sum(wg.globmatch(f, globs, flags=wg.GLOBSTAR | wg.DOTGLOB) for f in files)
    print(f"{n:>5}  {name}")
PY
```

The collector, in the installed bundle, searched by content because
minified names change with every build:

```bash
out="$LOCALAPPDATA/Programs/Microsoft VS Code/<commit>/resources/app/out"
grep -oE '.{0,120}instruction files available\..{0,420}' \
  "$out/vs/workbench/workbench.desktop.main.js"
grep -oE '.{0,300}Here is a list of instruction files.{0,1500}' \
  "$out/vs/workbench/workbench.desktop.main.js"
```

`Code.VisualElementsManifest.xml` beside `Code.exe` names the current
build's commit directory.

## Re-measure before acting

- The table, by the snippet, for each checkout: a port or a checkout may
  have been added since.
- The collector, on whatever VS Code build is installed. If it stops
  listing unmatched files, the design still holds, but its reason
  shrinks to tidiness.
- That the client Fabric repo's manifest still carries the three.
