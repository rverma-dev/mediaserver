#!/usr/bin/env bash
set -euo pipefail

# Extract GPG key ID and update Git config
GNUPGHOME="${1:-$HOME/.gnupg}"
export GNUPGHOME

EMAIL="rverma-dev@users.noreply.github.com"

# Get the key ID
KEY_ID=$(gpg --list-secret-keys --keyid-format LONG "$EMAIL" | grep sec | awk '{print $2}' | cut -d'/' -f2)

if [ -z "$KEY_ID" ]; then
    echo "No GPG key found for $EMAIL"
    exit 1
fi

echo "Found GPG key ID: $KEY_ID"

# Update Git config
git config --global user.signingkey "$KEY_ID"
git config --global commit.gpgsign true
git config --global tag.gpgsign true

echo "Git GPG configuration updated!"
echo "Key ID: $KEY_ID"
echo "Commit signing: $(git config --global commit.gpgsign)"
echo "Tag signing: $(git config --global tag.gpgsign)"
