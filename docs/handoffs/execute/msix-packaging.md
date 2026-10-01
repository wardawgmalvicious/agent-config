---
status: open
priority: 3
needs: []
blocked-by: []
written: 2026-09-10
---

# Skill handoff brief: msix-packaging

Last verified: 2026-10-01

> Guidance: Re-verify when referenced platform behaviors in project instructions get re-verified. For v1 briefs, use the date Claude Code creates the brief. Every section heading in this template stays in the filled brief; sections that don't apply get `N/A — <brief reason>` under the heading.

## Artifact path

Payload, in a new `windows` group:

- Repo: `skills/windows/msix-packaging/SKILL.md`, with four files in
  its `references/`.
- Deployed on this machine: **nowhere**. `windows` is a platform group,
  like `fabric` and `powerbi`: it is left out of the user-scope default,
  `-SkillGroups workflow,social,meta`, so no session sees the skill
  until a repo links it.
- Deployed to a repo that ships a Windows app, by group:

```powershell
./scripts/link-claude.ps1 -ClaudeDir <repo>/.claude -SkillsOnly -SkillGroups windows
```

The group is new, so the change reaches three files outside the skill's
directory, as the user agreed on 2026-10-01: `windows` joins
`PLATFORM_GROUPS` in `scripts/lint-skill-overrides.py`, which fails an
unclassified group; `.claude/settings.json` gains
`"msix-packaging": "name-only"` in `skillOverrides`, which that lint
requires of every platform skill; and `skills/README.md` gains a
section for the group. Two more, chosen by the user the same day once
this brief was shown, keep the prefix checks whole; see
Cross-reference dependencies.

No `.no-copilot` marker. The Copilot payload is being retired
(`copilot-payload-retirement.md`), and the marker's other job, allowing
an active `model:`, does not arise: the skill pins none.

## Scope

Takes a packaged Windows desktop app from source to an update its users
receive. It reads the project first, because the procedure forks there:
`WindowsPackageType` `None` means the app is unpackaged and has no MSIX
to release; single-project MSIX and a `.wapproj` build differently; and
`WindowsAppSDKSelfContained` decides whether the runtime ships inside
the package or must reach the machine another way. Then it walks one
release in order (raise the version, build, sign, publish the package,
publish the `.appinstaller` that names it, check the update lands) with
the error each step produces when it goes wrong. Three channels: App
Installer sideloading, the reference repo's; the Microsoft Store; and a
plain `.msix` or `.msixbundle` handed out directly.

It stops at the package boundary. Unpackaged distribution (MSI, EXE,
xcopy, the Windows App SDK runtime installer), packaging with external
location, enterprise deployment through Intune or Configuration
Manager, repackaging an installer with the MSIX Packaging Tool, and
Partner Center's listing and certification beyond its package
requirements are named as out of scope and not described.

Inline, model-invocable, not path-scoped. The queue brief left `paths:`
open with "measure, don't assume", and the group decision settled it: a
glob would narrow activation in the only repos that link the group and
save listing budget nowhere else, since a pruned platform group is in
no other session's listing. So the skill is unconditional where linked,
and the measurement the queue brief asked for, whether a packaging
request arrives as words or as a manifest being read, becomes the
words-first queries under Notes, which an unconditional skill can pass
and a conditional one could not.

## Sources drilled

Drilled on 2026-10-01, from Microsoft Learn only, by four Sonnet
subagents, one per source family, each returning a verbatim quote per
claim to a ledger: 100 page fetches (App Installer 32, signing 23,
identity and Store 23, Windows App SDK deployment and build 22), plus
search excerpts each ledger flagged as unfetched. The ledgers lived in
the session scratchpad and did not survive it; the skill's
`references/` carry the URL behind each claim instead. No page showed a
date except where noted.

