#!/usr/bin/env bash
# Guard for the deterministic-build compile-check CI job.
#
# Re-running compile.sh may tweak comment lines in the requirements files:
# pip-compile records the Python version and the constraint-file path in
# '#' comments, which can differ across environments without changing what
# actually gets installed. Such comment-only differences are tolerated.
# The check fails only when package pins or --hash lines change, or when
# compile.sh leaves build artifacts behind as untracked files.
set -euo pipefail

untracked_files="$(git ls-files --others --exclude-standard)"
if [ -n "$untracked_files" ]; then
    echo "compile.sh left untracked files behind:" >&2
    printf '%s\n' "$untracked_files" >&2
    exit 1
fi

# Reduce the diff to just the added/removed lines that carry real content:
#   1. keep only +/- lines (the patch body),
#   2. drop the +++/--- file headers,
#   3. drop comment lines (first non-space char is '#'),
#   4. drop blank lines.
meaningful_changes="$(
    git --no-pager diff HEAD \
        | grep -E '^[+-]' \
        | grep -vE '^[+-][+-]' \
        | grep -vE '^[+-][[:space:]]*#' \
        | grep -vE '^[+-][[:space:]]*$' \
        || true
)"

if [ -n "$meaningful_changes" ]; then
    echo "compile.sh produced changes to pins or hashes:" >&2
    git status --short >&2
    git --no-pager diff HEAD >&2
    exit 1
fi
