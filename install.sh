#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_PACKAGES=(zsh tmux ghostty)
PINNED_TMUX_VERSION="3.6a"

installHomebrewIfMissing() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

installBrewPackages() {
  brew bundle --file="$DOTFILES_DIRECTORY/Brewfile"
}

cloneTmuxPluginIfMissing() {
  local repositoryUrl="$1"
  local targetDirectory="$2"
  if [ -d "$targetDirectory" ]; then
    return
  fi
  git clone "$repositoryUrl" "$targetDirectory"
}

installTmuxPlugins() {
  cloneTmuxPluginIfMissing \
    "https://github.com/catppuccin/tmux" \
    "$HOME/.config/tmux/plugins/catppuccin/tmux"
  cloneTmuxPluginIfMissing \
    "https://github.com/tmux-plugins/tmux-battery" \
    "$HOME/.config/tmux/plugins/tmux-battery"
}

backupExistingFile() {
  local targetPath="$1"
  if [ ! -e "$targetPath" ] && [ ! -L "$targetPath" ]; then
    return
  fi
  if [ -L "$targetPath" ]; then
    return
  fi
  mv "$targetPath" "$targetPath.backup"
}

backupConflictingDotfiles() {
  backupExistingFile "$HOME/.zshrc"
  backupExistingFile "$HOME/.tmux.conf"
  backupExistingFile "$HOME/.config/ghostty/config"
}

stowPackages() {
  for package in "${STOW_PACKAGES[@]}"; do
    stow --target="$HOME" --dir="$DOTFILES_DIRECTORY" --restow "$package"
  done
}

isPinnedTmuxVersionInstalled() {
  if ! command -v tmux >/dev/null 2>&1; then
    return 1
  fi
  local installedVersion
  installedVersion="$(tmux -V | awk '{print $2}')"
  [ "$installedVersion" = "$PINNED_TMUX_VERSION" ]
}

installTmuxFromSource() {
  if isPinnedTmuxVersionInstalled; then
    return
  fi

  local buildDirectory
  buildDirectory="$(mktemp -d)"

  git clone --branch "$PINNED_TMUX_VERSION" --depth 1 https://github.com/tmux/tmux.git "$buildDirectory"

  local homebrewPrefix
  homebrewPrefix="$(brew --prefix)"

  (
    cd "$buildDirectory"
    sh autogen.sh
    PKG_CONFIG_PATH="$homebrewPrefix/lib/pkgconfig" ./configure \
      --prefix="$homebrewPrefix" \
      --enable-utf8proc \
      LDFLAGS="-L$homebrewPrefix/lib" \
      CPPFLAGS="-I$homebrewPrefix/include"
    make
    make install
  )

  rm -rf "$buildDirectory"
}

main() {
  installHomebrewIfMissing
  installBrewPackages
  installTmuxFromSource
  backupConflictingDotfiles
  stowPackages
  installTmuxPlugins
}

main