**Re-read first-hand the same day, before drafting**, for every claim a
release depends on: the Publisher-subject match (exact, every DN field,
in order; Event ID 150) and the `/fd` hash match (Event ID 151); the
update rules (same package family, a higher version, MSIX to bundle but
never back); 0x80073CFB for a rebuilt or re-signed package at one
version; the Store's re-sign and its revision-0 rule; timestamping
against an expired certificate; Local Computer Trusted People, since
App Installer does not search the user store; the `.appinstaller`
identity having to match the package's; `ShowPrompt` showing no prompt
to a packaged desktop app; the `ms-appinstaller:` protocol off by
default since December 2023, and Visual Studio's 2017/2 schema default
(a status page last reviewed August 2026); `GenerateAppxPackageOnBuild`;
Release builds taking framework dependencies from the Store;
`Content-Length` on GET and HEAD (0x80072F76); and NETSDK1083 for
`win10-x64` on .NET 8 and later. All held.

- **App Installer**: the schema reference and element pages, the file
  overview, update settings, the manual and Visual Studio how-tos, web
  install from IIS and Azure, the security features page, the
  troubleshooting page, the auto-update overview, and the distribution
  feature status page. Established the file's anatomy, the four schema
  namespaces, `UpdateSettings`, the MIME table, the protocol's status
  and its re-enabling policy, and the MSBuild properties one CI sample
  uses.
- **Signing**: the signing overview, SignTool for packages, the
  end-to-end signing guide, certificate creation, SignTool's known
  issues and reference, signature troubleshooting, Artifact Signing's
  integrations and FAQ, persistent identity, unsigned packages, Device
  Guard signing (retired) and the developer settings page. Established
  the subject rule, the command lines, timestamping, trust stores,
  Artifact Signing's dlib and metadata file, and the Store's re-sign.
- **Identity and Store**: both `Identity` schema pages, the package
  identity overview, the Store's package requirements, upload and
  submission-error pages, product identity, app package updates,
  `Add-AppxPackage`, upgrade and downgrade across architectures,
  MakeAppx, capability declarations and the Win32 deployment error
  table. Established identity constraints, version rules, package
  formats, Store association and restricted capabilities.
- **Windows App SDK deployment and build**: the deployment overview and
  architecture, the framework-dependent, self-contained and unpackaged
  guides, single-project MSIX, project properties, CI for WinUI, the
  MSIX CI page, packaging a .NET app, the winapp CLI's .NET guide, the
  release channels with the 1.5, 1.8 and 2.0 notes, and .NET's RID
  graph change. Established the packaging and runtime forks, the
  msbuild properties, runtime identifiers, and the version line: stable
  2.5.1 on 2026-09-16, with 1.8's servicing ended 2026-09-24.

Also read, from the reference WinUI repo, by kind and not by name: its
app project's packaging properties and its `.appinstaller`. They are
test cases, recorded under Notes, and define none of the skill, as the
queue brief required.

Not drilled, and the draft describes none of it:

- **Visual Studio's `.appinstaller` template substitution.** No Learn
  page documents the `{Version}`-style placeholders a committed
  `Package.appinstaller` holds, or when they are filled; the skill says
  to read the generated file, not the template, before publishing.
- **The values of `AppInstallerCheckForUpdateFrequency` and
  `AppInstallerUpdateFrequency`**, and any MSBuild property for
  `HoursBetweenUpdateChecks`: one CI sample only.
- **Visual Studio's output layout**, beyond "an HTML page" and the
  `_Test` folder.
- **A rule tying the `.appinstaller` root `Version` to the package's.**
  Learn defines each separately, and its CI sample raises both.
- **The literal Store publisher format.** A `CN=` GUID appears only in
  Q&A threads, which were not used.
- **What a user sees on a disabled `ms-appinstaller:` link**, and the
  App Installer dialogs' exact text: screenshots only.
- **The role of `.pubxml` publish profiles in a WinUI MSIX build**: no
  page.
- **Whether `WindowsAppSDKSelfContained` itself needs a
  RuntimeIdentifier or a non-AnyCPU platform**: only .NET's NETSDK1031
  and 2021-era release notes.
- **Updates crossing between a Store install and an `.appinstaller`
  install**: not stated anywhere fetched.
- **Enterprise channels, the MSIX Packaging Tool, packaging with
  external location, embedded App Installer (`uap13`), the App
  Installer APIs and auto-update cmdlets, and WinGet**: out of scope,
  so not pursued.

