#!/bin/bash
# Fedora 43 / GNOME Hibernate Setup Script
# Author: John Hill-Tanner

# ==========================================
# USER CONFIGURATION REQUIRED
# ==========================================
# Replace this with the UUID of your physical swap partition.
# You can find it by running: lsblk -f
SWAP_UUID="YOUR-SWAP-UUID-HERE"
SWAP_PARTITION="/dev/nvme0n1p1" # Update to match your block device
# ==========================================

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"
  exit
fi

if [ "$SWAP_UUID" == "YOUR-SWAP-UUID-HERE" ]; then
  echo "ERROR: Please edit this script and set your SWAP_UUID and SWAP_PARTITION first."
  exit 1
fi

echo "=== 1. Disabling and Removing ZRAM ==="
swapoff /dev/zram0 2>/dev/null
dnf remove -y zram-generator-defaults

echo "=== 2. Enabling Physical Swap ==="
swapon $SWAP_PARTITION
if ! grep -q "$SWAP_UUID" /etc/fstab; then
    echo "UUID=$SWAP_UUID none swap defaults 0 0" >> /etc/fstab
fi

echo "=== 3. Updating Kernel Parameters (Grubby) ==="
grubby --update-kernel=ALL --args="resume=UUID=$SWAP_UUID"

echo "=== 4. Rebuilding Initramfs (Dracut) ==="
echo 'add_dracutmodules+=" resume "' > /etc/dracut.conf.d/resume.conf
dracut -f

echo "=== 5. Configuring Systemd & Sleep states ==="
# This symlink redirects all 'suspend' calls to 'hibernate'
ln -sf /usr/lib/systemd/system/systemd-hibernate.service /etc/systemd/system/systemd-suspend.service

mkdir -p /etc/systemd/sleep.conf.d
cat <<INNER_EOF > /etc/systemd/sleep.conf.d/hibernate-only.conf
[Sleep]
AllowSuspend=yes
AllowHibernation=yes
INNER_EOF

mkdir -p /etc/systemd/logind.conf.d
cat <<INNER_EOF > /etc/systemd/logind.conf.d/hibernate-lid.conf
[Login]
HandleLidSwitch=hibernate
HandleLidSwitchExternalPower=hibernate
INNER_EOF

echo "=== 6. Applying PolicyKit Rules ==="
cat <<INNER_EOF > /etc/polkit-1/rules.d/10-enable-hibernate.rules
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.login1.hibernate" ||
        action.id == "org.freedesktop.login1.hibernate-multiple-sessions" ||
        action.id == "org.freedesktop.upower.hibernate") {
        return polkit.Result.YES;
    }
});
INNER_EOF

echo "=== 7. Fixing SELinux Contexts ==="
restorecon -Rv /etc/systemd/system/
restorecon -Rv /etc/systemd/sleep.conf.d/
restorecon -Rv /etc/systemd/logind.conf.d/
restorecon -Rv /etc/polkit-1/rules.d/

echo "=== 8. Reloading Daemons ==="
systemctl daemon-reload

echo "====================================================================="
echo "Setup complete! Please reboot your system to apply all changes safely."
echo " "
echo "NOTE: In GNOME Settings -> Power, 'Automatic Suspend' is now rewired."
echo "Setting an idle timer there will now automatically HIBERNATE your PC."
echo "====================================================================="
