# AstraOS Live ISO Kickstart
# Base: Fedora 40 + GNOME 46 + AstraOS extensions
# Build: livemedia-creator --no-virt

# --- Install mode ---
text

# --- Localization ---
lang fr_FR.UTF-8
keyboard fr-latin9
timezone Europe/Paris --isUtc

# --- Network ---
network --bootproto=dhcp --device=link --activate --hostname=astraos

# --- Security ---
rootpw --lock
selinux --permissive
firewall --enabled --service=mdns

# --- Services ---
services --enabled=NetworkManager,gdm,bluetooth,sshd
services --disabled=nfs-server,nfs

# --- Bootloader ---
bootloader --location=mbr --append="rhgb quiet"
zerombr

# --- Partitioning (live image, all in RAM) ---
clearpart --all --initlabel
part / --size=4096 --fstype=ext4

# === PACKAGES ===
%packages
# --- GNOME Desktop ---
@gnome-desktop
@base-x
@hardware-support
@fonts
@multimedia
@networkmanager-submodules
@common

# Core GNOME
gnome-shell
gnome-shell-extensions
gdm
gnome-control-center
gnome-session
gnome-session-wayland-session
gnome-keyring
gnome-tweaks
gnome-terminal
gnome-text-editor
gnome-screenshot
gnome-system-monitor
gnome-disk-utility
gnome-calculator
gnome-calendar
gnome-contacts
gnome-weather
gnome-clocks
gnome-maps
nautilus
baobab
evince
file-roller
yelp

# Wayland
mutter
xdg-desktop-portal
xdg-desktop-portal-gnome
xorg-x11-server-Xwayland

# Audio (PipeWire)
pipewire
pipewire-pulse
pipewire-alsa
pipewire-jack-audio-connect-kit
wireplumber
alsa-utils
alsa-plugins-pulseaudio

# Network
NetworkManager
NetworkManager-wifi
NetworkManager-bluetooth
network-manager-applet
modemmanager
mobile-broadband-provider-info

# Bluetooth
bluez
bluez-tools
gnome-bluetooth

# Fonts
google-noto-sans-fonts
google-noto-sans-math-fonts
google-noto-emoji-fonts
google-noto-color-emoji-fonts
jetbrains-mono-fonts
dejavu-sans-fonts
dejavu-sans-mono-fonts
liberation-fonts

# Browser
firefox
firefox-langpacks-fr

# Build tools (needed for MacOSDock extension build)
nodejs
npm
make
gcc
gcc-c++
pkgconfig

# Version control
git
wget
curl

# Editors
nano
vim-default-editor

# System tools
sudo
htop
fastfetch
baobab
passwd
shadow-utils

# Bootloader
grub2
efibootmgr
shim
syslinux

# Filesystem tools
btrfs-progs
ntfs-3g
dosfstools
exfatprogs
f2fs-tools
xfsprogs
e2fsprogs

# Firmware
linux-firmware
linux-firmware-whence
iwlax2xx-firmware
intel-media-driver
mesa-dri-drivers
mesa-va-drivers
vulkan-loader
vulkan-tools
glx-utils

# AstraOS specific (placeholder for future RPM packages)
# astraos-shell
# astraos-pass
# astraos-defender

# --- Exclusions ---
-unixODBC
-java-11-openjdk
-powerpc-utils
-s390utils
-geolite2-city
-geolite2-country
%end

# === POST INSTALL ===
%post --erroronfail --log=/root/astraos-install.log

set -e
echo "=== AstraOS post-install starting ==="

# --- Create astra user ---
useradd -m -G wheel,video,audio -c "AstraOS User" -s /bin/bash astra
echo 'astra:astra' | chpasswd
echo 'root:astra' | chpasswd

# Sudo without password for live session
echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/astra
chmod 0440 /etc/sudoers.d/astra

# --- Locale ---
echo 'LANG=fr_FR.UTF-8' > /etc/locale.conf
echo 'LC_TIME=fr_FR.UTF-8' >> /etc/locale.conf
locale-gen fr_FR.UTF-8 2>/dev/null || true

# --- Hostname ---
echo 'astraos' > /etc/hostname

# === Install AstraOS extensions and themes ===

EXT_DIR="/usr/share/gnome-shell/extensions"
THEME_DIR="/usr/share/themes"
ICON_DIR="/usr/share/icons"
WALLPAPER_DIR="/usr/share/backgrounds/astraos"

mkdir -p "$EXT_DIR" "$THEME_DIR" "$ICON_DIR" "$WALLPAPER_DIR"
mkdir -p "/etc/dconf/db/local.d"
mkdir -p "/etc/dconf/profile"

# --- [1] WhiteSur GTK Theme ---
echo "[1/6] Installing WhiteSur GTK theme..."
cd /tmp
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git
cd WhiteSur-gtk-theme
./install.sh -t all -N glassy -s standard --default -d "$THEME_DIR" 2>/dev/null || true
cd /tmp
rm -rf WhiteSur-gtk-theme

