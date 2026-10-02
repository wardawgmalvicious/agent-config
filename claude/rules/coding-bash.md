---
paths:
  - "**/*.sh"
  - "**/*.bash"
  - "**/.bashrc"
  - "**/.bash_profile"
  - "**/.profile"
---

# Bash Coding Conventions

Applies to shell scripts and to sourced shell profiles across these
repos. Three shapes exist and they have different rules, called out
where they diverge:

- **CLI wrappers** — `local-cli/*.sh`, `infra/deploy.sh`.
  Strict-mode scripts a human or agent runs directly.
- **Claude Code hooks** — `~/.claude/hooks/*.sh`, or a repo's
  `.claude/hooks/`. Run automatically on every session or tool call; see
  the hooks section.
- **Shell profiles** — `.bashrc`, `.bash_profile`, `.profile`. Sourced
  into a shell rather than executed, which inverts the strict-mode rule
  below.

Target is bash 4.4+ (Git Bash on Windows ships 5.x). If a project-scope
`.claude/rules/coding-bash.md` exists, that file supersedes this one.

## Baseline

- `#!/usr/bin/env bash` — resolves via PATH rather than assuming
  `/bin/bash`.
- 4-space indent. LF line endings (this repo pins `eol=lf`).
- Lint with `shellcheck`; format with `shfmt`.
- **Functions**: `lower_snake_case` — `env_value`, `ensure_az_login`.
- **Globals and constants**: `UPPER_SNAKE_CASE` — `SCRIPT_DIR`, `CONN`.
- Comment the **why**. These scripts carry long header blocks explaining
  design decisions ("ONE SCRIPT, NOT ONE PER ENDPOINT TYPE"), accepted
  input shapes, and deployment assumptions. That header is the most
  valuable part of the file — extend it, never strip it.

## Header block

Executable scripts open with a comment block covering purpose, the
configuration they read, usage examples, and any deployment assumption:

```bash
#!/usr/bin/env bash
# Wrapper around <tool> for <purpose>.
#
# Why this shape rather than the obvious alternative: <rationale>.
#
# .env keys:
#   FOO_ENDPOINT=<host>[/<db>]     # what it means, where to find it
#
# Usage:
#   scripts/data/foo.sh -q "..."
#   echo "..." | scripts/data/foo.sh
#
# Deployment assumption: lives at <repo>/scripts/data/ so SCRIPT_DIR/../..
# resolves to the repo root containing .env.
```

## Strict mode

`set -euo pipefail` at the top of any script that **acts**. Do not use it
in observability hooks that must never abort — see the hooks section —
and do not use it in a shell profile.

**A profile is sourced, so `set -e` exits the shell you are starting.**
The first command returning non-zero ends rc processing *and* the
session, before any prompt appears — and a `command -v` probe or a
`grep` that matched nothing is a command returning non-zero. `set -u`
behaves differently rather than identically, which is worth knowing
before reaching for one as a substitute: an unbound reference prints
`bash: NAME: unbound variable` and rc processing **continues**. Guard
optional work with a conditional and let the failures pass. Both
measured on bash 5.3, 2026-09-10.

Three errexit behaviours that bite, all verified on bash 5.3:

**1. Under `pipefail`, a `grep` that matches nothing kills the script.**
A "is this key absent?" lookup exits 1, and the assignment inherits it.
The `|| true` is required, not defensive:

```bash
# Aborts the script when the key is absent
value=$(grep -E "^$1=" "$ENV_FILE" | head -n 1)

# Correct — absence is an expected outcome here
value=$({ grep -E "^$1=" "$ENV_FILE" || true; } | head -n 1)
```

**2. `set -e` is suppressed inside any command that is part of an `&&` or
`||` list**, including a subshell. The body runs to completion on error:

```bash
# `false` does NOT abort; "reached" prints
( false; echo reached ) || echo "handler"
```

Do not wrap a compound block in `|| handler` and assume errexit still
guards its interior. Check status explicitly inside instead.

**3. `set -u` and empty arrays.** On bash 4.4+ `"${ARR[@]}"` on an empty
array is safe. The `${ARR+"${ARR[@]}"}` form seen in `sql.sh` is
portability armour for older bash — harmless, and keep it where it is,
but it is not required on Git Bash 5.x.

## Preflight

Check for every external tool before using it, and say how to install it:

```bash
if ! command -v sqlcmd >/dev/null 2>&1; then
    echo "error: sqlcmd not found on PATH" >&2
    echo "hint: winget install Microsoft.Sqlcmd" >&2
    exit 1
fi
```

Probe the specific capability, not a proxy for it. `az account show`
succeeding does not mean a token can be minted for the audience you
need — under Conditional Access the session can be valid and the token
still refused, so probe with `az account get-access-token --resource`.