## Frontmatter

```yaml
---
name: msix-packaging  # repo linter requires it; upstream optional — display label only, the /command comes from the directory name; max 64 chars; lowercase/digits/hyphens; no "anthropic"/"claude"
description: <FILLED — copy verbatim from "Description char count" below>  # repo linter requires it (upstream: recommended); gated at 1,024, the Agent Skills spec cap — see Description char count
when_to_use: <FILLED — copy verbatim from "Description char count" below>  # optional; appended to description in the skill listing; gated separately at 512, the Claude-Code-only remainder of the 1,536 truncation point. NOT one of the spec's six fields — a skill using it hard-fails the claude.ai upload path
disable-model-invocation: false  # ALWAYS PRESENT; true = manual-only (/commit-style): the description leaves context entirely; also blocks subagent preloading and scheduled-task prompts. Repo policy: false everywhere
# model: inherit  # ALWAYS PRESENT, ALWAYS COMMENTED — an active model: key of any value blocks Copilot slash invocation and fails lint-frontmatter.py
# effort:  # ALWAYS PRESENT, as a value or a commented-out placeholder — there is no `inherit` value, so omitting the field IS the inherit. Repo policy: commented on platform skills — this is a platform skill
---
```

No `paths:`, for the reason under Scope.

## Description char count

- `description`: 989 / 1,024
- `when_to_use`: 396 / 512

Counted with `wc -c` on ASCII-only text, 2026-10-01. The description
spends its length on the user's vocabulary and the error codes they
paste; `when_to_use` carries the verbs, the old Trusted Signing name,
and the pointer to `land`. Over the cap after an edit, cut the
description's coverage clause from its end, the error codes last.

```text
Use when releasing a packaged Windows desktop app as MSIX: WinUI 3 (Windows App SDK), or WPF and WinForms through a Windows Application Packaging Project (.wapproj), shipped by App Installer (.appinstaller), the Microsoft Store (.msixupload) or a plain .msix or .msixbundle. Reads the project first, since WindowsPackageType None means no MSIX and WindowsAppSDKSelfContained decides who delivers the runtime, then walks the release in order: raise the Identity Version in Package.appxmanifest, build with msbuild /p:GenerateAppxPackageOnBuild=true, sign with SignTool (/fd matching the block map, a timestamp, Publisher equal to the certificate subject), publish the package before the .appinstaller that names it, and check the update lands. Covers .appinstaller schemas and UpdateSettings, MIME types, the ms-appinstaller protocol disabled since December 2023, Trusted People trust, Azure Artifact Signing, the Store re-sign, and errors 0x80073CFB, 0x8007000B, 0x800B0109 and 0x80072F76.
```

```text
Use when asked to publish, release or ship a new version of a Windows app, bump or sign an MSIX (SignTool, Azure Artifact or Trusted Signing), edit the Identity in Package.appxmanifest or an .appinstaller file, set up App Installer auto-update, prepare a Microsoft Store submission, or explain why an MSIX will not install or update. Not for publishing a git branch or pull request: that is land.
```

## Body structure outline

1. **Opening.** The subject in two sentences; a dated-sources line
   saying Learn contradicts itself here and §7 lists where; what is not
   here (unpackaged installers, enterprise deployment, repackaging).
2. **§1 The three rules everything serves.** Name plus Publisher is the
   package family, and updates stay within it; every release raises the
   version, and same-version bits differ only as 0x80073CFB; the
   manifest Publisher equals the certificate subject exactly.
3. **§2 Read the project first.** A table from what the project file
   holds to what follows: `WindowsPackageType` `None` stops the skill;
   `EnableMsixTooling` with a manifest in the app project is
   single-project MSIX; a `.wapproj` builds instead;
   `WindowsAppSDKSelfContained` decides who delivers the runtime. Then
   architecture (no Any CPU; NETSDK1083 for `win10-*` RIDs) and how to
   tell the channel.
4. **§3 Release through App Installer, in order.** Version, build, sign,
   publish the package then the `.appinstaller`, verify the update, with
   the commands and the failure each step produces.
