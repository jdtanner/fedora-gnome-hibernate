#!/bin/bash
# install.sh - Installs the Fedora Hibernate GNOME Extension manually.
#
# Use this only if you are installing the extension on its own,
# without running the main setup-fedora-hibernate.sh script.
# This script should be run as your normal user (not with sudo).

EXT_UUID="hibernate@the-hill-tanners.fedora"
EXT_DIR="$HOME/.local/share/gnome-shell/extensions/$EXT_UUID"

# Check we're not running as root
if [ "$EUID" -eq 0 ]; then
    echo "ERROR: Do not run this script with sudo. Run it as your normal user."
    exit 1
fi

# Check the extension files are present
if [ ! -f "extension.js" ] || [ ! -f "metadata.json" ]; then
    echo "ERROR: extension.js and metadata.json not found."
    echo "       Please run this script from inside the hibernate-extension directory."
    exit 1
fi

echo "Creating extension directory..."
mkdir -p "$EXT_DIR"

echo "Copying extension files..."
cp extension.js metadata.json "$EXT_DIR/"

echo ""
echo "=========================================================="
echo " IMPORTANT: You must log out and log back in before"
echo " enabling the extension."
echo ""
echo " After logging back in, open the Extensions app and"
echo " enable 'Fedora Hibernate'."
echo ""
echo " Do NOT run 'gnome-extensions enable' right now -- it"
echo " will have no effect until the shell has reloaded."
echo "=========================================================="