Zone arithmetic needs `uv` or `pwsh`, so preflight whichever the script
uses: convert through `uv run --no-project --with tzdata python`, never
through `date` with a named `TZ`, which answers UTC labelled `GMT` with
exit 0. `~/.claude/CLAUDE.md` § "Timezones: no tzdata in Git Bash, and
UTC timestamps" has the rule, and the evidence file it names has the
measurement under the same heading.

## Secrets and payloads stay off argv

A secret, a query or a request body reaches a child process on stdin,
in a file the caller owns, or in the environment — never as an
argument. One remedy, two reasons, standing on different evidence:

- **argv is visible outside the process** — `ps -ef`, Task Manager's
  command-line column, `Win32_Process.CommandLine` — for the life of
  the call, and kept by anything that logs process starts. That is
  documented OS behaviour, not a measured incident: keeping secrets
  off it is the user's design choice, applied 2026-09-22.
- **A native Windows program's argv is one command line**, capped at
  32,767 characters, and Git Bash's curl decodes it through the ANSI
  code page — wrong results with exit 0. Measured 2026-09-23;
  `~/.claude/CLAUDE.md` § "A native program's argv is one Windows
  command line" has the rule, and the evidence file it names has the
  measurements under the same heading.

```bash
JQ_BIN=()
case "$OSTYPE" in msys* | cygwin*) JQ_BIN=(-b) ;; esac
BODY=$(printf '%s' "$QUERY" | jq "${JQ_BIN[@]}" -Rs '{query: .}')
printf '%s' "$BODY" | curl -sS --data-binary @- \
    -H 'Content-Type: application/json' "$URL"
```

- **Gate `-b` on `cygwin*` as well as `msys*`.** Git Bash here reports
  `OSTYPE=cygwin` (2026-09-23), so an `msys*` gate alone never fires
  and jq silently reads the payload in text mode. `-b` needs jq 1.7 or
  later, which is why it is gated rather than passed everywhere. Pipe
  a file into jq rather than using `--rawfile`, which stays text mode
  even with `-b`.
- **`--data-binary @-`, not `--data @-`.** curl's manual says
  `-d @file` strips carriage returns, newlines and null bytes —
  harmless for a URL-encoded form, wrong for a query. A token form
  body goes the same way, and `printf` is a builtin, so the value is
  never an exec'd program's argument.
- **A header is argv too.** `-H @file` reads headers from a file, and
  `--config -` (`-K -`) takes `header =` and `data =` lines from stdin
  when one call needs both, since only one of `@-` and `--config -` can
  have stdin. A GET has no body, but a `--config -` block is read byte
  for byte as well: a `data-urlencode` line in one sent `é` as
  `%C3%A9`, against `%E9` as an argument (a client repo, 2026-09-23).
  Quote each value, escaping `\\`, `\"`, `\t`, `\n` and `\r`,
  backslash first.

## Paths

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
```

Never derive paths from `$PWD` — these scripts are run from anywhere.

On Windows, normalise paths crossing the Git Bash / Win32 boundary with
`cygpath`, and tolerate either form on input:

```bash
FILE_PATH_UNIX=$(cygpath -u "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")
```

## Output streams

- **stdout is for data** the caller pipes onward. Keep it clean.
- **stderr is for everything else** — diagnostics, prompts, progress.
  Redirect a chatty subcommand's output with `-o none >&2` rather than
  letting it pollute stdout.
- Lowercase prefixes: `error:`, `warning:`, `note:`, `hint:`.
- `exec` the final command so it replaces the shell and its exit status
  propagates directly: `exec sqlcmd -S "$SERVER" ...`.
- **A sourced profile keeps stdout empty.** Print its diagnostics only
  when stdout is a terminal (`[[ -t 1 ]]`), or send them to stderr.
  Claude Code builds a session's Bash snapshot by sourcing the profile
  and capturing `PATH` from the shell's output, so whatever the profile
  prints to stdout lands inside `PATH` for every later tool call. This
  machine's startup banner, ANSI escapes and all, sat at the head of
  the snapshot's `export PATH=` line until machine-config fixed it on
  2026-09-22 (`c9a2ed4`, banner only to a terminal); a snapshot taken
  the next morning held a plain `export PATH='/c/...`.

## Quoting and tests

- Quote every expansion: `"$var"`, `"${arr[@]}"`. Unquoted is a bug
  unless word-splitting is the explicit intent.
- `[[ ]]` over `[ ]` — no word-splitting surprises, supports `=~`.
- Under `set -u`, read possibly-unset variables as `"${VAR:-}"`.
- **Quoted heredocs (`<<'EOF'`) for literal content.** An unquoted
  heredoc expands `$`, backticks, and escapes; use it only when
  interpolation is wanted. This matters for any content containing
  Windows paths, regexes, or shell metacharacters.
- Provide escape hatches as environment variables (`SKIP_AZ_LOGIN=1`)
  rather than extra flags, for CI and non-interactive callers.

## A running script reads its file as it goes

