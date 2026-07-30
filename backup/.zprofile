
eval "$(/opt/homebrew/bin/brew shellenv)"

# Created by `pipx` on 2025-06-14 16:05:23
export PATH="$PATH:/Users/riosky/.local/bin"

# Keep MacTeX tools available even in shells that don't inherit path_helper's PATH.
if [[ -d /Library/TeX/texbin && ":$PATH:" != *":/Library/TeX/texbin:"* ]]; then
  export PATH="/Library/TeX/texbin:$PATH"
fi
