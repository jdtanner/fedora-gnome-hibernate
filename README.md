# Fedora 43 GNOME Hibernate Master Setup

A comprehensive, all-in-one automation script to enable native hibernation on Fedora 43 (GNOME 49+) and inject a "Hibernate..." button directly into the Quick Settings menu.

## 🚀 The Problem
By default, Fedora uses **ZRAM**, which is great for performance but makes hibernation impossible because there is no persistent storage for the RAM image. Additionally, GNOME 49+ does not expose a "Hibernate" option in the UI, and its "Automatic Suspend" feature doesn't naturally support hibernating to disk.

## ✨ The Solution
This repository provides a master script that automates the complex system-level changes required for Fedora:
* ✅ **Disables ZRAM:** Removes `zram-generator` to prevent conflicts.
* ✅ **Enables Physical Swap:** Configures your persistent swap partition in `/etc/fstab`.
* ✅ **Kernel Resume:** Uses `grubby` to set the `resume=UUID=...` flag for the bootloader.
* ✅ **Initramfs Update:** Automatically rebuilds the `dracut` images with the `resume` module.
* ✅ **Systemd Redirection:** Symlinks `systemd-suspend` to `systemd-hibernate`, so **any** sleep call (Lid close, Idle timer) triggers a safe hibernate.
* ✅ **UI Extension:** Installs a custom GNOME Extension to put a "Hibernate..." button in the Power submenu.

---

## 📋 Prerequisites
1. **Physical Swap Partition:** You **must** have a dedicated swap partition (not a swapfile) that is at least the size of your RAM (e.g., if you have 16GB RAM, you need a 17GB+ Swap partition).
2. **Secure Boot:** Must be **Disabled** in your BIOS/UEFI. The Linux kernel lockdown prevents hibernation when Secure Boot is active.
3. **Swap UUID:** You will need your swap partition's UUID. Run `lsblk -f` to find it.

---

## 🛠️ Installation

### 1. Configure the Script
Open `setup-fedora-hibernate.sh` and update the top two variables:
```bash
SWAP_UUID="your-uuid-here"
SWAP_PARTITION="/dev/your-device-here"
```

### 2. Run the Setup
```bash
sudo ./setup-fedora-hibernate.sh
```

### 3. Reboot
A full system reboot is required to load the new kernel parameters and rebuild the initramfs.

---

## ⏱️ How to use "Automatic Hibernate"
Because this script symlinks the system sleep calls, you don't need a special menu for idle timers. 
1. Open GNOME **Settings** -> **Power**.
2. Go to **Automatic Suspend**.
3. Set your desired idle time. 
**When the timer hits zero, the machine will now Hibernate instead of Suspend.**

---

## 🔧 Enabling the UI Button
After rebooting and logging back in:
1. Open the **Extensions** app (or `gnome-extensions-app`).
2. Locate **Fedora Hibernate** and toggle it **ON**.
3. Your "Hibernate..." button will now appear in the Quick Settings (top right) under the Power section.

---

## 🧪 Testing & Verification
To verify the kernel sees your resume partition:
```bash
cat /proc/cmdline | grep resume
```
To test a manual hibernation:
```bash
sudo systemctl hibernate
```

## ⚖️ License
Distributed under the MIT License. Created by John Hill-Tanner.
