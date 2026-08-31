#!/bin/bash

TARGET_CLASS="^(org.pulseaudio.pavucontrol|nm-connection-editor|blueman-manager)$"

handle() {
  case $1 in
    activewindow\>\>*)
      FOCUSED_CLASS=$(echo "$1" | cut -d'>' -f3 | cut -d',' -f1)
      if [[ ! "$FOCUSED_CLASS" =~ $TARGET_CLASS ]]; then
        hyprctl dispatch "hl.dsp.window.close({ window = 'class:${TARGET_CLASS}'})" 2>/dev/null
      fi
      ;;
  esac
}

socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock \
  | while read -r line; do handle "$line"; done


