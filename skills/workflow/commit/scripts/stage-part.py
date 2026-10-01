#!/usr/bin/env python3
"""Stage part of a file's changes into the index, leaving the working tree alone.

    uv run --no-project python <skill>/scripts/stage-part.py <repo> <path> include <regex>
    uv run --no-project python <skill>/scripts/stage-part.py <repo> <path> exclude <regex>

<repo> is any directory in the repository, and <path> is relative to its top
level, as `git status --short` prints it.

A block is one run of changed lines between two unchanged ones, in a line
diff of the path's index version against its working-tree version. `include`
takes every block holding a line, removed or added, that <regex> matches;
`exclude` takes every block holding none. The index version with the taken
blocks applied is written as a blob and put straight into the index, and the
working tree is never written. Each block prints TAKE or skip, its lines
removed and added, the working-tree line it sits at, and its first line with
text: the audit to read before `git diff --cached`.

The working-tree side is read through git's clean filter, as `git add` would
store it, so a file checked out CRLF stages LF; `git hash-object -w` leaves
that version behind as one unreferenced blob and changes nothing else. The
diff is against the index, not HEAD, so a second run builds on the first,
and `git restore --staged -- <path>` starts the path over.

Exit 0 once a blob is staged; 1 when no block was taken, the index untouched;
2 on a usage error or a path it refuses; git's own code when git fails, with
git's message on stderr. The measurements and the limits are in
references/index-staging.md.
"""
import difflib
import os
import re
import subprocess
import sys

USAGE = "usage: stage-part.py <repo> <path> include|exclude <regex>"
MODES = ("include", "exclude")
# The modes a line diff means anything for: a symlink's blob is its target's
# name, and a submodule's entry is a commit.
FILE_MODES = ("100644", "100755")
# git's own binary test: a NUL in the first 8000 bytes.
SNIFF = 8000

for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        _stream.reconfigure(encoding="utf-8", errors="replace")


def git(repo: str, *args: str, data: bytes | None = None) -> bytes:
    """Run git in repo and return its stdout; git's stderr reaches the caller."""
    return subprocess.run(["git", "-C", repo, *args], input=data,
                          stdout=subprocess.PIPE, check=True).stdout


def refuse(message: str) -> int:
    print(f"error: {message}", file=sys.stderr)
    return 2


def label(lines: list[bytes]) -> str:
    """The block's first line with text, trimmed to one row of the audit."""
    for line in lines:
        text = line.decode("utf-8", "replace").strip()
        if text:
            return text[:70]
    return "(blank lines)"


def main(argv: list[str]) -> int:
    if len(argv) != 4 or argv[2] not in MODES:
        print(USAGE, file=sys.stderr)
        return 2
    repo, path, mode, pattern = argv
    if os.sep == "\\":
        path = path.replace("\\", "/")
    try:
        rx = re.compile(pattern)
    except re.error as exc:
        return refuse(f"bad regex {pattern!r}: {exc}")

    top = git(repo, "rev-parse", "--show-toplevel").decode().strip()
    listing = git(top, "ls-files", "--stage", "-z", "--", f":(literal){path}")
    entries = [meta.split() for meta, _, name in
               (record.partition(b"\t") for record in listing.split(b"\0") if record)
               if name == os.fsencode(path)]
    if not entries:
        return refuse(f"{path} is not in the index, so it has no version to diff against")
    if len(entries) > 1 or entries[0][2] != b"0":
        return refuse(f"{path} is unmerged; resolve it first")
    filemode, old_sha = entries[0][0].decode(), entries[0][1].decode()
    if filemode not in FILE_MODES:
        return refuse(f"{path} has mode {filemode}, not a regular file")

    old = git(top, "cat-file", "blob", old_sha)
    new = git(top, "cat-file", "blob",
              git(top, "hash-object", "-w", "--", path).decode().strip())
    if b"\0" in old[:SNIFF] or b"\0" in new[:SNIFF]:
        return refuse(f"{path} is binary")

    a, b = old.splitlines(keepends=True), new.splitlines(keepends=True)
    out: list[bytes] = []
    blocks = taken = 0
    for tag, i1, i2, j1, j2 in difflib.SequenceMatcher(
            a=a, b=b, autojunk=False).get_opcodes():
        if tag == "equal":
            out += a[i1:i2]
            continue
        blocks += 1
        hit = any(rx.search(line.decode("utf-8", "surrogateescape"))
                  for line in a[i1:i2] + b[j1:j2])
        take = hit if mode == "include" else not hit
        taken += take
        out += b[j1:j2] if take else a[i1:i2]
        print(f"  {'TAKE' if take else 'skip'}  -{i2 - i1} +{j2 - j1}  "
              f"line {j1 + 1}: {label(b[j1:j2] or a[i1:i2])}")
    sys.stdout.flush()  # the audit before any message on stderr
    if not taken:
        reason = "no block taken" if blocks else "no change from the index"
        print(f"{path}: {reason}; the index is untouched", file=sys.stderr)
        return 1
    sha = git(top, "hash-object", "-w", "--stdin", data=b"".join(out)).decode().strip()
    git(top, "update-index", "--cacheinfo", f"{filemode},{sha},{path}")
    print(f"{path}: staged {sha[:10]}, {taken} of {blocks} blocks")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except subprocess.CalledProcessError as exc:
        print(f"error: {' '.join(exc.cmd)} exited {exc.returncode}", file=sys.stderr)
        sys.exit(exc.returncode)
