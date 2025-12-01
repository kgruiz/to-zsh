#!/usr/bin/env zsh
set -e

# temporary HOME for isolation
TMPDIR=$(mktemp -d)
export HOME="$TMPDIR"
export TO_CONFIG_FILE="$HOME/.to_dirs"
export TO_CONFIG_META_FILE="$HOME/.to_dirs_meta"
export TO_USER_CONFIG_FILE="$HOME/.to_zsh_config"
export TO_RECENT_FILE="$HOME/.to_dirs_recent"

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
if ! whence -f _to | grep -q -- '--sort'; then
    echo "completion missing --sort" >&2
    exit 1
fi
if ! whence -f _to | grep -q '_path_files'; then
    echo "completion missing _path_files" >&2
    exit 1
fi
if ! whence -f _to | grep -q 'GetSortedKeywords'; then
    echo "completion missing GetSortedKeywords" >&2
    exit 1
fi

if ! whence -w GetSortedKeywords >/dev/null; then
    echo "GetSortedKeywords not defined globally" >&2
    exit 1
fi

keywords=($(GetSortedKeywords))
if [[ ${#keywords[@]} -ne 2 ]]; then
    echo "GetSortedKeywords returned unexpected count: ${#keywords[@]}" >&2
    exit 1
fi

if [[ ${keywords[1]} != foo || ${keywords[2]} != bar ]]; then
    echo "GetSortedKeywords returned unexpected order: ${keywords[*]}" >&2
    exit 1
fi

echo "tests passed"
