#!/usr/bin/env bash
# Exercises claude/hooks/prune-probe-sessions.py, the sweep, and
# prune-probe-sessions.sh, its once-a-day gate, against a fake session store
# and a fake temp folder. No session needed, and nothing outside the temp
# fixture is read or written:
#
#   bash tests/hooks/prune-probe-sessions/test-prune-probe-sessions.sh
#   HOOKS=~/.claude/hooks bash tests/hooks/prune-probe-sessions/test-prune-probe-sessions.sh
#
# Run the second form after scripts/link-claude.ps1: hooks are copies.
#
# The sweep deletes, so every rule that keeps something is planted next to
# one that deletes: a real session whose AI title starts "Probe:", one
# renamed away from "probe:", a scratch folder holding a file, one too new,
# one not named by a session id, a project whose memory holds a file. The
# live store passing proves none of that; a sweep that deleted nothing
# would pass it too. Needs uv; the sweep's first run downloads the Agent
# SDK. The gate's cases hand it a fake uv that only records its arguments.

set -u
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
HOOKS="${HOOKS:-$HERE/../../../claude/hooks}"
SWEEP=$HOOKS/prune-probe-sessions.py
GATE=$HOOKS/prune-probe-sessions.sh
for f in "$SWEEP" "$GATE"; do
    [ -f "$f" ] || {
        echo "missing $f" >&2
        exit 1
    }
done

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
PASS=0
FAIL=0

# Windows long form: what Claude Code records as a cwd and encodes into a
# project folder's name, and what native python needs.
win() { cygpath -w -l "$1" 2>/dev/null || printf '%s\n' "$1"; }
enc() { printf '%s' "$1" | sed 's/[^A-Za-z0-9]/-/g'; }
ok() {
    PASS=$((PASS + 1))
    echo "  ok   $1"
}
bad() {
    FAIL=$((FAIL + 1))
    echo "  FAIL $1"
}
gone() { if [ ! -e "$2" ]; then ok "$1"; else bad "$1: still at $2"; fi; }
kept() { if [ -e "$2" ]; then ok "$1"; else bad "$1: deleted $2"; fi; }

CONF=$WORK/config
TMPROOT=$WORK/tmp
mkdir -p "$CONF/projects" "$TMPROOT/claude"
TMPW=$(win "$TMPROOT")

# transcript <project-folder> <session-id> <cwd> [title-record-json...]
transcript() {
    local dir=$CONF/projects/$1 sid=$2 cwd=$3
    shift 3
    mkdir -p "$dir/memory"
    {
        jq -b -nc --arg s "$sid" --arg c "$cwd" \
            '{type: "user", message: {role: "user", content: "Reply with OK."}, uuid: ("u-" + $s),
              parentUuid: null, sessionId: $s, cwd: $c, gitBranch: "main",
              timestamp: "2026-09-20T00:00:00.000Z", isSidechain: false}'
        jq -b -nc --arg s "$sid" \
            '{type: "assistant", message: {role: "assistant", content: [{type: "text", text: "OK"}]},
              uuid: ("a-" + $s), parentUuid: ("u-" + $s), sessionId: $s,
              timestamp: "2026-09-20T00:00:01.000Z", isSidechain: false}'
        for rec in "$@"; do printf '%s\n' "$rec"; done
    } >"$dir/$sid.jsonl"
}
old() { touch -d '5 days ago' "$@"; }

A=aaaaaaaa-0000-4000-8000-000000000001 # probe: cwd in temp, old
B=bbbbbbbb-0000-4000-8000-000000000002 # probe: named "probe: ...", real cwd, old
C=cccccccc-0000-4000-8000-000000000003 # real session, old
D=dddddddd-0000-4000-8000-000000000004 # real session whose AI title starts "Probe:"
E=eeeeeeee-0000-4000-8000-000000000005 # probe, but fresh
F=ffffffff-0000-4000-8000-000000000006 # probe, old, but --keep
G=99999999-0000-4000-8000-000000000007 # named "probe: ..." once, renamed since
O1=11111111-0000-4000-8000-000000000011 # scratch folder, no transcript, empty, old
O2=22222222-0000-4000-8000-000000000012 # scratch folder, no transcript, holds a file
O3=33333333-0000-4000-8000-000000000013 # scratch folder, no transcript, empty, fresh
O4=44444444-0000-4000-8000-000000000014 # the only folder in its scratch project

PA=$(enc "$TMPW\\probe-a")
PE=$(enc "$TMPW\\probe-e")
PF=$(enc "$TMPW\\probe-f")
PGONE=$(enc "$TMPW\\probe-gone")
REAL=$(enc 'C:\Repos\fixture-real')
REALEMPTY=$(enc 'C:\Repos\fixture-empty')

transcript "$PA" "$A" "$TMPW\\probe-a"
mkdir -p "$CONF/projects/$PA/$A/subagents" "$CONF/session-env/$A" "$CONF/file-history/$A" \
    "$TMPROOT/claude/$PA/$A/scratchpad"
