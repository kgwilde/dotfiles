eval "$(starship init zsh)"

export PATH="$HOME/.local/bin:$PATH"

localZshrcFile="$HOME/.zshrc.local"
if [ -f "$localZshrcFile" ]; then
  source "$localZshrcFile"
fi