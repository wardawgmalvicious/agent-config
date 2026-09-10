# Handoff: C# coding rules

- **Written**: 2026-09-10, out of the session that built
  [payload-coverage.py](../../../scripts/payload-coverage.py) and found
  C# to be the largest uncovered surface in the payload.
- **Kind**: one coding rule certainly, a second probably, and a
  packaging artifact that is skill-shaped rather than rule-shaped.
- **Status**: **open, written 2026-09-10.** Nothing is drafted.
- **Run in**: a fresh session. The C# repos in reach are *inputs*, not
  the definition — see "One repo is context" below before treating any
  of them as the source of truth.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## Why this is the largest gap in the payload

Measured 2026-09-10, immediately after `coding-markdown.md` landed:

| Extension | Uncovered | Of |
| --- | --- | --- |
| `.cs` | 138 | 138 |
| `.xaml` | 14 | 14 |
| `.csproj` | 4 | 4 |
| `.sln` `.appxmanifest` `.appinstaller` `.resw` `.manifest` | 1 | 1 |

Coverage is **zero, not partial** — no rule and no skill declares a glob
matching a single one of these files. That is 161 files, more than twice
the next candidate. Re-derive rather than trusting this table, per the
queue's own re-measure rule:

```bash
uv run --with pyyaml --with wcmatch python scripts/payload-coverage.py \
    --sweep <repo-root>
```

## What earns a line in this rule

**A convention earns a line when there is a real fork and an unguided
model would choose arbitrarily.** That is the whole filter, and it is
stricter than it sounds.

