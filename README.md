# Fedora 43 Hibernate Setup

A one-script solution to enable hibernation on Fedora 43 with GNOME, including
a custom extension that adds a "Hibernate..." button to the Quick Settings panel.

---

## What this does

Out of the box, Fedora doesn't support hibernation. There are two reasons for this:

**1. Fedora uses ZRAM by default.**
ZRAM is a compressed chunk of your existing RAM used as virtual swap — it's fast,
but it vanishes when the machine loses power. Hibernation works by writing
everything in RAM to a physical storage device so the session can be restored after
a full power-off. ZRAM can't do that.

**2. GNOME doesn't show a Hibernate button.**
Even once the system supports hibernation, there's no UI option in GNOME 45+.
This repo fixes that too.

The setup script handles all of the following automatically:

- Removes ZRAM and enables your physical swap partition instead
- Tells the kernel where to find the swap partition at boot (the `resume` flag)
- Rebuilds the boot image (initramfs) to include the resume module
- Redirects system sleep calls so that idle timers and lid-close events trigger
  hibernate rather than suspend
- Installs a GNOME extension that adds a "Hibernate..." button to the Power
  submenu in Quick Settings

---

## Before you start

You need three things in place before running the script.

### 1. A dedicated swap partition

This is different from a swapfile. You need a real partition — at least as large
as your total RAM — formatted as swap. If your machine has 16 GB of RAM, you
need a swap partition of at least 17 GB.

To check whether you have one, open a terminal and run:

```bash
lsblk -f
```

Look for a partition with `FSTYPE` listed as `swap`. If you don't have one, you'll
need to create it before continuing. GParted is a straightforward tool for this if
you have unallocated space available.

### 2. Your swap partition's UUID

Once you've confirmed the swap partition exists, note its UUID from the `lsblk -f`
output — it's the long string in the `UUID` column next to your swap partition.
You'll need it in the next step.

### 3. Secure Boot must be disabled

The Linux kernel's security lockdown mode — which is active when Secure Boot is
enabled — blocks hibernation. You'll need to disable Secure Boot in your BIOS/UEFI
settings. The exact steps vary by manufacturer, but the option is usually found
under a "Security" or "Boot" tab. Restart into your BIOS by pressing the relevant
key during startup (commonly F2, F12, or Del, depending on your machine).

---

## Installation

### Step 1: Edit the script

Open `setup-fedora-hibernate.sh` in a text editor and update the two lines near
the top:

```bash
SWAP_UUID="your-uuid-here"
SWAP_PARTITION="/dev/your-device-here"
```

Replace `your-uuid-here` with the UUID you found above, and `your-device-here`
with the device path of your swap partition (for example `/dev/nvme0n1p2` or
`/dev/sda2`).

### Step 2: Run the script

From the repository root directory, run:

```bash
sudo ./setup-fedora-hibernate.sh
```

The script will work through each step and report what it's doing. If anything
goes wrong, it will tell you rather than silently continuing.

### Step 3: Reboot

A full reboot is required. The new kernel parameters won't take effect until the
machine restarts.

---

## Enabling the GNOME extension

After rebooting and logging back in:

1. Open the **Extensions** app. You can search for it in the Activities overview,
   or install it first with `sudo dnf install gnome-extensions-app` if it's not
   already there.
2. Find **Fedora Hibernate** in the list and toggle it on.
3. Click the power icon in the top-right corner of the screen. Under the Power
   section, you'll now see a **"Hibernate..."** option.

---

## Setting up automatic hibernate

Because the script redirects sleep calls at the system level, you don't need any
special configuration for idle-based hibernation:

1. Open **Settings** → **Power**.
2. Under **Automatic Suspend**, set your preferred idle timer.

When that timer expires, the machine will hibernate rather than suspend.

---

## Checking it's working

After rebooting, confirm the kernel has picked up your resume partition:

```bash
cat /proc/cmdline | grep resume
```

You should see `resume=UUID=...` in the output with your swap partition's UUID.

To test hibernation manually:

```bash
sudo systemctl hibernate
```

The machine should power off completely, then restore your session when you turn
it back on.

---

## Troubleshooting

**The machine suspends instead of hibernating**

Check the `systemd-suspend.service` symlink was created correctly:

```bash
ls -la /etc/systemd/system/systemd-suspend.service
```

It should point to `/usr/lib/systemd/system/systemd-hibernate.service`. If not,
re-run the setup script.

**The session doesn't restore after hibernating**

This usually means the kernel couldn't find the resume partition at boot. Run:

```bash
cat /proc/cmdline | grep resume
```

Confirm the UUID matches your swap partition exactly. If it's missing, re-run the
setup script and reboot again.

**The Hibernate button doesn't appear in GNOME**

Make sure the extension is enabled in the Extensions app. If it doesn't appear in
the list at all, check the extension files are in place:

```bash
ls ~/.local/share/gnome-shell/extensions/hibernate@the-hill-tanners.fedora/
```

You should see `extension.js` and `metadata.json`. If the directory is empty or
missing, run the setup script again from the repository root directory.

If the files are there but the button still doesn't appear, check GNOME's log for
extension errors:

```bash
journalctl /usr/bin/gnome-shell -b | grep FedoraHibernate
```

---

## License

MIT — see [LICENSE](LICENSE) for details.
