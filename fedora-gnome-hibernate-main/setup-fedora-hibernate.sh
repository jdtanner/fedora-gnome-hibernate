#!/bin/bash
# Fedora 43 / GNOME Hibernate Setup
# Author: John Hill-Tanner
#
# This script must be run with sudo from the repository root directory.
# Before running, edit the two variables below.

# ==========================================
# USER CONFIGURATION REQUIRED
# ==========================================
SWAP_UUID="YOUR-SWAP-UUID-HERE"
SWAP_PARTITION="/dev/nvme0n1p1"  # Update to match your swap partition (e.g. /dev/sda2)
# ==========================================

# --- Pre-flight checks ---

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run this script with sudo."
    exit 1
fi

if [ "$SWAP_UUID" = "YOUR-SWAP-UUID-HERE" ]; then
    echo "ERROR: You must edit this script and set SWAP_UUID and SWAP_PARTITION before running."
    echo "       Run 'lsblk -f' to find your swap partition's UUID."
    exit 1
fi

if [ -z "$SUDO_USER" ]; then
    echo "ERROR: SUDO_USER is not set. Please run with sudo rather than as root directly."
    exit 1
fi

if [ ! -f "hibernate-extension/extension.js" ] || [ ! -f "hibernate-extension/metadata.json" ]; then
    echo "ERROR: Extension files not found. Please run this script from the repository root directory."
    exit 1
fi

echo ""
echo "=========================================================="
echo " Fedora Hibernate Setup"
echo "=========================================================="
echo ""

# --- Step 1: Disable ZRAM ---

echo "Step 1/6: Disabling ZRAM..."
dnf remove -y zram-generator-defaults
swapoff /dev/zram0 2>/dev/null || true
echo "Done."
echo ""

# --- Step 2: Enable physical swap ---

echo "Step 2/6: Enabling physical swap partition..."
if ! swapon "$SWAP_PARTITION"; then
    echo "WARNING: swapon failed for $SWAP_PARTITION."
    echo "         The partition may already be active, or the device path may be wrong."
    echo "         Check with 'lsblk -f' and update SWAP_PARTITION in this script if needed."
    echo "         Continuing, but hibernation may not work correctly."
fi
if ! grep -q "$SWAP_UUID" /etc/fstab; then
    echo "UUID=$SWAP_UUID none swap defaults 0 0" >> /etc/fstab
    echo "Added swap entry to /etc/fstab."
else
    echo "Swap entry already present in /etc/fstab, skipping."
fi
echo "Done."
echo ""

# --- Step 3: Kernel resume parameter and initramfs ---

echo "Step 3/6: Configuring kernel resume parameter and rebuilding initramfs..."
grubby --update-kernel=ALL --args="resume=UUID=$SWAP_UUID"
echo 'add_dracutmodules+=" resume "' > /etc/dracut.conf.d/resume.conf
dracut -f
echo "Done."
echo ""

# --- Step 4: Redirect systemd suspend to hibernate ---

echo "Step 4/6: Redirecting system sleep to hibernate..."
ln -sf /usr/lib/systemd/system/systemd-hibernate.service \
       /etc/systemd/system/systemd-suspend.service
mkdir -p /etc/systemd/sleep.conf.d
cat <<EOF > /etc/systemd/sleep.conf.d/hibernate-only.conf
[Sleep]
AllowSuspend=yes
AllowHibernation=yes
EOF
echo "Done."
echo ""

# --- Step 5: PolicyKit and SELinux ---

echo "Step 5/6: Configuring PolicyKit permissions and SELinux labels..."
cat <<EOF > /etc/polkit-1/rules.d/10-enable-hibernate.rules
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.login1.hibernate" ||
        action.id == "org.freedesktop.login1.hibernate-multiple-sessions" ||
        action.id == "org.freedesktop.upower.hibernate") {
        return polkit.Result.YES;
    }
});
EOF
restorecon -Rv /etc/systemd/ /etc/polkit-1/rules.d/ 2>/dev/null || true
echo "Done."
echo ""

# --- Step 6: Install GNOME extension ---

echo "Step 6/6: Installing GNOME extension for user '$SUDO_USER'..."
USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
EXT_UUID="hibernate@the-hill-tanners.fedora"
EXT_DIR="$USER_HOME/.local/share/gnome-shell/extensions/$EXT_UUID"

mkdir -p "$EXT_DIR"
cp hibernate-extension/extension.js "$EXT_DIR/"
cp hibernate-extension/metadata.json "$EXT_DIR/"
chown -R "$SUDO_USER:$SUDO_USER" "$USER_HOME/.local/share/gnome-shell/extensions/"
echo "Done."
echo ""

# --- Reload systemd ---

systemctl daemon-reload

# --- Verification ---

echo "=========================================================="
echo " Verification"
echo "=========================================================="
echo ""
echo "Checking kernel command line for resume parameter..."
if grep -q "resume=UUID=$SWAP_UUID" /proc/cmdline; then
    echo "  OK: resume parameter found (current boot)."
else
    echo "  NOTE: resume parameter not yet in /proc/cmdline -- this is expected"
    echo "        before the first reboot. It will be present after restarting."
fi

echo ""
echo "Checking swap is active..."
if swapon --show | grep -q "$SWAP_PARTITION"; then
    echo "  OK: $SWAP_PARTITION is active."
else
    echo "  WARNING: $SWAP_PARTITION does not appear to be active."
    echo "           Check 'swapon --show' after reboot."
fi

echo ""
echo "=========================================================="
echo " FINISHED -- REBOOT YOUR MACHINE NOW"
echo "=========================================================="
echo ""
echo "After rebooting and logging back in:"
echo ""
echo "  1. Open the Extensions app."
echo "  2. Find 'Fedora Hibernate' and toggle it ON."
echo "  3. A 'Hibernate...' option will appear in Quick Settings"
echo "     under the Power section (top-right corner)."
echo ""
echo "  To test hibernation manually:"
echo "    sudo systemctl hibernate"
echo ""
echo "=========================================================="
