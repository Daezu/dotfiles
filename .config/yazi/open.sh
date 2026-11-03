#!/bin/sh

if [ "$(uname -s)" = Darwin ]; then
  exec open "$@"
fi

exec xdg-open "$@"
