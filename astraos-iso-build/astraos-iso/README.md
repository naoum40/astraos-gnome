# AstraOS ISO Build (Fedora Base)

Build script for AstraOS Live ISO based on Fedora 40 + GNOME 46 + AstraOS extensions.

## Structure

```
astraos-iso/
├── Makefile                    # Build orchestration
├── docker/
│   └── Dockerfile.build        # Fedora 40 + lorax + livemedia-creator
├── kickstart/
│   └── astraos.ks              # Anaconda kickstart (packages + post-install)
├── scripts/
│   └── README.md               # This file
├── out/                        # Built ISO output
└── work/                       # Build temp files
```

## What's in the ISO

### Base system
- Fedora 40 (Linux 6.x kernel)
- GNOME 46 desktop
- PipeWire audio
- NetworkManager + Bluetooth
- Firefox (FR locale)
- Wayland + X11 compatibility

### AstraOS customizations (installed in %post)
- **WhiteSur GTK theme** (Dark, glassy variant)
- **WhiteSur icon theme**
- **WhiteSur cursors**
- **MacOSDock** extension (built with npm) — macOS-style dock with magnification
- **blur-my-shell** — glassmorphism blur effect
- **OriginUI Control Center** + **Private Mode**
- **user-theme** extension (for custom shell themes)
- AstraOS wallpaper (violet gradient fallback)
- AstraOS branding (/etc/os-release, motd, issue)

### GNOME settings applied
- Theme: WhiteSur-Dark
- Button layout: close,minimize,maximize (left side, macOS-style)
- Extensions enabled: MacOSDock, blur-my-shell, user-theme, OriginUI
- Auto-login as `astra` user (no password for live session)
- French locale (fr_FR.UTF-8)
- Touchpad: tap-to-click, natural scroll

## Build requirements

- Docker (or Podman)
- ~10 GB free disk space
- Internet connection (downloads Fedora packages during build)

## Build the ISO

```bash
cd astraos-iso
make build-iso
```

Build time: ~20-40 minutes (depends on network + machine).

Output: `out/AstraOS-0.3.0-x86_64.iso` (~2-3 GB)

## Test the ISO

### Option 1: QEMU with VNC (for Codespaces/headless)
```bash
make test-qemu
```
Then connect to VNC port 5900:
```bash
# On Codespaces, use port forwarding or noVNC
# VNC: localhost:5900
```

### Option 2: VirtualBox (local machine)
1. Copy `out/AstraOS-0.3.0-x86_64.iso` to your machine
2. VirtualBox → New VM → Linux 64-bit
3. RAM: 4096 MB, Disk: 30 GB
4. Mount the ISO as CD
5. Boot → AstraOS live session

### Option 3: Real hardware
1. Flash ISO to USB: `dd if=out/AstraOS-0.3.0-x86_64.iso of=/dev/sdX bs=4M status=progress`
2. Boot from USB
3. AstraOS live session starts

## Login

- User: `astra`
- Password: `astra`
- Auto-login enabled

## Build packs (future)

The Makefile will support packs (Core, Developer, Bureautique, Illustrateur, Gaming) via different kickstart files:
- `kickstart/astraos-core.ks`
- `kickstart/astraos-developer.ks`
- etc.

For now, `astraos.ks` is the Core pack.

## Troubleshooting

### Build fails: "no space left"
Increase Docker disk size or run `docker system prune -a`.

### Build fails: lorax errors
Check `work/lmc-logs/` for detailed anaconda logs.

### ISO boots but GNOME doesn't start
- Press Ctrl+Alt+F2 for TTY
- Login as `astra`
- Run: `journalctl -u gdm -b` to check GDM logs
- Try: `startx` or `gnome-session --session=gnome`

### Extensions not loaded
- Open Terminal
- Run: `gnome-extensions list` to see installed extensions
- Enable manually: `gnome-extensions enable macosdock@vinnytherobot`
- Install Extension Manager: `dnf install gnome-extensions-app`

## Notes

- This is a **test** build to validate Fedora as AstraOS base
- The README on GitHub still says Arch Linux — this is a parallel experiment
- If Fedora works well, we'll migrate the official build to Fedora
- AstraOS Rust apps (AstraPass, games, etc.) are NOT in this ISO yet — they'll be added as RPM packages later

## Compared to Arch (archiso)

| Aspect | Fedora (livemedia-creator) | Arch (archiso) |
|---|---|---|
| Build tool | lorax / livemedia-creator | archiso |
| Config format | Kickstart (.ks) | profiledef.sh + packages.x86_64 |
| Package manager | dnf | pacman |
| Overlay filesystem | via %post script | airootfs/ directory |
| Extension install | git clone in %post | git clone in customize_airootfs.sh |
| ISO size | ~2-3 GB | ~1.5-2 GB |
| Build time | ~20-40 min | ~15-30 min |
| Stability | High (Fedora releases) | Bleeding edge |
| .rpm support | Native | No |
