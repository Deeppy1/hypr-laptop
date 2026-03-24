#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║        AMONG TREES — HYPRLAND BOOTSTRAP INSTALLER               ║
# ║        github.com/Deeppy1/hypr-laptop                           ║
# ║                                                                  ║
# ║  Run this from a fresh Arch install (post-pacstrap, as a        ║
# ║  normal user with sudo access, NOT as root).                    ║
# ║                                                                  ║
# ║  Usage:  bash install.sh                                        ║
# ╚══════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Colours ────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

REPO_URL="https://github.com/Deeppy1/hypr-laptop"
REPO_RAW="https://raw.githubusercontent.com/Deeppy1/hypr-laptop/main"

# ── Helpers ────────────────────────────────────────────────────────
info()    { echo -e "${CYAN}${BOLD}[•]${RESET} $*"; }
success() { echo -e "${GREEN}${BOLD}[✓]${RESET} $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[!]${RESET} $*"; }
error()   { echo -e "${RED}${BOLD}[✗]${RESET} $*"; exit 1; }

ask() {
    # ask <prompt> — returns 0 (yes) or 1 (no)
    local prompt="$1"
    echo -en "${YELLOW}${BOLD}[?]${RESET} ${prompt} [Y/n] "
    read -r reply
    [[ "${reply:-Y}" =~ ^[Yy]$ ]]
}

# ── Sanity checks ──────────────────────────────────────────────────
[[ $EUID -eq 0 ]] && error "Do not run as root — run as your normal user with sudo access."

if ! command -v pacman &>/dev/null; then
    error "pacman not found. This script is for Arch Linux only."
fi

echo
echo -e "${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║   Among Trees — Hyprland Bootstrap Installer     ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
echo
warn "This will install Hyprland + all supporting packages and apply your dotfiles."
echo

# ══════════════════════════════════════════════════════════════════
#  STEP 1 — Update system
# ══════════════════════════════════════════════════════════════════
info "Updating pacman mirrors and system packages..."
sudo pacman -Syu --noconfirm

# ══════════════════════════════════════════════════════════════════
#  STEP 2 — Install yay (AUR helper) if not present
# ══════════════════════════════════════════════════════════════════
if ! command -v yay &>/dev/null; then
    info "Installing yay (AUR helper)..."
    sudo pacman -S --noconfirm --needed git base-devel
    TMPDIR=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$TMPDIR/yay"
    (cd "$TMPDIR/yay" && makepkg -si --noconfirm)
    rm -rf "$TMPDIR"
    success "yay installed."
else
    success "yay already present."
fi

# ══════════════════════════════════════════════════════════════════
#  STEP 3 — Install packages
# ══════════════════════════════════════════════════════════════════
info "Installing packages (this may take a while)..."

# ── Core Hyprland stack ────────────────────────────────────────────
PACMAN_PKGS=(
    # Hyprland & compositor deps
    hyprland
    hyprpaper
    hyprlock
    hypridle
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk

    # Wayland essentials
    wayland
    wayland-protocols
    wlroots
    qt5-wayland
    qt6-wayland
    glfw-wayland

    # Display / GPU
    mesa
    nvidia-dkms          # swap for vulkan-radeon / nvidia-dkms as needed

    # Waybar
    waybar
    otf-font-awesome

    # Terminal
    kitty

    # App launcher
    rofi-wayland

    # Notifications
    dunst
    libnotify

    # File manager
    thunar
    gvfs
    tumbler       # thumbnails
    ffmpegthumbnailer

    # Browser
    firefox

    # Screenshot
    grimblast
    grim
    slurp

    # Audio (PipeWire stack)
    pipewire
    pipewire-alsa
    pipewire-pulse
    pipewire-jack
    wireplumber
    pavucontrol
    playerctl

    # Bluetooth
    bluez
    bluez-utils
    blueman

    # Network
    networkmanager
    network-manager-applet
    nm-connection-editor

    # Brightness
    brightnessctl

    # Polkit
    polkit-gnome

    # Fonts
    ttf-jetbrains-mono-nerd
    noto-fonts
    noto-fonts-emoji
    ttf-nerd-fonts-symbols

    # Theming
    gtk3
    gtk4
    qt5ct
    qt6ct
    papirus-icon-theme

    # Cursor
    bibata-cursor-theme

    # Utilities
    git
    curl
    wget
    jq
    unzip
    zip
    ripgrep
    fd
    bat
    eza
    fzf
    starship   # shell prompt

    # XDG
    xdg-utils
    xdg-user-dirs
)

