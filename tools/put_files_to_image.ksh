#!/usr/bin/env bash
set -euo pipefail

CREATE_IMG=0
SIZE="140kb"
POSITIONAL=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--create)
            CREATE_IMG=1
            shift
            ;;
        -s|--size)
            if [[ $# -lt 2 || -z "${2:-}" ]]; then
                echo "error: --size requires a value (e.g. 140kb, 800kb)" >&2
                exit 1
            fi
            SIZE="$2"
            shift 2
            ;;
        --size=*)
            SIZE="${1#*=}"
            if [[ -z "$SIZE" ]]; then
                echo "error: --size requires a value (e.g. 140kb, 800kb)" >&2
                exit 1
            fi
            shift
            ;;
        -h|--help)
            echo "usage: $0 [-c|--create] [-s|--size <size>] <disk-image> <list-of-files> [dest]" >&2
            exit 0
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

set -- "${POSITIONAL[@]+"${POSITIONAL[@]}"}"

if [[ $# -lt 2 || $# -gt 3 ]]; then
    echo "usage: $0 [-c|--create] [-s|--size <size>] <disk-image> <list-of-files> [dest]" >&2
    exit 1
fi

DISK="$1"
FILES="$2"
DEST="${3:-}"
TMP_RAW="/tmp/merlin_inject_$$.raw"

trap 'rm -f "$TMP_RAW"' EXIT

if [[ ! -f "$FILES" ]]; then
    echo "error: file list not found: $FILES" >&2
    exit 1
fi

if [[ "$CREATE_IMG" -eq 1 ]]; then
    acx create -d "$DISK" --prodos --size="$SIZE"
elif [[ ! -f "$DISK" ]]; then
    echo "error: disk image not found: $DISK (use -c to create it)" >&2
    exit 1
fi

if [[ -n "$DEST" ]]; then
    acx mkdir -d "$DISK" "$DEST" 2>/dev/null || true
fi

while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    [[ -z "$line" ]] && continue

    if [[ ! -f "$line" ]]; then
        echo "missing: $line" >&2
        exit 1
    fi

    echo "$line"
    compress_asm_merlin_raw.py < "$line" > "$TMP_RAW"

    name="$(basename "$line")"
    rel_dir="$(dirname "$line")"

    target_dir=""
    if [[ -n "$DEST" && "$rel_dir" != "." ]]; then
        target_dir="$DEST/$rel_dir"
    elif [[ -n "$DEST" ]]; then
        target_dir="$DEST"
    elif [[ "$rel_dir" != "." ]]; then
        target_dir="$rel_dir"
    fi

    if [[ -n "$target_dir" ]]; then
        acx mkdir -d "$DISK" "$target_dir" 2>/dev/null || true
        acx put -f -d "$DISK" --raw -t TXT "$TMP_RAW" -n "$name" --dir="$target_dir"
    else
        acx put -f -d "$DISK" --raw -t TXT "$TMP_RAW" -n "$name"
    fi
done < "$FILES"
