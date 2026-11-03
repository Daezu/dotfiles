# Add the detected Homebrew prefix for login shells on macOS. The two standard
# locations cover Apple Silicon and Intel without changing Linux PATH setup.
if [[ "$OSTYPE" == darwin* ]]; then
  for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$_brew" ]]; then
      eval "$("$_brew" shellenv)"
      break
    fi
  done
  unset _brew
fi