5. **§4 Trust on the target machine.** Local Computer Trusted People;
   the conflicting Trusted Root advice; when no trust step is needed.
6. **§5 Releasing to the Store instead.** Association, the StoreUpload
   build, no signature of your own, the revision-0 rule, restricted
   capabilities.
7. **§6 When an install or update fails.** The codes a release hits
   most, each with its cause and the step to revisit; the full table in
   `references/identity-and-store.md`.
8. **§7 Where Learn contradicts itself.** Each conflict, both sides
   cited, and what to do instead of quoting either as the rule.
9. **§8 Constraints.**

`references/`: `app-installer.md` (anatomy, schemas, update settings,
hosting, the protocol, MSBuild generation, logs), `signing.md`
(certificates, SignTool, timestamping, trust, Artifact Signing, CI
secrets, signing errors), `build.md` (the Windows App SDK forks,
single-project MSIX versus `.wapproj`, msbuild properties, runtime
identifiers, CI) and `identity-and-store.md` (identity constraints,
versions and updates, package formats, Store submission, the error
table).

## Changes from source proposal

The source is the queue brief `msix-packaging-skill.md`, written
2026-09-10 as the remainder of the C# rules brief, which `git log`
recovers. This brief replaces it under the skill's own stem, as
`/author-skill` step 5 says. Departures and settlements:

- **Name `msix-packaging`**: the queue stem less `-skill`, chosen by the
  user on 2026-10-01 over `msix-release` and `package-windows-app`.
- **A new `windows` platform group**, chosen by the user on 2026-10-01
  over `workflow` with a glob, which holds repo-general verbs and is the
  group Copilot copies, and over a new user-scope group, which would
  change the `-SkillGroups` default everywhere it is written and still
  need a glob.
- **One skill, not two**, chosen by the user on 2026-10-01: a packaging
  skill beside a distribution skill would both half-match "publish a new
  version", since the version must agree across the manifest and the
  `.appinstaller`.
- **`paths:` settled as none**, for the reason under Scope.
- **Carried forward unchanged**: the coverage evidence, re-measured
  under Notes; the three code-review findings, under Notes; and the
  denylist constraint.

## Tag

`personal`

## Portability caveats

N/A — personal scope. `when_to_use` is the only Claude-Code-only field
the skill sets; there is no `shell:`, `context: fork`, hook or active
`model:`.

## Cross-reference dependencies

- `land` — (a) already converted. Both use "publish" and "ship", and
  `land`'s mean a git branch. `land` sits at user scope, so it is
  co-active wherever `windows` is linked, and `when_to_use` names it.
- `claude/rules/coding-csharp.md` and `claude/rules/coding-xaml.md` —
  (a) already converted. They cover `.cs`, `.csproj` and `.xaml`; the
  skill restates neither.
- **The prefix checks, landing with the skill** — (a), chosen by the
  user on 2026-10-01. `PLATFORM_PREFIXES` in
  `scripts/lint-skill-overrides.py` gains `msix-`, without which an
  override left behind by a renamed `msix-` skill would go unflagged.
  Root `CLAUDE.md` § "Commands" checks a deploy with
  `ls ~/.claude/skills | grep -E '^(fabric|pbir|pbid)-'`, which would
  not flag this skill re-linked into user scope by a bare run, so its
  pattern gains `msix`, as does the `detail` of the VS Code task that
  describes the same check.
- **Stale lists once `windows` exists** — (b) pending, wording only,
  left for `/learn`: the platform-prefix line in
  `.claude/rules/editing-skills.md`, `/author-skill` step 3's group
  list, the naming paragraph in `skills/README.md`'s Behavioral
  section, `.claude/rules/skill-overrides.md`'s "`skills/fabric/` and
  `skills/powerbi/`", and the same pair in
  `scripts/lint-skill-overrides.py`'s docstring. None is read
  mechanically, and `/author-skill` edits no other skill, so none
  changes here.

## Claude Code's post-draft checklist

> Guidance: Reproduced verbatim in every filled brief as standing reminders. Do not edit per-brief; brief-specific observations belong in Notes below.

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit — an edit landing inside the frontmatter can leave YAML that still parses, into the wrong shape, with nothing warning.
4. If the run drafts 3+ skills, return a proposal covering all of them before writing any.

