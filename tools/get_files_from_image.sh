#!/usr/bin/env ksh
set -eu

OUT_DIR="."
PREFIX=""

while [ $# -gt 0 ]; do
    case "$1" in
        -o|--output)
            if [ $# -lt 2 ] || [ -z "${2:-}" ]; then
                echo "error: --output requires a directory path" >&2
                exit 1
            fi
            OUT_DIR="$2"
            shift 2
            ;;
        --output=*)
            OUT_DIR="${1#*=}"
            if [ -z "$OUT_DIR" ]; then
                echo "error: --output requires a directory path" >&2
                exit 1
            fi
            shift
            ;;
        -p|--prefix)
            if [ $# -lt 2 ] || [ -z "${2:-}" ]; then
                echo "error: --prefix requires a value" >&2
                exit 1
            fi
            PREFIX="$2"
            shift 2
            ;;
        --prefix=*)
            PREFIX="${1#*=}"
            if [ -z "$PREFIX" ]; then
                echo "error: --prefix requires a value" >&2
                exit 1
            fi
            shift
            ;;
        -h|--help)
            echo "usage: $0 [-o|--output <dir>] [-p|--prefix <pfx>] <disk-image> <list-of-files> [dest_dir]" >&2
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "error: unknown option: $1" >&2
            echo "usage: $0 [-o|--output <dir>] [-p|--prefix <pfx>] <disk-image> <list-of-files> [dest_dir]" >&2
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    echo "usage: $0 [-o|--output <dir>] [-p|--prefix <pfx>] <disk-image> <list-of-files> [src_dir]" >&2
    exit 1
fi

DISK="$1"
FILES="$2"
DEST_DIR="${3:-}"
TMP_RAW="/tmp/merlin_extract_$$.raw"

trap 'rm -f "$TMP_RAW"' EXIT

if [ -z "$DISK" ] || [ ! -f "$DISK" ]; then
    echo "error: disk image not found: $DISK" >&2
    exit 1
fi

if [ -z "$FILES" ] || [ ! -f "$FILES" ]; then
    echo "error: file list not found: $FILES" >&2
    exit 1
fi

mkdir -p "$OUT_DIR"

while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    [ -z "$line" ] && continue

    echo "$line"

#    name="$(basename "$line")"
#    rel_dir="$(dirname "$line")"
#    src_name="${PREFIX}${name}"
    name="$(basename "$line")"
    rel_dir="$(dirname "$line")"

    if [ "$rel_dir" != "." ]; then
        if [ -n "$PREFIX" ]; then
            img_path=${PREFIX}"/"${rel_dir}/${name}
        else
            img_path="$rel_dir/$name"
        fi
    else
        if [ -n "PREFIX" ]; then
            img_path="$PREFIX/$name"
        else
            img_path="$name"
        fi
    fi

    rm -f "$TMP_RAW"
    acx get -d "$DISK" --method=text -o "$TMP_RAW" "$img_path"

    out_path="$OUT_DIR/$line"
    target_parent="$(dirname "$out_path")"
    mkdir -p "$target_parent"
    reformat_asm_merlin.py < "$TMP_RAW" > "$out_path"
done < "$FILES"

