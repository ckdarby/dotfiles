#!/usr/bin/env bash
set -euo pipefail

readonly VIRTUAL_SINK="obs_desktop"
readonly VIRTUAL_MONITOR="${VIRTUAL_SINK}.monitor"
readonly VIRTUAL_DESC="OBS Desktop Audio"
readonly LOOPBACK_NAME="${VIRTUAL_SINK}_to_headset"
readonly LOOPBACK_LATENCY_MS="${OBS_LOOPBACK_LATENCY_MS:-20}"

take_lock() {
  command -v flock >/dev/null 2>&1 || return 0

  local lock_dir="${XDG_RUNTIME_DIR:-/tmp}"
  [[ -d "$lock_dir" ]] || lock_dir="/tmp"

  exec 9>"${lock_dir}/${VIRTUAL_SINK}-router.lock"
  flock -n 9 || exit 0
}

sink_exists() {
  pactl list short sinks \
    | awk -v sink="$VIRTUAL_SINK" '$2 == sink { found = 1 } END { exit !found }'
}

headset_sink() {
  pactl list short sinks \
    | awk -v virtual="$VIRTUAL_SINK" '
        $2 != virtual && $2 ~ /^bluez_output/ { print $2; exit }
      '
}

ensure_virtual_sink() {
  if ! sink_exists; then
    pactl load-module module-null-sink \
      sink_name="$VIRTUAL_SINK" \
      sink_properties="device.description=${VIRTUAL_DESC}" >/dev/null
  fi

  pactl set-default-sink "$VIRTUAL_SINK"
}

unload_existing_loopbacks() {
  pactl list modules short \
    | awk -v source="$VIRTUAL_MONITOR" '
        /module-loopback/ && index($0, "source=" source) { print $1 }
      ' \
    | while read -r module_id; do
        pactl unload-module "$module_id" || true
      done
}

loopback_exists() {
  local sink="$1"

  pactl list modules short \
    | awk -v source="$VIRTUAL_MONITOR" -v sink="$sink" '
        /module-loopback/ && index($0, "source=" source) && index($0, "sink=" sink) {
          found = 1
        }
        END { exit !found }
      '
}

load_loopback() {
  local sink="$1"

  if pactl load-module module-loopback \
      source="$VIRTUAL_MONITOR" \
      sink="$sink" \
      latency_msec="$LOOPBACK_LATENCY_MS" \
      sink_input_properties="media.name=${LOOPBACK_NAME}" \
      source_dont_move=true \
      sink_dont_move=true >/dev/null 2>&1; then
    return
  fi

  pactl load-module module-loopback \
    source="$VIRTUAL_MONITOR" \
    sink="$sink" \
    latency_msec="$LOOPBACK_LATENCY_MS" \
    sink_input_properties="media.name=${LOOPBACK_NAME}" >/dev/null
}

route_obs_audio() {
  local sink

  ensure_virtual_sink
  sink="$(headset_sink || true)"

  if [[ -z "$sink" ]]; then
    unload_existing_loopbacks
    return
  fi

  loopback_exists "$sink" && return

  unload_existing_loopbacks
  load_loopback "$sink"
}

take_lock
route_obs_audio

pactl subscribe | while read -r _event; do
  route_obs_audio
  sleep 1
  route_obs_audio
done