sudo pacman -S --noconfirm --needed "${PACMAN_PKGS[@]}" || \
    warn "Some pacman packages may have failed — check output above."

success "Core packages installed."

# ── AUR packages ───────────────────────────────────────────────────
AUR_PKGS=(
    hyprshot                # extra screenshot utility
    wlogout                 # power menu
    swayosd                 # on-screen volume/brightness display
    rose-pine-gtk-theme     # GTK theme (dark, forest-compatible)
    bibata-cursor-theme     # cursor (might already be in pacman)
    nwg-look                # GTK settings for Wayland
)

info "Installing AUR packages..."
yay -S --noconfirm --needed "${AUR_PKGS[@]}" || \
    warn "Some AUR packages may have failed — continuing."

success "AUR packages installed."

# ══════════════════════════════════════════════════════════════════
#  STEP 4 — Enable services
# ══════════════════════════════════════════════════════════════════
info "Enabling system services..."

sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth

# PipeWire — user services
systemctl --user enable --now pipewire
systemctl --user enable --now pipewire-pulse
systemctl --user enable --now wireplumber

success "Services enabled."

# ══════════════════════════════════════════════════════════════════
#  STEP 5 — XDG user dirs
# ══════════════════════════════════════════════════════════════════
info "Setting up XDG user directories..."
xdg-user-dirs-update
success "XDG dirs ready."

# ══════════════════════════════════════════════════════════════════
#  STEP 6 — Pull dotfiles from GitHub
# ══════════════════════════════════════════════════════════════════
info "Pulling config files from ${REPO_URL}..."

# Create target directories
mkdir -p \
    "$HOME/.config/hypr/wallpapers" \
    "$HOME/.config/waybar" \
    "$HOME/.config/rofi" \
    "$HOME/.config/kitty"

# ── hyprland.conf ──────────────────────────────────────────────────
info "  → hyprland.conf"
curl -fsSL "${REPO_RAW}/hyprland.conf" \
    -o "$HOME/.config/hypr/hyprland.conf"

# ── hyprpaper.conf ─────────────────────────────────────────────────
info "  → hyprpaper.conf"
curl -fsSL "${REPO_RAW}/hyprpaper.conf" \
    -o "$HOME/.config/hypr/hyprpaper.conf"

# ── hyprlock.conf ──────────────────────────────────────────────────
info "  → hyprlock.conf"
curl -fsSL "${REPO_RAW}/hyprlock.conf" \
    -o "$HOME/.config/hypr/hyprlock.conf"

# ── waybar config ──────────────────────────────────────────────────
info "  → waybar/config.jsonc"
curl -fsSL "${REPO_RAW}/config.jsonc" \
    -o "$HOME/.config/waybar/config.jsonc"

info "  → waybar/style.css"
curl -fsSL "${REPO_RAW}/style.css" \
    -o "$HOME/.config/waybar/style.css"

# ── rofi theme ─────────────────────────────────────────────────────
info "  → rofi/among-trees.rasi"
curl -fsSL "${REPO_RAW}/among-trees.rasi" \
    -o "$HOME/.config/rofi/among-trees.rasi"

# ── wallpaper ──────────────────────────────────────────────────────
info "  → wallpaper (jpg)"
curl -fsSL "${REPO_RAW}/among-trees-dadaws-small-cliffs.jpg" \
    -o "$HOME/.config/hypr/wallpapers/among-trees-dadaws-small-cliffs.jpg"

success "All dotfiles deployed."