echo x >"$CONF/projects/$PA/$A/subagents/agent-1.jsonl"
echo x >"$CONF/session-env/$A/env"
echo x >"$CONF/file-history/$A/v1"
echo x >"$TMPROOT/claude/$PA/$A/scratchpad/notes.txt"

transcript "$REAL" "$B" 'C:\Repos\fixture-real' '{"type":"custom-title","customTitle":"probe: cold check","sessionId":"'"$B"'"}'
transcript "$REAL" "$C" 'C:\Repos\fixture-real'
transcript "$REAL" "$D" 'C:\Repos\fixture-real' '{"type":"ai-title","aiTitle":"Probe: results review","sessionId":"'"$D"'"}'
transcript "$REAL" "$G" 'C:\Repos\fixture-real' \
    '{"type":"custom-title","customTitle":"probe: x","sessionId":"'"$G"'"}' \
    '{"type":"custom-title","customTitle":"real work","sessionId":"'"$G"'"}'
echo '# memory' >"$CONF/projects/$REAL/memory/MEMORY.md"
transcript "$PE" "$E" "$TMPW\\probe-e"
transcript "$PF" "$F" "$TMPW\\probe-f"
mkdir -p "$CONF/projects/$PGONE/memory" "$CONF/projects/$REALEMPTY/memory"

mkdir -p "$TMPROOT/claude/$REAL/$C" "$TMPROOT/claude/$REAL/$O1/scratchpad" "$TMPROOT/claude/$REAL/$O2" \
    "$TMPROOT/claude/$REAL/$O3" "$TMPROOT/claude/$REAL/not-a-session" "$TMPROOT/claude/orphans/$O4"
echo x >"$TMPROOT/claude/$REAL/$O2/kept.txt"
echo '{}' >"$TMPROOT/claude/cache-break-state-x.json"

old "$CONF/projects/$PA/$A.jsonl" "$CONF/projects/$REAL/"*.jsonl "$CONF/projects/$PF/$F.jsonl"
old "$TMPROOT/claude/$REAL/$C" "$TMPROOT/claude/$REAL/$O1/scratchpad" "$TMPROOT/claude/$REAL/$O1" \
    "$TMPROOT/claude/$REAL/$O2" "$TMPROOT/claude/$REAL/not-a-session" "$TMPROOT/claude/orphans/$O4"

sweep() {
    CLAUDE_CONFIG_DIR=$(win "$CONF") PYTHONIOENCODING=utf-8 \
        uv run --quiet --script "$SWEEP" --temp-dir "$TMPW" --keep "$F" "$@" >"$WORK/out" 2>&1
    echo $? >"$WORK/rc"
}
# everything_kept <label>: no fixture path has gone
everything_kept() {
    local p missing=0
    for p in "$CONF/projects/$PA/$A.jsonl" "$CONF/projects/$REAL/$B.jsonl" "$CONF/projects/$PGONE" \
        "$TMPROOT/claude/$REAL/$O1" "$TMPROOT/claude/orphans"; do
        [ -e "$p" ] || missing=$((missing + 1))
    done
    if [ "$missing" = 0 ]; then ok "$1"; else bad "$1: $missing paths gone"; fi
}

echo "sweep: $SWEEP"
echo "-- report (no --apply) --"
sweep
if [ "$(cat "$WORK/rc")" = 0 ]; then ok "exits 0"; else
    bad "exits $(cat "$WORK/rc")"
    sed 's/^/       | /' "$WORK/out"
fi
if grep -q '^probe sessions idle 2 days or more: 2,' "$WORK/out"; then ok "finds two probes"; else
    bad "finds two probes"
    sed 's/^/       | /' "$WORK/out"
fi
if grep -q "$A.*cwd in the temp folder" "$WORK/out" && grep -q "$B.*named" "$WORK/out"; then
    ok "says why each is a probe"
else bad "says why each is a probe"; fi
if grep -q '^folders holding no file: 6$' "$WORK/out"; then ok "finds six empty folders"; else
    bad "finds six empty folders: $(grep '^folders' "$WORK/out")"
fi
everything_kept "deletes nothing"

echo "-- apply --"
sweep --apply
if [ "$(cat "$WORK/rc")" = 0 ]; then ok "exits 0"; else
    bad "exits $(cat "$WORK/rc")"
    sed 's/^/       | /' "$WORK/out"
