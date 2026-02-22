#!/usr/bin/env bash
# Symlink dotfiles from repo into $HOME
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}"

files=(.bashrc .profile)

for file in "${files[@]}"; do
    src="${DOTFILES_DIR}/${file}"
    dest="${TARGET_DIR}/${file}"

    [ ! -f "$src" ] && continue

    # Backup existing file (skip if already a symlink to us)
    if [ -f "$dest" ] && [ ! -L "$dest" ]; then
        cp "$dest" "${dest}.bak.$(date +%Y%m%d%H%M%S)"
        echo "Backed up ${dest}"
    fi

    ln -sf "$src" "$dest"
    echo "Linked ${dest} → ${src}"
done

echo "Done. Run 'source ~/.bashrc' or start a new shell."