# ══════════════════════════════════════════════════════════════════
#  STEP 7 — Kitty terminal config
# ══════════════════════════════════════════════════════════════════
info "Writing kitty.conf (Among Trees theme)..."
cat > "$HOME/.config/kitty/kitty.conf" << 'EOF'
# ── Among Trees kitty theme ───────────────────────────────────────
font_family      JetBrainsMono Nerd Font
bold_font        JetBrainsMono Nerd Font Bold
italic_font      JetBrainsMono Nerd Font Italic
font_size        12.5

# Colours
background            #0d1a1f
foreground            #f7d8a0
selection_background  #2a5570
selection_foreground  #f7d8a0
cursor                #e8935a
cursor_text_color     #0d1a1f

# Normal
color0   #0d1a1f
color1   #c4614a
color2   #5a8c3a
color3   #e8935a
color4   #2a5570
color5   #9b6a8a
color6   #4a9fb5
color7   #9bbfcc

# Bright
color8   #1a3a4a
color9   #d4715a
color10  #6aaa50
color11  #f4b87a
color12  #4a7a9b
color13  #b08aa0
color14  #6abfd5
color15  #f7d8a0

# Window
background_opacity    0.90
window_padding_width  12
confirm_os_window_close 0

# Misc
enable_audio_bell     no
shell_integration     enabled
EOF
success "kitty.conf written."

# ══════════════════════════════════════════════════════════════════
#  STEP 8 — hypridle (auto-lock on idle)
# ══════════════════════════════════════════════════════════════════
info "Writing hypridle.conf..."
mkdir -p "$HOME/.config/hypr"
cat > "$HOME/.config/hypr/hypridle.conf" << 'EOF'
general {
    lock_cmd      = hyprlock
    before_sleep_cmd = hyprlock
    after_sleep_cmd  = hyprctl dispatch dpms on
}

listener {
    timeout  = 300   # 5 min — dim screen
    on-timeout = brightnessctl -s set 20%
    on-resume  = brightnessctl -r
}

listener {
    timeout  = 360   # 6 min — lock
    on-timeout = hyprlock
}

listener {
    timeout  = 600   # 10 min — screen off
    on-timeout = hyprctl dispatch dpms off
    on-resume  = hyprctl dispatch dpms on
}
EOF
success "hypridle.conf written."

# ══════════════════════════════════════════════════════════════════
#  STEP 9 — GTK / cursor theming
# ══════════════════════════════════════════════════════════════════
info "Applying GTK theme settings..."

mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

cat > "$HOME/.config/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=rose-pine
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
gtk-font-name=Noto Sans 11
gtk-application-prefer-dark-theme=1
EOF

# gtk4 symlink
ln -sf "$HOME/.config/gtk-3.0/settings.ini" \
       "$HOME/.config/gtk-4.0/settings.ini" 2>/dev/null || true

# cursor
mkdir -p "$HOME/.icons/default"
cat > "$HOME/.icons/default/index.theme" << 'EOF'
[Icon Theme]
Name=Default
Comment=Default cursor theme
Inherits=Bibata-Modern-Classic
EOF

success "GTK/cursor theme set."

# ══════════════════════════════════════════════════════════════════
#  STEP 10 — Shell prompt (starship)
# ══════════════════════════════════════════════════════════════════
if command -v starship &>/dev/null; then
    info "Configuring starship prompt (Among Trees palette)..."
    mkdir -p "$HOME/.config"
    cat > "$HOME/.config/starship.toml" << 'EOF'
# Among Trees starship prompt
format = """
[╭─](fg:#2a5570) $directory$git_branch$git_status$cmd_duration
[╰─](fg:#2a5570) $character"""

[directory]
style = "bold fg:#e8935a"
truncate_to_repo = true
truncation_length = 3

[git_branch]
symbol = " "
style  = "fg:#4a9fb5"

[git_status]
style = "fg:#f4b87a"

[character]
success_symbol = "[❯](bold fg:#5a8c3a)"
error_symbol   = "[❯](bold fg:#c4614a)"