Bash reads a script from its file while it runs, not whole before it
starts, so an edit made mid-run lands in that run: it resumes at its
byte offset, inside the new text. A background harness edited while it
waited on a long command resumed mid-word once the command returned —
`line 83: nvoked: command not found`, then
``syntax error near unexpected token `fi'``, exit 2 — and its post-run
checks never ran. An edit that began exactly at the next unread line
ran the new line as if it had always been there, exit 0. Both measured
on bash 5.3, 2026-09-30. Nothing shows that a background run is still
reading its file, so edit a copy, or wait for the run to exit.

## Claude Code hooks

Hooks run on every session start or tool call.
Their blast radius is the whole session, so they follow stricter rules
than an ordinary script.

**Observability hooks must never block.** No `set -e`; always `exit 0`;
degrade to a lesser output rather than failing. A logging hook that
aborts takes the session's tool call with it.

**Enforcement hooks** (PreToolUse) use `set -euo pipefail` and signal
through exit codes: `0` allows, `2` blocks with stderr fed back to Claude
as the rejection reason. Any other non-zero is reported as a hook error
and the call proceeds — so a crash fails **open**. Decide deliberately
which side a failure should land on, and say so in the header. **A
deliberate open whose check never ran exits 1, not 0**: Claude Code shows
a non-zero exit's first stderr line as a `hook error` notice, while
stderr from an exit 0 reaches only the debug log (hooks docs, read
2026-09-27), so an exit-0 abstention reads as a clean pass.

**Exit 2's stderr has a different reader per event.** Claude reads it
for PreToolUse; for PreCompact, which it blocks, only the user sees it,
on a manual `/compact`; for SessionStart it is a `hook error` notice
Claude never sees. Plain stdout reaches Claude only from
`UserPromptSubmit`, `UserPromptExpansion`, `SessionStart` and
`PostModelSwitch`, and a PreCompact's `systemMessage` is discarded, so a
hook that tells Claude something about a compaction is SessionStart with
matcher `compact`, which fires after one (hooks docs, read 2026-10-01).

**Bound the lifetime of anything you pipe into.** `jq` reads stdin; if
the hook's shell dies mid-pipeline, `jq` is left blocking on a stdin that
never closes and holds the session's cwd forever. That is enough to make
Windows refuse to rename any ancestor directory — reported as "Access is
denied", indistinguishable from a permissions problem. A stranded `jq`
from `log-instructions-loaded.sh` blocked the `C:\GitHub` -> `C:\Repos`
migration and was invisible to every command-line and window scan.

```bash
jq_input() {
  local rc=0
  printf '%s\n' "$INPUT" | timeout 5 jq "$@" 2>/dev/null || rc=$?
  [[ $rc -eq 126 || $rc -eq 127 ]] || return "$rc"
  printf '%s\n' "$INPUT" | jq "$@" 2>/dev/null
}

if command -v jq >/dev/null 2>&1 \
    && OUT=$(jq_input -c '...'); then
  printf '%s\n' "$OUT" >> "$LOG"
else
  # fallback that still records something
fi
```

**Run `timeout`; never probe for it.** `command -v timeout` proves the
file is on `PATH`, not that it runs: under Defender's ASR rule "Block use
of copied or impersonated system tools", a per-user Git install's
`timeout.exe` exits **126** (measured 2026-09-17), and the probe this
example once carried handed every jq call to a wrapper that never
started, so a guard hook allowed every commit and push with output
identical to a clean pass. 126 and 127, could not execute and not found,
are codes jq's own errors never use, so either retries bare `jq`, and a
healthy call spawns what it did before. To test the fallback, shadow
`timeout` with a file whose shebang names no interpreter (exit 126): a
non-executable file proves nothing, since bash skips it on `PATH` and
runs the real one (2026-09-27).

**Read stdin once** into a variable — `INPUT=$(cat)` — then reuse it.
The payload is consumed on first read.

**Keep hooks cheap.** They run on every matching event; a slow hook is a
tax on every tool call.

## Anti-patterns

- `set -e` assumed to guard a block inside `||` — it does not.
- Unquoted expansions.
- Parsing `ls`; use globs or `find`.
- `cd` without `|| exit` in a script that continues afterwards.
- Piping into a long-lived process with no timeout inside a hook.
- Diagnostics on stdout in a script whose stdout is piped.
- Anything on stdout from a sourced profile — see Output streams.
- Sourcing a `.env` file — it may contain values bash chokes on. Read
  keys with `grep`/`cut` instead, as `sql.sh` does.
- `echo "$var"` for arbitrary data; use `printf '%s\n' "$var"`.
- Hardcoding `/c/...` or `C:\...` when `cygpath` or `$HOME` would do.
- `TZ=<zone> date` for zone arithmetic — it answers UTC; see Preflight.
- A secret, a query or a request body as an argument — see Secrets and
  payloads stay off argv.
- Editing a script while a run of it is still reading — see A running
  script reads its file as it goes.