# --- [2] WhiteSur Icon Theme ---
echo "[2/6] Installing WhiteSur icons..."
cd /tmp
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git
cd WhiteSur-icon-theme
./install.sh -d "$ICON_DIR" 2>/dev/null || true
cd /tmp
rm -rf WhiteSur-icon-theme

# --- [3] WhiteSur Cursors ---
echo "[3/6] Installing WhiteSur cursors..."
cd /tmp
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-cursors.git
cd WhiteSur-cursors
./install.sh -d "$ICON_DIR" 2>/dev/null || true
cd /tmp
rm -rf WhiteSur-cursors

# --- [4] infinityOS extensions (OriginUI + blur-my-shell + user-theme) ---
echo "[4/6] Installing OriginUI + blur-my-shell + user-theme..."
cd /tmp
git clone --depth=1 https://github.com/infinityOS-project/infinityOS-lb-config.git
INFINITY_EXT="/tmp/infinityOS-lb-config/gnome-shell-extensions"

# Copy extensions if they exist
for ext in \
    "OriginUICC@quandz24.extension" \
    "OriginUIPrivateMode@quandz24.extension" \
    "blur-my-shell@aunetx" \
    "user-theme@gnome-shell-extensions.gcampax.github.com"; do
    if [ -d "$INFINITY_EXT/$ext" ]; then
        cp -r "$INFINITY_EXT/$ext" "$EXT_DIR/"
        echo "  -> $ext installed"
    fi
done

cd /tmp
rm -rf infinityOS-lb-config

# --- [5] MacOSDock extension ---
echo "[5/6] Building MacOSDock extension..."
cd /tmp
git clone --depth=1 https://github.com/vinnytherobot/MacOSDock.git
cd MacOSDock

# Build with npm (primary method)
npm install 2>/dev/null && npm run build 2>/dev/null && \
    echo "  -> MacOSDock built with npm" || \
    echo "  -> npm build failed, trying make"

# Fallback: make
make build 2>/dev/null && echo "  -> MacOSDock built with make" || true

# Copy built extension
DOCK_EXT_DIR=$(find . -name "*.extension" -type d 2>/dev/null | head -1)
if [ -z "$DOCK_EXT_DIR" ]; then
    DOCK_EXT_DIR=$(find . -path "*/extensions/*" -name "*.extension" -type d 2>/dev/null | head -1)
fi

if [ -n "$DOCK_EXT_DIR" ] && [ -d "$DOCK_EXT_DIR" ]; then
    cp -r "$DOCK_EXT_DIR" "$EXT_DIR/"
    echo "  -> MacOSDock copied to $EXT_DIR"
