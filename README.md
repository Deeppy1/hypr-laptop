# Among Trees — Hyprland Theme

Colour palette extracted from *Among Trees* (dadaws / small cliffs biome):
- **Forest floor dark**: `#0d1a1f`
- **Teal fog mid**: `#1a3a4a` / `#2a5570`
- **Amber glow**: `#e8935a` / `#f4b87a`
- **Coral sky**: `#c4614a`
- **Pale gold**: `#f7d8a0`
- **Accent teal**: `#4a9fb5`

---

## File placement

```
~/.config/hypr/
├── hyprland.conf          ← hyprland/hyprland.conf
├── hyprlock.conf          ← hyprland/hyprlock.conf
├── hyprpaper.conf         ← hyprland/hyprpaper.conf
└── wallpapers/
    └── among-trees-dadaws-small-cliffs.jpg   ← your image

~/.config/waybar/
├── config.jsonc           ← waybar/config.jsonc
└── style.css              ← waybar/style.css

~/.config/rofi/
└── among-trees.rasi       ← rofi/among-trees.rasi
```

---

## Font requirement

All configs use **JetBrainsMono Nerd Font**. Install with:
```bash
# Arch
yay -S ttf-jetbrains-mono-nerd

# or copy from Nerd Fonts releases
```

---

## Hyprlock notes

- `~/.face` — set a square avatar image for the user icon on the lockscreen
- The lockscreen blurs the wallpaper with `blur_passes = 3` — adjust to taste
- Invoked via `Super+Shift+L` in the hyprland keybinds

## Rofi notes

- Launcher: `Super+Space`
- Window switcher: `Super+Tab`
- Power menu script path: `~/.config/rofi/powermenu.sh` (create your own or remove that keybind)