## Notes

**Evidence re-measured 2026-10-01, before entering the worktree.**
`payload-coverage.py` on the reference WinUI repo: 204 tracked files,
161 covered (79%), against 80% and 41 uncovered when the queue brief was
written. The five packaging-adjacent files (`.appxmanifest`,
`.appinstaller`, `.manifest`, `.resw`, `.sln`) are unchanged; the
movement is four commits of 2026-09-22 that added two uncovered `.json`
config examples and two covered `.cs` files. Nothing moved toward or
away from this work. A `.xml`, a Template Studio config rather than
packaging, also shows uncovered. **The skill raises no file's coverage
in that report**, which counts globs: being unconditional, it has none.

**The reference repo as a test case**, by kind: a self-contained,
single-project WinUI 3 app on .NET 10 and Windows App SDK 2.x; a
committed `Package.appinstaller` holding `{Version}`-style placeholders
under the 2017/2 schema with `HoursBetweenUpdateChecks="0"`, which
Learn's status page says that schema ignores and two other pages say it
supports; `win10-x86;win10-x64;win10-arm64` runtime identifiers beside a
.NET 10 target framework, the case NETSDK1083 names, though whether the
project builds as written is the test's to observe; and a
`PublishProfile` naming `win10-$(Platform).pubxml` files absent from
disk. Each is a question for `/test-skill`'s behavioural run, not a fact
the skill states about any repo.

**Carried from the queue brief**, three code-review findings for the
reference repo, which a rule stating them would make false everywhere
else: two packages referenced at different versions across projects,
which central package management would collapse; `Platforms`
disagreeing three ways across four projects, which bears on packaging,
since the package architecture is chosen from it; and two generations
of the Windows Community Toolkit in one app, the WinUI-2-era 7.x
controls beside 8.x ones.

**This repo is public and the reference repo's name is denylisted**, so
this brief says "the reference WinUI repo" throughout, and the skill
names no repo: it loads into every repo that links the group.

**Drill cost**: four Sonnet subagents, about 1.8M tokens together,
stopped once by the session limit and resumed with a cap of eight more
fetches each. A cost datum for the next drill of this size.

**Test plan for `/test-skill`.** The group deploys only after the
landing, since `link-claude.ps1` refuses a worktree: link `windows` into
a probe repo's project scope with `-ClaudeDir <probe>/.claude
-SkillsOnly -SkillGroups windows`, then probe cold, against a
`--safe-mode` baseline. Words-first queries, sent with no file read
before them, which it should fire on:

1. "Publish a new version of this app to the App Installer share."
2. "Users say App Installer reports the package as untrusted. Fix it."
3. "Bump the MSIX version and build x64 and arm64 packages."
4. "Installing the update fails with 0x80073CFB."
5. "Get this WinUI app ready for a Microsoft Store submission."
6. "Why does nobody get prompted to update the app?"

Queries it should leave alone: "Land this branch", and "Publish this
branch to GitHub and open a PR", both `land`'s; and "Write a unit test
for the view model". One it should take and stop at its boundary:
"Build a WiX installer for our unpackaged WPF app."

Behaviour to compare with the baseline: it reads the project file
before proposing a command; it refuses to change the Publisher or Name
of a shipped app; it raises the version rather than re-signing at the
same one; it passes `/fd` and `/td` explicitly and timestamps; it links
the `.appinstaller` directly rather than through `ms-appinstaller:`;
and it reports a Learn conflict as a conflict instead of quoting one
side.

## Confidence

- **Structure**: H — the shape follows the shipped platform skills, and
  the group deploys the way `fabric` and `powerbi` do.
- **Field specs**: M — the description sits 35 under its cap and its
  trigger quality is untested; whether "publish a new version" reaches
  this skill and not `land` is the test's first question.
- **Body content**: M — every claim is quoted from Learn and the
  load-bearing ones re-read first-hand, but Learn contradicts itself in
  a dozen places the skill reports rather than resolves, and no step has
  been run against a real release.
