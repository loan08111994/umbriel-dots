<div align="center">

# 🌒 umbriel-dots

<sub><i>Nevil's personal rice — Umbriel compositor + Noctalia shell.</i></sub>

![Arch Linux](https://img.shields.io/badge/Arch-CachyOS-1793D1?logo=arch-linux&logoColor=white)
![Wayland](https://img.shields.io/badge/Wayland-Umbriel-00BFFF)
![Noctalia](https://img.shields.io/badge/Shell-Noctalia%20v5-purple)

</div>

---

## 📌 Contents

- [Overview](#-overview)
- [Repo structure](#-repo-structure)
- [Quick Start](#-quick-start)
- [Vietnamese input method (fcitx5 + Lotus)](#️-vietnamese-input-method-fcitx5--lotus)
- [Limine theme (bootloader)](#-limine-theme-bootloader)
- [Keybinds](#-keybinds)
- [Credits](#-credits)

---

## 🌙 Overview

Personal dotfiles extracted directly from a live machine, including:

- **Umbriel** — the native compositor of the Noctalia ecosystem ([docs](https://docs.noctalia.dev/umbriel/)), with tuned keybinds, Noctalia autostart, and NVIDIA workarounds.
  > 🌈 **Wallpaper-driven border colors:** Noctalia's official builtin template (Settings → Templates → Compositors → Umbriel) generates `~/.config/umbriel/noctalia.toml` from the wallpaper's matugen palette — focused/unfocused borders, title bar, and overview tint all recolor on every wallpaper change. The file is included via `[include.optional]` and **auto-reloads** when Noctalia re-renders it.
- **YAMIS icon theme** (yet-another-monochrome-icon-set, by `dirn` — the upstream repo is no longer public, so it's tracked in `icons/YAMIS/`) — default for GTK3/4 (`settings.ini`) and Qt (via `QT_QPA_PLATFORMTHEME=gtk3` + `[Icons]` in kdeglobals). `install.sh` copies it to `~/.local/share/icons`.
- **fcitx5 + Lotus** — Wayland-native Vietnamese input method ([fcitx5-lotus](https://github.com/LotusInputMethod/fcitx5-lotus), AUR) — the tracked profile already enables `lotus` as the default IM; env vars live in the fish config. See the dedicated section below.
- **zsh + Powerlevel10k** — prompt theme (CachyOS repo packages `zsh-theme-powerlevel10k` + `cachyos-zsh-config`); `configs/zsh/` tracks `.zshrc` + `.p10k.zsh`, deployed to `$HOME`.
- **Noctalia shell v5** — settings + user templates + all 9 plugins (catwalk, clipper, custom-sticker, dns-switcher, pomodoro, screen-recorder, timer, usb-drive-manager, video-wallpaper).
  > ⚠️ Noctalia's real settings live in `~/.local/state/noctalia/settings.toml` (the `noctalia settings` UI writes there), while `~/.config/noctalia/settings.toml` is only an override layer. This repo tracks both: `configs/noctalia/` (override) + `configs/noctalia-state/` (real settings).
- **qylock** — anime-style Quickshell lockscreen, bound to `Mod+Alt+L`.
- **MikuPlymouth** — Hatsune Miku boot splash with randomly rotating video clips.
- Desktop configs included: kitty, fastfetch, cava, btop, nvim, yazi, rmpc, mpd, mpv, fish, starship, GTK 3/4 css themes, plus niri/hyprland fallbacks (from Noctara-Dots).

## 📁 Repo structure

```
umbriel-dots/
├── configs/              # copied directly from ~/.config on the source machine
│   ├── umbriel/          # config.toml — compositor (auto-reloads on edit)
│   ├── noctalia/         # settings.toml + user-templates.toml + plugins/
│   ├── kitty/ fastfetch/ cava/ btop/ nvim/ yazi/ rmpc/ mpd/ mpv/ fish/ fcitx5/
│   ├── hypr/ niri/       # fallback configs for other compositors
│   ├── gtk-3.0/ gtk-4.0/ # noctalia.css theme
│   ├── zsh/              # .zshrc + .p10k.zsh (Powerlevel10k) — deployed to $HOME
│   ├── bash/             # .bashrc + .bash_profile — deployed to $HOME
│   └── starship.toml
├── wallpapers/           # default logos + wallpaper sources
│   ├── Pfps-and-logos/   # crying-cat avatar + icon.png (lockscreen sticker)
│   └── (CozyPixels ~1.9GB — install.sh asks before downloading to
│         ~/Pictures/Wallpapers: Catppuccin, Nord, One Dark, anime, live...)
├── external/             # git submodules
│   ├── qylock/           # github.com/Darkkal44/qylock
│   ├── MikuPlymouth/     # github.com/Thang1191/MikuPlymouth
│   └── catppuccin-limine/ # github.com/catppuccin/limine — bootloader theme
├── boot/
│   └── limine/           # limine-splash.png — boot screen wallpaper
├── fonts/
│   └── qylock/           # fonts missing upstream (Genshin, minecraft, nier-automata,
│                         #   star-rail, terraria) — install.sh copies them in when needed
├── install.sh
├── sync.sh               # reverse sync: machine → repo
└── README.md
```

## 🚀 Quick Start

```bash
# 1. Clone with submodules
git clone --recurse-submodules https://github.com/loan08111994/umbriel-dots
cd umbriel-dots

# 2. Install deps — install.sh asks: pacman first for repo packages,
#    paru only for what's missing on AUR. Manual install:
sudo pacman -S --needed umbriel noctalia xdg-desktop-portal-umbriel quickshell xwayland-satellite nwg-look \
    neovim kitty fastfetch cava btop yazi rmpc mpd mpv fish starship rsync shellcheck thunar code \
    zsh cachyos-zsh-config zsh-theme-powerlevel10k fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool \
    gvfs udisks2 thunar-volman
# AUR only for: GUI apps + fcitx5-lotus (+ core -git packages on plain Arch
# which lacks the CachyOS repos)
paru -S --needed zen-browser-bin helium-browser-bin spotify obsidian-bin fcitx5-lotus-bin

# 3. Run the installer (auto-backs up existing configs to ~/.config-backup-<timestamp>)
./install.sh
#   → deploys all of ~/.config
#   → installs qylock into ~/.local/share/quickshell-lockscreen
#   → asks whether to install MikuPlymouth (needs sudo, patches mkinitcpio + grub)
#   → asks whether to enable miku-rotate.timer: runs install.sh ~1 min after
#     every boot to rotate through all 37 clips (Plymouth only keeps ~10 per boot)
#   → installs the default logos into ~/Pictures/Pfps-and-logos (avatar + icon.png)
#   → ASKS before downloading CozyPixels wallpapers (~1.9GB) to ~/Pictures/Wallpapers
#     (skips automatically if already present)
#
#   The -y / --yes flag auto-answers YES to every prompt for a non-interactive run:
./install.sh --yes
#   (sudo password must still be typed manually when pacman/MikuPlymouth prompt)
#
# Note: install.sh does NOT change your login shell unless you agree at the final
# prompt (chsh → fish). On machines keeping bash/zsh as login shell, fish configs
# still deploy but only apply when running fish; IM env vars come from
# .zshenv/.bashrc instead.

# 4. Reboot (so Plymouth picks up mkinitcpio), enter the Umbriel session
```

### Notes for deploying to another machine

- `configs/umbriel/config.toml` binds `Mod+Alt+L` with the hardcoded path `/home/nevil/.local/share/quickshell-lockscreen/lock.sh` — change it to your own `$HOME/...`.
- `[keybinds]` in config.toml **completely replaces** Umbriel's default keybinds — anything you add must go into this file.
- Noctalia settings in `configs/noctalia/settings.toml` are only the override layer; Noctalia manages the rest in `~/.local/state/noctalia` (not tracked).
- qylock: fonts for some themes (Genshin, Minecraft, Nier Automata, Star Rail, Terraria) **are not tracked upstream** — `install.sh` copies them from `fonts/qylock/<theme>/font/` into `external/qylock/themes/*/font/` after installing. `osumania` and `windows_7` have no fonts anywhere — those themes fall back to the system default font (still works).
- Update submodules: `git submodule update --remote`

## ⌨️ Vietnamese input method (fcitx5 + Lotus)

Input method: [fcitx5-lotus](https://github.com/LotusInputMethod/fcitx5-lotus) (AUR) as an fcitx5 addon. Automatic setup:

```bash
paru -S --needed fcitx5-lotus-bin          # Lotus addon (prebuilt)
sudo udevadm control --reload-rules && sudo udevadm trigger   # /dev/uinput permissions
sudo systemctl enable --now fcitx5-lotus-server@$(whoami).service  # it's a system unit!
```

The rest is already in the repo:

- **`configs/fish/config.fish`**, **`configs/zsh/zshenv`**, **`configs/bash/bashrc`** — IM env vars (`GTK_IM_MODULE`, `QT_IM_MODULE`, `XMODIFIERS=@im=fcitx`...) set for all 3 shells: fish (inside `is-login`), zsh (`.zshenv` — read on every invocation), bash (`.bashrc` — before the interactivity check). Umbriel inherits them no matter which shell launches it
- **`configs/fcitx5/profile`** — `DefaultIM=lotus` + layout `us`
- **Autostart:** `[general].autostart = ["noctalia", "fcitx5 -d"]` in `configs/umbriel/config.toml` (the fcitx5 package's XDG autostart also kicks in — both layers coexist fine since fcitx5 is single-instance)

Usage: `Ctrl+Space` toggles Vietnamese • settings via `fcitx5-configtool` or the Lotus tray icon in Noctalia.

Verify: `fcitx5-diagnose | grep -i wayland` — you should see `frontend:wayland_v2` plus app InputContexts.

> Electron/Chromium apps (zen, code, spotify...): launch with `--enable-wayland-ime --wayland-text-input-version=3` for smooth IM behavior on Wayland.

## 🥾 Limine theme (bootloader)

The machine runs Limine (CachyOS: `/boot/limine.conf`). The repo provides:

- **`external/catppuccin-limine/`** — 4 flavors × 10 accents: `themes/mocha/catppuccin-mocha-pink.conf`...
- **`boot/limine/limine-splash.png`** — splash image (sakura street) for the boot screen

How to configure it yourself (needs sudo because `/boot` is the ESP):

```bash
# 1. Pick a theme — preview each accent's colors:
cat external/catppuccin-limine/themes/mocha/catppuccin-mocha-pink.conf

# 2. Paste the theme contents at the TOP of /boot/limine.conf:
sudo nano /boot/limine.conf

# 3. Copy the splash onto the ESP and reference it (global option — before the first entry):
sudo cp boot/limine/limine-splash.png /boot/limine-splash.png
#    → add to /boot/limine.conf:
#    wallpaper: boot():/limine-splash.png
#    wallpaper_style: centered        # tiled | centered | stretched (default: stretched)
#    backdrop: 1e1e2e                 # fill color when centered (RRGGBB)

# 4. Branding text (empty = hidden):
#    interface_branding:

# 5. Reboot to see the result
```

> ⚠️ CachyOS note: `limine-mkinitcpio-hook` + `limine-snapper-sync` may **overwrite** entries in `limine.conf` on kernel updates — keep your theme edits at the top of the file and don't touch the `entry:` items the hooks generate.

## ⌨️ Keybinds

| Key | Action |
|---|---|
| `Mod+Alt+L` | qylock lockscreen |
| `Mod+Shift+L` | Noctalia session lock |
| `Mod+Q` | Close window |
| `XF86Audio*` / `XF86MonBrightness*` | OSD via Noctalia (works even when locked) |

Full list: `~/.config/umbriel/config.toml` → `[keybinds]`.

## 🙏 Credits

- [Noctara-Dots](https://github.com/deadduck-09/noctara-dots) — base rice, many desktop configs originate here
- [qylock](https://github.com/Darkkal44/qylock) — lockscreen
- [MikuPlymouth](https://github.com/Thang1191/MikuPlymouth) — boot splash
- [CozyPixels](https://github.com/SleepyCatHey/CozyPixels) — wallpaper collection + cat logo
- [catppuccin/limine](https://github.com/catppuccin/limine) — Limine bootloader theme
- [Noctalia](https://github.com/noctalia-dev/noctalia-shell) + [Umbriel](https://docs.noctalia.dev/umbriel/) — shell & compositor
