#!/bin/bash
# Fedora 43 / GNOME Hibernate Master Setup
# Author: John Hill-Tanner

# ==========================================
# USER CONFIGURATION REQUIRED
# ==========================================
SWAP_UUID="YOUR-SWAP-UUID-HERE"
SWAP_PARTITION="/dev/nvme0n1p1" # Update to match your block device
# ==========================================

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"
  exit 1
fi

if [ "$SWAP_UUID" == "YOUR-SWAP-UUID-HERE" ]; then
  echo "ERROR: Please edit this script and set your SWAP_UUID and SWAP_PARTITION first."
  exit 1
fi

echo "--- 1. Disabling ZRAM ---"
dnf remove -y zram-generator-defaults
swapoff /dev/zram0 2>/dev/null

echo "--- 2. Enabling Physical Swap ---"
swapon $SWAP_PARTITION
if ! grep -q "$SWAP_UUID" /etc/fstab; then
    echo "UUID=$SWAP_UUID none swap defaults 0 0" >> /etc/fstab
fi

echo "--- 3. Kernel & Initramfs ---"
grubby --update-kernel=ALL --args="resume=UUID=$SWAP_UUID"
echo 'add_dracutmodules+=" resume "' > /etc/dracut.conf.d/resume.conf
dracut -f

echo "--- 4. Systemd Redirection (Suspend -> Hibernate) ---"
ln -sf /usr/lib/systemd/system/systemd-hibernate.service /etc/systemd/system/systemd-suspend.service
mkdir -p /etc/systemd/sleep.conf.d
cat <<INNER_EOF > /etc/systemd/sleep.conf.d/hibernate-only.conf
[Sleep]
AllowSuspend=yes
AllowHibernation=yes
INNER_EOF

echo "--- 5. PolicyKit & SELinux ---"
cat <<INNER_EOF > /etc/polkit-1/rules.d/10-enable-hibernate.rules
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.login1.hibernate" ||
        action.id == "org.freedesktop.login1.hibernate-multiple-sessions" ||
        action.id == "org.freedesktop.upower.hibernate") {
        return polkit.Result.YES;
    }
});
INNER_EOF
restorecon -Rv /etc/systemd/ /etc/polkit-1/rules.d/

echo "--- 6. Installing Extension for User: $SUDO_USER ---"
USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
EXT_UUID="hibernate@the-hill-tanners.fedora"
EXT_DIR="$USER_HOME/.local/share/gnome-shell/extensions/$EXT_UUID"

mkdir -p "$EXT_DIR"
cp hibernate-extension/extension.js "$EXT_DIR/"
cp hibernate-extension/metadata.json "$EXT_DIR/"
chown -R $SUDO_USER:$SUDO_USER "$USER_HOME/.local/share/gnome-shell/extensions/"

systemctl daemon-reload

echo "=========================================================="
echo "FINISHED! REBOOT YOUR MACHINE NOW."
echo " "
echo "After reboot:"
echo "1. Log in."
echo "2. Open GNOME Extensions app and ensure 'Fedora Hibernate' is ON."
echo "3. Go to Power Settings: 'Automatic Suspend' now = Hibernate."
echo "=========================================================="