else
    # Copy whole build dir as fallback
    cp -r build/* "$EXT_DIR/" 2>/dev/null || true
    echo "  -> MacOSDock: manual copy (check /tmp/MacOSDock)"
fi

cd /tmp
rm -rf MacOSDock

# --- [6] Wallpaper ---
echo "[6/6] Installing wallpaper..."
# Try to download AstraOS wallpaper
wget -q "https://raw.githubusercontent.com/naoum40/AstraOS-Beta/main/assets/wallpapers/default-violet.png" \
    -O "$WALLPAPER_DIR/default-violet.png" 2>/dev/null && \
    echo "  -> Wallpaper downloaded" || \
    echo "  -> Wallpaper download failed (will use default)"

# Create a simple gradient wallpaper as fallback
if [ ! -f "$WALLPAPER_DIR/default-violet.png" ]; then
    cat > /tmp/gen-wallpaper.py << 'PYEOF'
import struct, zlib
w, h = 1920, 1080
# Violet gradient
pixels = []
for y in range(h):
    for x in range(w):
        r = int(129 + (11 - 129) * (y / h))
        g = int(140 + (13 - 140) * (y / h))
        b = int(248 + (23 - 248) * (y / h))
        pixels.append(bytes([r, g, b]))
raw = b"".join(pixels)
def chunk(typ, data):
    c = typ + data
    return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xffffffff)
sig = b"\x89PNG\r\n\x1a\n"
ihdr = struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)
idat = zlib.compress(b"".join(b"\x00" + raw[i:i+w*3] for i in range(0, len(raw), w*3)))
with open("/usr/share/backgrounds/astraos/default-violet.png", "wb") as f:
    f.write(sig + chunk(b"IHDR", ihdr) + chunk(b"IDAT", idat) + chunk(b"IEND", b""))
print("Wallpaper generated")
PYEOF
    python3 /tmp/gen-wallpaper.py 2>/dev/null || true
    rm -f /tmp/gen-wallpaper.py
fi

# === GNOME Settings (dconf) ===

echo "Configuring GNOME settings..."

cat > /etc/dconf/db/local.d/01-astraos << 'DCONFEOF'
# AstraOS GNOME configuration

[org/gnome/desktop/interface]
gtk-theme='WhiteSur-Dark'
icon-theme='WhiteSur-dark'
cursor-theme='WhiteSur-cursors'
font-name='Cantarell 11'
monospace-font-name='JetBrains Mono 11'
color-scheme='prefer-dark'
enable-animations=true
show-battery-percentage=true

[org/gnome/shell]
disable-user-extensions=false
enabled-extensions=['macosdock@vinnytherobot','blur-my-shell@aunetx','user-theme@gnome-shell-extensions.gcampax.github.com','OriginUICC@quandz24.extension']
favorite-apps=['firefox.desktop','org.gnome.Nautilus.desktop','org.gnome.Terminal.desktop','org.gnome.TextEditor.desktop']

[org/gnome/shell/extensions/user-theme]
name='WhiteSur-Dark'

[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/astraos/default-violet.png'
picture-uri-dark='file:///usr/share/backgrounds/astraos/default-violet.png'
picture-options='zoom'
primary-color='#818cf8'
secondary-color='#0b0d17'

[org/gnome/desktop/screensaver]
picture-uri='file:///usr/share/backgrounds/astraos/default-violet.png'
picture-options='zoom'

[org/gnome/desktop/wm/preferences]
button-layout='close,minimize,maximize:'
theme='WhiteSur-Dark'
action-double-click-titlebar='toggle-maximize'
focus-mode='click'

[org/gnome/mutter]
edge-tiling=false
attach-modal-dialogs=true
center-new-windows=true
dynamic-workspaces=true
workspaces-only-on-primary=true

[org/gnome/desktop/peripherals/touchpad]
tap-to-click=true
natural-scroll=true
two-finger-scrolling=true

[org/gnome/settings-daemon/plugins/power]
sleep-inactive-ac-type='nothing'
sleep-inactive-battery-type='suspend'
power-saver-profile-on-low-battery=true

[org/gnome/login-screen]
disable-user-list=false
banner-message-enable=true
banner-message='Bienvenue sur AstraOS'

[org/gnome/desktop/input-sources]
sources=[('xkb', 'fr')]
xkb-options=['terminate:ctrl_alt_bksp']

[org/freedesktop/tracker/miner/files]
crawling-interval='battery-default'
index-recursive-directories=['&DESKTOP','&DOCUMENTS','&DOWNLOAD','&MUSIC','&PICTURES','&VIDEOS']
DCONFEOF

# dconf profile
cat > /etc/dconf/profile/user << 'EOF'
user-db:user
system-db:local
EOF

# Update dconf database
dconf update 2>/dev/null || true

# === GDM auto-login ===
echo "Configuring GDM auto-login..."
mkdir -p /etc/gdm
cat > /etc/gdm/custom.conf << 'GDMEOF'
# GDM custom configuration
[daemon]
WaylandEnable=true
AutomaticLogin=astra
AutomaticLoginEnable=True
# Disable Wayland for debugging if needed:
# WaylandEnable=false

[security]
DisallowRoot=true

[xdmcp]
Enable=false

[chooser]

[debug]
Enable=false
GDMEOF

# === GDM theme (use WhiteSur for login screen) ===
echo "Configuring GDM theme..."
# Copy theme to GDM user
if [ -d "$THEME_DIR/WhiteSur-Dark" ]; then
    mkdir -p /etc/gdm/greeter.dconf
    cat > /etc/gdm/greeter.dconf/01-astraos << 'GREETEREOF'
[org/gnome/desktop/interface]
gtk-theme='WhiteSur-Dark'
icon-theme='WhiteSur-dark'
cursor-theme='WhiteSur-cursors'

[org/gnome/shell]
enabled-extensions=['blur-my-shell@aunetx']

[org/gnome/login-screen]
logo='/usr/share/icons/hicolor/256x256/apps/astraos-logo.png'
disable-user-list=false
GREETEREOF
fi

# === Enable services ===
echo "Enabling services..."
systemctl enable gdm
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable sshd
systemctl enable systemd-resolved
systemctl enable firewalld 2>/dev/null || true

# === Remove unnecessary packages ===
echo "Cleaning up..."
dnf clean all
rm -rf /var/cache/dnf
rm -rf /tmp/*
rm -rf /var/tmp/*

# === AstraOS branding ===
echo "Applying AstraOS branding..."

# OS info
cat > /etc/os-release << 'OSEOFE'
NAME="AstraOS"
VERSION="0.3.0 (GNOME)"
ID=astraos
ID_LIKE=fedora
VERSION_ID=0.3
PLATFORM_ID="platform:f40"
PRETTY_NAME="AstraOS 0.3.0 (GNOME) - Fedora Base"
ANSI_COLOR="0;35"
LOGO=astraos-logo
CPE_NAME="cpe:/o:astraos:0.3.0"
HOME_URL="https://github.com/naoum40/AstraOS-Beta"
BUG_REPORT_URL="https://github.com/naoum40/astraos-iso-test/issues"
OSEOFE

# Motd
cat > /etc/motd << 'MOTDEOF'

    ✦ AstraOS 0.3.0 - GNOME Edition ✦

  Base: Fedora 40 | Desktop: GNOME 46
  User: astra | Password: astra

  Type 'fastfetch' for system info.

MOTDEOF

# Issue
echo "AstraOS 0.3.0 (GNOME)" > /etc/issue
echo "Kernel \r on \m (\l)" >> /etc/issue
echo "" >> /etc/issue

echo "=== AstraOS post-install complete ==="

%end

# === Final reboot/shutdown ===
reboot
