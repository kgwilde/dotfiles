export DOTFILES_DIRECTORY="$HOME/dotfiles"

localZshrcFile="$HOME/.zshrc.local"
if [ -f "$localZshrcFile" ]; then
  source "$localZshrcFile"
fi
