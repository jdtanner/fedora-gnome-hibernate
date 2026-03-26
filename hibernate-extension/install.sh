#!/bin/bash
# install.sh - Installs the Fedora Hibernate GNOME Extension
EXT_UUID="hibernate@the-hill-tanners.fedora"
EXT_DIR="$HOME/.local/share/gnome-shell/extensions/$EXT_UUID"

echo "Creating extension directory..."
mkdir -p "$EXT_DIR"

echo "Copying extension files..."
cp extension.js metadata.json "$EXT_DIR/"

echo "Enabling extension..."
gnome-extensions enable "$EXT_UUID"

echo "--------------------------------------------------------"
echo "INSTALLATION COMPLETE!"
echo "NOTE: You MUST log out and log back in for the button to appear."
echo "--------------------------------------------------------"
