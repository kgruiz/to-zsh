#!/usr/bin/env zsh
set -e

# temporary HOME for isolation
TMPDIR=$(mktemp -d)
export HOME="$TMPDIR"

# stub compdef to avoid requiring compinit
function compdef { :; }

echo "foo=/tmp/foo" > "$HOME/.to_dirs"
echo "bar=/tmp/bar" >> "$HOME/.to_dirs"

source "$(dirname "$0")/../to.zsh"
if ! whence -f _to | grep -q '_arguments'; then
    echo "_to function missing _arguments" >&2
    exit 1
fi
if ! whence -f _to | grep -q -- '--add-bulk'; then
    echo "completion missing --add-bulk" >&2
    exit 1
fi
if ! whence -f _to | grep -q -- '--copy'; then
    echo "completion missing --copy" >&2
    exit 1
fi
if ! whence -f _to | grep -q -- '--no-create'; then
    echo "completion missing --no-create" >&2
    exit 1
fi

echo "tests passed"
