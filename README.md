# Fedora 43 GNOME Hibernate Setup

A complete setup script and custom GNOME Shell extension to enable native, secure hibernation on Fedora 43 (GNOME 49+). 

Fedora's default use of `dracut`, `grubby`, SELinux, and ZRAM requires a specific configuration for hibernation. This repository automates that setup.

## Features
* ✅ Safely disables ZRAM in favor of a dedicated physical swap partition.
* ✅ Configures kernel parameters via `grubby`.
* ✅ Rebuilds `initramfs` automatically via `dracut`.
* ✅ Redirects system suspend calls to hibernate via systemd symlinks.
* ✅ Custom GNOME extension for a "Hibernate..." button in the Quick Settings menu.

## Prerequisites
1. **Physical Swap Partition:** You must have a swap partition at least as large as your RAM.
2. **Secure Boot Disabled:** Linux kernel lockdown prevents hibernation when Secure Boot is active.

## Installation
1. Find your swap partition's UUID: `lsblk -f`
2. Update `SWAP_UUID` in `setup-fedora-hibernate.sh`.
3. Run the script: `sudo ./setup-fedora-hibernate.sh`
4. **Reboot.**
5. Install the UI button:
   ```bash
   cd hibernate-extension
   chmod +x install.sh
   ./install.sh
   ```
6. **Log out and log back in.**

## ⏱️ Automatic Hibernation
Because this setup redirects 'suspend' calls to 'hibernate' at the system level, you can use the built-in GNOME **Settings -> Power -> Automatic Suspend** menu. Setting a timer there will now automatically hibernate your machine.

## Testing
Test directly from the terminal:
```bash
sudo systemctl hibernate
```
