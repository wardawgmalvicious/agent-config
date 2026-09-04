---
paths:
  - "**/*.sh"
  - "**/*.bash"
---

# Bash Coding Conventions

Applies to shell scripts across these repos. Two shapes exist and they
have different rules, called out where they diverge:

- **CLI wrappers** — `local-cli/*.sh`, `infra/deploy.sh`.
  Strict-mode scripts a human or agent runs directly.
- **Claude Code hooks** — `agent-config/hooks/*.sh`. Run automatically on
  every session or tool call; see the hooks section.

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
in observability hooks that must never abort — see the hooks section.

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

## Claude Code hooks

Hooks in `agent-config/hooks/` run on every session start or tool call.
Their blast radius is the whole session, so they follow stricter rules
than an ordinary script.

**Observability hooks must never block.** No `set -e`; always `exit 0`;
degrade to a lesser output rather than failing. A logging hook that
aborts takes the session's tool call with it.

**Enforcement hooks** (PreToolUse) use `set -euo pipefail` and signal
through exit codes: `0` allows, `2` blocks with stderr fed back to Claude
as the rejection reason. Any other non-zero is reported as a hook error
and the call proceeds — so a crash fails **open**. Decide deliberately
which side a failure should land on, and say so in the header.

**Bound the lifetime of anything you pipe into.** `jq` reads stdin; if
the hook's shell dies mid-pipeline, `jq` is left blocking on a stdin that
never closes and holds the session's cwd forever. That is enough to make
Windows refuse to rename any ancestor directory — reported as "Access is
denied", indistinguishable from a permissions problem. A stranded `jq`
from `log-instructions-loaded.sh` blocked the `C:\GitHub` -> `C:\Repos`
migration and was invisible to every command-line and window scan.

```bash
JQ=(jq)
if command -v timeout >/dev/null 2>&1; then JQ=(timeout 5 jq); fi

if command -v jq >/dev/null 2>&1 \
    && OUT=$(printf '%s\n' "$INPUT" | "${JQ[@]}" -c '...' 2>/dev/null); then
  printf '%s\n' "$OUT" >> "$LOG"
else
  # fallback that still records something
fi
```

The array form matters: it degrades to bare `jq` where `timeout` is
absent, instead of failing.

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
- Sourcing a `.env` file — it may contain values bash chokes on. Read
  keys with `grep`/`cut` instead, as `sql.sh` does.
- `echo "$var"` for arbitrary data; use `printf '%s\n' "$var"`.
- Hardcoding `/c/...` or `C:\...` when `cygpath` or `$HOME` would do.