It rules out most of what a C# style guide contains. "Prefer `async
Task` over `async void`" is already known to any model reading the file;
spending rule budget on it buys nothing and dilutes what does. It also
rules out anything a tool already enforces — see the next section.

What passes is a fork where both branches are defensible, the choice is
ours, and an unguided model answers inconsistently across sessions:
`var` everywhere versus explicit types at declarations, constructor
injection versus a service locator, `System.Text.Json` versus
`Newtonsoft.Json` on a framework shipping the former, whether a library
method takes a `CancellationToken` by convention or only where needed.

**Several of those are the user's call rather than something to derive.**
Where the fork is genuine and no measurement settles it, put the
question back rather than picking — the same discipline
`linkedin-highlights` uses for numbers a repo cannot know. A rule that
silently invents a preference is worse than one that asks, because
nothing later distinguishes the invention from a decision.

That filter is also why this work sat below `coding-markdown.md` despite
being four times the file count. Markdown conventions here were
*measurable* from 215 authored files, so the rule states them as fact.
C# has no comparable corpus in reach, so this rule is built from drilled
sources and explicit decisions instead, and every line has to survive
the question above.

## Where a repo's own config outranks the rule

Put this in the rule itself, as one line of generic content: **for
anything a repo's `.editorconfig`, `Directory.Build.props` or analyzer
set already pins, that file wins and the rule stays silent.**

This is a mechanism fact, true in any C# repo, and it needs no survey of
any particular one. It matters because the failure is silent and
confusing: the model writes code following the rule, the IDE reformats
it on save, and nothing explains which was right.

The practical consequence is that **the rule should not spend lines on
layout, spacing, brace placement, or `using` ordering at all.** Those
are what `.editorconfig` exists to express, so a rule stating them is
either redundant or in conflict, and never authoritative.

## Sources to drill

No single repo defines these conventions. Drill breadth-first:

- **Microsoft Learn** — the C# coding conventions and the .NET library
  design guidelines. Reachable by `microsoft-learn-mcp`, which is at
  user scope and fires in any session. That is the leverage the YAML
  rule notably lacks.
- **`dotnet/runtime`'s own coding style**, as a worked example of what a
  large codebase actually settled on and why.
- **Existing `.editorconfig` files, mined selectively.** Any C# repo in
  reach is a candidate input, the reference WinUI 3 one included — a
  well-chosen severity there is real evidence about what is worth
  pinning. Take the choices that look deliberate; do not adopt a file
  wholesale.

That last point has a measurement behind it. The reference repo's
`.editorconfig` runs 202 lines and defines
`csharp_style_var_for_built_in_types` **twice** — `true:suggestion` at
line 85 and `true:warning` at line 96 — and duplicates
`dotnet_style_object_initializer` as well (measured 2026-09-10). A file
that contradicts itself on severity accumulated rather than being
authored. Useful input, bad authority, which is the general case for any
config not written by the person adopting it.

Worth mining from it even so, as candidate forks rather than answers:
file-scoped namespaces, simple `using` statements, pattern matching over
`as`-with-null-check, `readonly` fields, and its nuanced
expression-bodied split (properties and accessors yes, constructors no,
methods only when they fit on one line).

## Candidate topics for the rule

None yet drilled. These are the areas where a fork is likely to be real:

| Topic | Why the fork is likely real |
| --- | --- |
| `async` discipline — `async void`, cancellation | a correctness contract, not layout |
| Nullable reference types past `<Nullable>enable` | the flag is on; boundaries are not |
| `IDisposable` / `IAsyncDisposable` ownership | lifetime, not syntax |
| EF Core query shape — tracking, N+1, migrations | library semantics |
| Azure SDK client lifetime and credential choice | library semantics |
| MVVM — toolkit generators vs hand-written `INPC` | framework choice |
| Exception policy — what escapes, what is caught | judgement |

## One repo is context, not the definition

The stack below is the C# actually worked in as of 2026-09-10. It is
useful for knowing which libraries the rule will be read alongside, and
for nothing else. **It does not scope the rule.**

That needs saying because the first draft of this brief got it wrong: it
made "what does that repo's `.editorconfig` not already cover" the
gating question, which quietly promoted one repo to the definition of
the rule's surface. It is one repo, its config was not authored here,
and it is *first* rather than representative. A rule built around it
would be wrong in the next C# repo — and since a rule loads by glob into
every repo, wrong-in-the-next is the default outcome, not an edge case.

Verified 2026-09-10 by reading the four `.csproj` files directly. Facts
about a dependency set, not identity — but see the constraint below.

- `net10.0-windows10.0.19041.0` and `net10.0`, `LangVersion latest`,
  `Nullable enable`
- WinUI 3 / `Microsoft.WindowsAppSDK` 2.2.0, self-contained
- `CommunityToolkit.Mvvm` 8.4.2
- `Microsoft.EntityFrameworkCore.Sqlite` 10.0.9,
  `Microsoft.Extensions.Hosting` 10.0.9
- `Azure.Identity` 1.21.0, `Azure.Security.KeyVault.Secrets` 4.11.0,
  `Azure.Messaging.EventHubs` 5.12.2
- `SSH.NET` 2025.1.0, `CsvHelper` 33.1.0, WCF `System.ServiceModel.*`

## Separate the generalizable findings from the repo-specific ones

Reading that dependency set turned up four things. **Two belong in a
rule and two do not**, and conflating them is the trap this section
exists to prevent.

Generalizable — true of any .NET 10 project, so rule content:

- `System.Data.SqlClient` (present at 4.9.1) is the archived package;
  `Microsoft.Data.SqlClient` is the supported successor.
- `Newtonsoft.Json` (present at 13.0.4) alongside a framework that
  ships `System.Text.Json` is a choice that should be deliberate.

Repo-specific — a code-review finding for that repo, **not** rule
content, because a rule stating it would be false everywhere else:

- `System.Configuration.ConfigurationManager` is referenced at both
  10.0.3 and 10.0.9 across projects; `WinUIEx` at both 2.9.1 and 2.9.2.
  Central package management would collapse both.
- `Platforms` disagrees three ways across four projects
  (`AnyCPU;x64;x86`, `x86;x64;arm64`, and a three-way union).
- `CommunityToolkit.WinUI.UI.Controls` 7.1.2 is the WinUI-2-era
  namespace, sitting beside `CommunityToolkit.WinUI.Controls.Segmented`
  8.2.x. Two toolkit generations in one app.

## Proposed artifacts

1. **`claude/rules/coding-csharp.md`** — `paths: ["**/*.cs"]`. The
   drilled forks plus the deference line. This is the one that certainly
   earns its place.
2. **`claude/rules/coding-xaml.md`** — `paths: ["**/*.xaml"]`.
   Recommended separate: `x:Bind` versus `Binding`, resource scoping,
   what belongs in code-behind. Only 14 files, so the case for folding
   it into the C# rule is real — decide by whether the content is
   markup guidance or C# guidance, not by file count.
3. **MSIX / `.appinstaller` packaging** — skill-shaped, not rule-shaped.
   Packaging is a procedure with an ordering and failure modes, which is
   a skill; a rule fires on a file and states conventions. Do not force
   it into `paths:`.

## Constraint: this repo is public and the client name is denylisted

The brief above says "the reference WinUI 3 repo" deliberately. That
repo's name and its path are both on `~/.config/identity-denylist.txt`,
so `identity-guard` blocks a commit that adds either. Package versions
and target frameworks are public NuGet facts and are fine. This is the
same convention `item-type-skill-fabric-plan.md` uses for the reference
Fabric repo.

The same constraint applies to the rule itself, which is why the stack
belongs in this brief and not in the rule: a rule naming one client's
dependency set would be wrong in every other repo it loads into.

## Post-draft checklist

- `uv run --with pyyaml scripts/lint-frontmatter.py claude/rules/<name>.md`
- Glob check by hand: a bare `*.cs` matches **only repo-root files**.
  `**/*.cs` is the form. The linter rejects that mistake, a backslash
  separator, and a leading `/` — but a glob that is well-formed and
  wrong about the world has no error path at all.
- `uv run --with pyyaml scripts/lint-instructions.py` will **fail** until
  each new rule is either ported to `copilot/instructions/` or recorded
  in `copilot/.source-hashes.json` as deferred with a reason. Unlike
  `coding-markdown.md`, a C# rule is a plausible port: the content is
  language convention rather than this repo's house voice.
- Add an entry to
  [claude/rules/README.md](../../../claude/rules/README.md).
- `./scripts/link-claude.ps1 -SkillGroups workflow` — rules deploy by
  copy and are **not live until this runs**. No `-Force` needed unless
  `CLAUDE.md` or `settings.json` also changed.
- Re-run `payload-coverage.py` and record the movement, the way the
  markdown rule's entry records 37% to 94%.