fi
gone "probe in temp: transcript" "$CONF/projects/$PA/$A.jsonl"
gone "probe in temp: sidecar folder" "$CONF/projects/$PA/$A"
gone "probe in temp: session-env" "$CONF/session-env/$A"
gone "probe in temp: file-history" "$CONF/file-history/$A"
gone "probe in temp: scratch folder, file and all" "$TMPROOT/claude/$PA/$A"
gone "probe's project folder, memory empty" "$CONF/projects/$PA"
gone "probe's scratch project folder" "$TMPROOT/claude/$PA"
gone "named probe: transcript" "$CONF/projects/$REAL/$B.jsonl"
kept "real session" "$CONF/projects/$REAL/$C.jsonl"
kept "AI title starting Probe: is not a name" "$CONF/projects/$REAL/$D.jsonl"
kept "renamed away from probe:" "$CONF/projects/$REAL/$G.jsonl"
kept "project folder whose memory holds a file" "$CONF/projects/$REAL/memory/MEMORY.md"
kept "fresh probe" "$CONF/projects/$PE/$E.jsonl"
kept "probe passed to --keep" "$CONF/projects/$PF/$F.jsonl"
gone "temp-cwd project folder holding no file" "$CONF/projects/$PGONE"
kept "real project folder holding no file" "$CONF/projects/$REALEMPTY"
gone "orphan scratch folder, empty and old" "$TMPROOT/claude/$REAL/$O1"
kept "orphan scratch folder holding a file" "$TMPROOT/claude/$REAL/$O2/kept.txt"
kept "orphan scratch folder, fresh" "$TMPROOT/claude/$REAL/$O3"
kept "scratch folder not named by a session id" "$TMPROOT/claude/$REAL/not-a-session"
kept "live session's empty scratch folder" "$TMPROOT/claude/$REAL/$C"
gone "scratch project holding only an orphan" "$TMPROOT/claude/orphans"
kept "a file beside the scratch projects" "$TMPROOT/claude/cache-break-state-x.json"
LOG=$CONF/logs/prune-probe-sessions.log
if [ "$(grep -c '"event": "probe-session"' "$LOG" 2>/dev/null)" = 2 ] &&
    grep -q '"event": "run", "sessions": 2,' "$LOG"; then
    ok "logs each probe and the run"
else bad "logs each probe and the run"; fi

echo "-- apply again --"
sweep --apply
if grep -q '^probe sessions idle 2 days or more: 0,' "$WORK/out" &&
    grep -q '^folders holding no file: 0$' "$WORK/out" && [ "$(cat "$WORK/rc")" = 0 ]; then
    ok "finds nothing more"
else
    bad "finds nothing more"
    sed 's/^/       | /' "$WORK/out"
fi

echo "gate: $GATE"
mkdir -p "$WORK/bin" "$WORK/gate" "$WORK/la/Temp/probe-root"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >>"%s"\n' "$WORK/uv-calls" >"$WORK/bin/uv"
chmod +x "$WORK/bin/uv"
GCONF=$WORK/gate/config
LAW=$(win "$WORK/la")
# gate <cwd>: run the gate once; prints how many times uv has been called
gate() {
    jq -b -nc --arg c "$1" '{session_id: "s-1", cwd: $c, hook_event_name: "SessionStart", source: "startup"}' \
        >"$WORK/gate-in.json"
    PATH="$WORK/bin:$PATH" CLAUDE_CONFIG_DIR=$GCONF LOCALAPPDATA=$LAW TEMP='C:\nowhere' TMP='C:\nowhere' \
        bash "$GATE" <"$WORK/gate-in.json" >"$WORK/gate-out" 2>&1
    echo $? >"$WORK/gate-rc"
}
calls() { if [ -f "$WORK/uv-calls" ]; then wc -l <"$WORK/uv-calls" | tr -d ' '; else echo 0; fi; }
expect_calls() { if [ "$(calls)" = "$2" ]; then ok "$1"; else bad "$1: uv called $(calls) times, wanted $2"; fi; }

gate 'C:\Repos\fixture-real'
expect_calls "first session of the day sweeps" 1
if grep -q -- '--script .*prune-probe-sessions.py --apply --keep s-1$' "$WORK/uv-calls"; then
    ok "sweeps with --apply, keeping the session that started it"
else bad "sweep arguments: $(cat "$WORK/uv-calls")"; fi
if [[ $(cat "$GCONF/logs/prune-probe-sessions.last") =~ ^[0-9]+$ ]]; then ok "stamps the run"; else bad "stamps the run"; fi
gate 'C:\Repos\fixture-real'
expect_calls "a second session that day does not" 1
printf -v NOW '%(%s)T' -1
echo $((NOW - 90000)) >"$GCONF/logs/prune-probe-sessions.last"
gate "$LAW\\Temp\\probe-root"
expect_calls "a probe never sweeps, even when one is due" 1
echo 'garbage' >"$GCONF/logs/prune-probe-sessions.last"
gate 'C:\Repos\fixture-real'
expect_calls "a day later, or an unreadable stamp, sweeps" 2
if [ ! -s "$WORK/gate-out" ] && [ "$(cat "$WORK/gate-rc")" = 0 ]; then
    ok "prints nothing and exits 0"
else bad "prints nothing and exits 0: rc $(cat "$WORK/gate-rc"), output $(cat "$WORK/gate-out")"; fi

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