[cmd_duration]
style = "fg:#9bbfcc"
min_time = 500
EOF
    # Add to shell rc if not already there
    for RC in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [[ -f "$RC" ]] && ! grep -q "starship init" "$RC"; then
            echo '' >> "$RC"
            echo '# Starship prompt' >> "$RC"
            echo 'eval "$(starship init bash)"' >> "$RC"
        fi
    done
    success "starship configured."
fi

# ══════════════════════════════════════════════════════════════════
#  STEP 11 — Rofi power menu script
# ══════════════════════════════════════════════════════════════════
info "Writing rofi power menu script..."
cat > "$HOME/.config/rofi/powermenu.sh" << 'EOF'
#!/usr/bin/env bash
# Simple power menu entries for rofi -modi power-menu
declare -A OPTIONS
OPTIONS=(
    ["  Shutdown"]="systemctl poweroff"
    ["󰜉  Reboot"]="systemctl reboot"
    ["  Suspend"]="systemctl suspend"
    ["  Lock"]="hyprlock"
    ["󰗽  Logout"]="hyprctl dispatch exit"
)

CHOICE=$(printf '%s\n' "${!OPTIONS[@]}" | sort | rofi -dmenu -p "Power")
[[ -n "$CHOICE" ]] && eval "${OPTIONS[$CHOICE]}"
EOF
chmod +x "$HOME/.config/rofi/powermenu.sh"
success "Power menu script written."

# ══════════════════════════════════════════════════════════════════
#  STEP 12 — SDDM display manager (optional)
# ══════════════════════════════════════════════════════════════════
if ask "Install SDDM display manager (recommended for login screen)?"; then
    sudo pacman -S --noconfirm --needed sddm
    sudo systemctl enable sddm
    # Point SDDM at a Hyprland session
    sudo mkdir -p /usr/share/wayland-sessions
    if [[ ! -f /usr/share/wayland-sessions/hyprland.desktop ]]; then
        sudo tee /usr/share/wayland-sessions/hyprland.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
EOF
    fi
    success "SDDM installed and enabled."
else
    info "Skipping SDDM. You can start Hyprland by adding 'exec Hyprland' to ~/.bash_profile."
fi

# ══════════════════════════════════════════════════════════════════
#  DONE
# ══════════════════════════════════════════════════════════════════
echo
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}${BOLD}║   ✓  Installation complete!                      ║${RESET}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
echo
echo -e "  Configs placed in:"
echo -e "    ${CYAN}~/.config/hypr/${RESET}    — hyprland, hyprlock, hyprpaper, hypridle"
echo -e "    ${CYAN}~/.config/waybar/${RESET}  — bar config + CSS"
echo -e "    ${CYAN}~/.config/rofi/${RESET}    — among-trees.rasi + powermenu.sh"
echo -e "    ${CYAN}~/.config/kitty/${RESET}   — terminal theme"
echo
echo -e "  ${YELLOW}Things to do before first boot:${RESET}"
echo -e "    1. Copy a square photo to ${CYAN}~/.face${RESET} (hyprlock avatar)"
echo -e "    2. Swap ${CYAN}vulkan-intel${RESET} for your GPU driver if needed"
echo -e "       (${BOLD}vulkan-radeon${RESET} / ${BOLD}nvidia-dkms${RESET} + ${BOLD}nvidia-utils${RESET})"
echo -e "    3. Set your keyboard layout in ${CYAN}~/.config/hypr/hyprland.conf${RESET} (currently ${BOLD}gb${RESET})"
echo -e "    4. Reboot, then log in via SDDM → Hyprland"
echo
echo -e "  Keybinds:"
echo -e "    ${BOLD}Super+Return${RESET}   → kitty"
echo -e "    ${BOLD}Super+Space${RESET}    → rofi launcher"
echo -e "    ${BOLD}Super+Shift+L${RESET}  → lock screen"
echo -e "    ${BOLD}Super+Shift+S${RESET}  → screenshot (area)"
echo
