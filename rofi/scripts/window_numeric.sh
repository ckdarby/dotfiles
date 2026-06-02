#!/usr/bin/env bash
set -euo pipefail

detect_wm_msg() {
  if command -v i3-msg >/dev/null 2>&1; then
    printf '%s\n' "i3-msg"
    return 0
  fi

  if command -v swaymsg >/dev/null 2>&1; then
    printf '%s\n' "swaymsg"
    return 0
  fi

  return 1
}

print_nonselectable() {
  local message="$1"
  printf '%s\0nonselectable\x1ftrue\n' "$message"
}

list_windows() {
  local wm_msg
  wm_msg="$(detect_wm_msg || true)"

  printf '\0prompt\x1fWindows (numeric ws)\n'
  printf '\0no-custom\x1ftrue\n'

  if [[ -z "$wm_msg" ]]; then
    print_nonselectable "Install i3-msg or swaymsg to use this mode"
    return 0
  fi

  if ! command -v jq >/dev/null 2>&1; then
    print_nonselectable "Install jq to use this mode"
    return 0
  fi

  local tree
  if ! tree="$("$wm_msg" -t get_tree 2>/dev/null)"; then
    print_nonselectable "Unable to read i3/sway tree"
    return 0
  fi

  local -a rows=()
  mapfile -t rows < <(
    jq -r '
      def sanitize: tostring | gsub("[\r\n]+"; " ");
      def all_nodes: recurse(.nodes[]?, .floating_nodes[]?);
      all_nodes
      | select(.type? == "workspace" and ((.name // "") | test("^[0-9]")))
      | . as $ws
      | ($ws | all_nodes | select(.window? != null))
      | [
          (($ws.name // "?") | sanitize),
          ((.name // "") | sanitize),
          ((.window_properties.class // "") | sanitize),
          ((.window_properties.instance // "") | sanitize),
          (.id | tostring)
        ]
      | join("\u001f")
    ' <<<"$tree"
  )

  if [[ ${#rows[@]} -eq 0 ]]; then
    print_nonselectable "No windows in numeric workspaces"
    return 0
  fi

  local row workspace title class_name instance_name con_id label meta
  for row in "${rows[@]}"; do
    IFS=$'\x1f' read -r workspace title class_name instance_name con_id <<<"$row"

    label="$title"
    [[ -z "$label" ]] && label="$class_name"
    [[ -z "$label" ]] && label="$instance_name"
    [[ -z "$label" ]] && label="(untitled)"
    label="[$workspace] $label"

    meta="$class_name $instance_name $title $workspace"
    printf '%s\0info\x1f%s\x1fmeta\x1f%s\n' "$label" "$con_id" "$meta"
  done
}

focus_selected_window() {
  local con_id="${ROFI_INFO:-}"
  [[ -z "$con_id" ]] && return 0

  local wm_msg
  wm_msg="$(detect_wm_msg || true)"
  [[ -z "$wm_msg" ]] && return 0

  "$wm_msg" "[con_id=$con_id]" focus >/dev/null 2>&1 || true
}

case "${ROFI_RETV:-0}" in
  0)
    list_windows
    ;;
  1)
    focus_selected_window
    ;;
esac
