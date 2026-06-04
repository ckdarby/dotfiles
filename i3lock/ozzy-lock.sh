#!/usr/bin/env bash
set -euo pipefail

# Dependencies:
# imagemagick
# i3lock
# x11-xserver-utils for xrandr display detection

readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/i3lock"
readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/i3lock"
readonly FALLBACK_IMAGE="${CONFIG_DIR}/i3lock.png"
readonly DEFAULT_LOCK_SIZE=3840x2160
readonly BACKGROUND=000000

is_size() {
    [[ "${1:-}" =~ ^[0-9]+x[0-9]+$ ]]
}

detect_sizes() {
    command -v xrandr >/dev/null 2>&1 || {
        printf '%s %s\n' "$DEFAULT_LOCK_SIZE" "$DEFAULT_LOCK_SIZE"
        return 0
    }

    xrandr --query 2>/dev/null \
        | awk -v default_size="$DEFAULT_LOCK_SIZE" '
            /^Screen [0-9]+:/ {
                width = $8
                height = $10
                gsub(",", "", width)
                gsub(",", "", height)
                lock_size = width "x" height
            }

            $2 == "connected" {
                for (i = 3; i <= NF; i++) {
                    if ($i ~ /^[0-9]+x[0-9]+\+[0-9-]+\+[0-9-]+$/) {
                        split($i, parts, /[x+]/)
                        output_size = parts[1] "x" parts[2]

                        if (tile_size == "" || $3 == "primary") {
                            tile_size = output_size
                        }

                        break
                    }
                }
            }

            END {
                if (lock_size == "") {
                    lock_size = default_size
                }

                if (tile_size == "") {
                    tile_size = lock_size
                }

                print lock_size, tile_size
            }
        ' || printf '%s %s\n' "$DEFAULT_LOCK_SIZE" "$DEFAULT_LOCK_SIZE"
}

render_lock_image() {
    local source="$1"
    local output="$2"
    local lock_size="$3"
    local tile_size="$4"

    convert "$source" \
        -resize "${tile_size}^" \
        -gravity center \
        -extent "$tile_size" \
        -write mpr:tile \
        +delete \
        -size "$lock_size" \
        tile:mpr:tile \
        "$output"
}

refresh_image() {
    local lock_size="$1"
    local tile_size="$2"
    local target="$3"
    local tile_width="${tile_size%x*}"
    local tile_height="${tile_size#*x}"
    local url="https://picsum.photos/${tile_width}/${tile_height}?random&blur"
    local tmp_source tmp_target

    [[ "${4:-false}" == true || ! -f "$target" ]] || return 0

    mkdir -p "$CACHE_DIR"

    tmp_source="$(mktemp "${CACHE_DIR}/ozzy-lock.XXXXXX.jpeg")"
    tmp_target="$(mktemp "${CACHE_DIR}/ozzy-lock.XXXXXX.png")"

    if wget -q --timeout=10 --tries=1 -O "$tmp_source" "$url" \
        && render_lock_image "$tmp_source" "$tmp_target" "$lock_size" "$tile_size"; then
        mv "$tmp_target" "$target"
    elif [[ -f "$FALLBACK_IMAGE" ]] \
        && render_lock_image "$FALLBACK_IMAGE" "$tmp_target" "$lock_size" "$tile_size"; then
        mv "$tmp_target" "$target"
    fi

    rm -f "$tmp_source" "$tmp_target"
}

read -r detected_lock_size detected_tile_size < <(detect_sizes)

lock_image="${I3LOCK_LOCK_SIZE:-$detected_lock_size}"
is_size "$lock_image" || lock_image="$DEFAULT_LOCK_SIZE"

tile_image="${I3LOCK_TILE_SIZE:-$detected_tile_size}"
is_size "$tile_image" || tile_image="$lock_image"
cache_image="${CACHE_DIR}/i3lock-${lock_image}.png"

if [[ ! -f "$cache_image" ]]; then
    refresh_image "$lock_image" "$tile_image" "$cache_image" || true
fi

if [[ -f "$cache_image" ]]; then
    i3lock -c "$BACKGROUND" -i "$cache_image" -n
elif [[ -f "$FALLBACK_IMAGE" ]]; then
    i3lock -c "$BACKGROUND" -i "$FALLBACK_IMAGE" -n
else
    i3lock -c "$BACKGROUND" -n
fi

refresh_image "$lock_image" "$tile_image" "$cache_image" true || true
