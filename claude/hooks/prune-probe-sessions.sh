#!/usr/bin/env bash
# prune-probe-sessions.sh — SessionStart hook (matcher "startup", async): at
# most once a day, run prune-probe-sessions.py --apply, which deletes probe
# sessions two days after they last ran. Why it deletes what it deletes is
# in that script's docstring; this file is only the gate in front of it.
#
# Why a hook and not the probe launchers: probes come from /test-skill,
# test-activation.ps1, test-instruction-loading.py, a cold `claude -p` and
# ad hoc checks, and a probe's transcript is the witness its test reads after
# it ends, so no probe can delete itself and no one launcher sees them all.
#
# The sweep needs Python and the Agent SDK through uv, about two seconds warm
# and half a minute over this machine's store: too much for every session,
# and a test run starts dozens of probes. So this decides without spawning
# anything: a probe (its cwd in the temp folder) never sweeps, and a sweep
# under a day old means return at once. Async, so no session waits on it;
# Claude Code cuts it off if the session ends first, which only leaves the
# rest for the next day's run.
#
# Nothing reaches Claude: stdout is discarded and stderr goes to
# ~/.claude/logs/prune-probe-sessions.err. The sweep's record of what it
# deleted is ~/.claude/logs/prune-probe-sessions.log. Always exits 0.

IFS= read -r -d '' INPUT || true
CONFIG_DIR=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
LOG_DIR=$CONFIG_DIR/logs
STAMP=$LOG_DIR/prune-probe-sessions.last
HERE=.
[[ ${BASH_SOURCE[0]} == */* ]] && HERE=${BASH_SOURCE[0]%/*}

# json_value <field>: the field's string value in REPLY, separators as "/".
json_value() {
    local re="\"$1\":\"([^\"]*)\""
    [[ $INPUT =~ $re ]] || return 1
    REPLY=${BASH_REMATCH[1]//\\\\//}
}

# A probe never sweeps. TEMP often spells the profile folder by its 8.3 short
# name while a recorded cwd uses the long one, so LOCALAPPDATA's Temp is
# checked as well.
if json_value cwd; then
    cwd=${REPLY,,}
    for t in "${LOCALAPPDATA:+$LOCALAPPDATA/Temp}" "${TEMP:-}" "${TMP:-}"; do
        t=${t//\\//}
        t=${t,,}
        t=${t%/}
        [[ -n $t && ($cwd == "$t" || $cwd == "$t"/*) ]] && exit 0
    done
fi

printf -v NOW '%(%s)T' -1
LAST=0
[[ -r $STAMP ]] && IFS= read -r LAST <"$STAMP"
[[ $LAST =~ ^[0-9]+$ ]] || LAST=0
((NOW - LAST < 86400)) && exit 0
[[ -d $LOG_DIR ]] || mkdir -p "$LOG_DIR" 2>/dev/null || exit 0
printf '%s\n' "$NOW" >"$STAMP" 2>/dev/null || exit 0

KEEP=()
json_value session_id && KEEP=(--keep "$REPLY")
uv run --quiet --script "$HERE/prune-probe-sessions.py" --apply "${KEEP[@]}" \
    >/dev/null 2>>"$LOG_DIR/prune-probe-sessions.err"
exit 0
