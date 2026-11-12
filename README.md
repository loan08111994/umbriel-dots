<div align="center">

# 🌒 umbriel-dots

<sub><i>Nevil's personal rice — CachyOS · Umbriel compositor · Noctalia shell.</i></sub>

![Arch Linux](https://img.shields.io/badge/Arch-CachyOS-1793D1?logo=arch-linux&logoColor=white)
![Wayland](https://img.shields.io/badge/Wayland-Umbriel-00BFFF)
![Noctalia](https://img.shields.io/badge/Shell-Noctalia%20v5-purple)

</div>

---

## What's inside

| Component | Notes |
|---|---|
| **Umbriel** + Noctalia v5 | Compositor + shell; wallpaper-driven border colors via Noctalia's builtin Umbriel template (`~/.config/umbriel/noctalia.toml`, auto-reloads on wallpaper change) |
| **qylock** lockscreen + SDDM | `Mod+Alt+L` lockscreen; SDDM login uses the **same qylock theme** (theme tracked in `configs/qylock/theme`, currently `R1999_1`) |
| **MikuPlymouth** | Miku boot splash with rotating clips (`miku-rotate.timer` rotates all 37 clips) |
| **fcitx5 + Lotus** | Vietnamese input, Wayland-native — see section below |
| **zsh + Powerlevel10k**, fish, bash | All 3 shells tracked + IM env vars |
| **YAMIS icons** | Tracked in `icons/YAMIS/` (upstream gone); GTK3/4 + Qt default |
| kitty, fastfetch, cava, btop, nvim, yazi, rmpc, mpd, mpv... | Full desktop config set |

## Quick Start

```bash
git clone https://github.com/loan08111994/umbriel-dots   # submodules auto-init if missing
cd umbriel-dots
./install.sh          # or ./install.sh --yes for zero prompts
# → enter sudo password once (timestamp cache), reboot. Done.
```

What `install.sh` does, in order: pacman deps (repo packages only, AUR via paru only for what's missing) → deploy configs (auto-backup to `~/.config-backup-<ts>`, auto-rewrite hardcoded `/home/nevil` → your `$HOME`) → qylock lockscreen with the repo theme (**zero prompts**) → qylock fonts patch → fcitx5-lotus server unit → MikuPlymouth (ask) → miku-rotate timer (ask) → CozyPixels wallpapers ~1.9GB (ask, verified ≥100 files after download, clones to disk not tmpfs) → chsh fish (ask) → SDDM enable + qylock theme as login theme (auto). Full log: `~/.cache/umbriel-dots/*.log`.

Things that stay manual by design: **sudo password**, **reboot**, and the **Limine theme** (below) — a live bootloader file is too dangerous to script.

## Vietnamese input (fcitx5 + Lotus)

Everything except the AUR package is automated (env vars in all 3 shells, profile, autostart, systemd server unit):

```bash
paru -S --needed fcitx5-lotus-bin
```

`Ctrl+Space` toggles Vietnamese. Electron apps (zen, code, spotify) need `--enable-wayland-ime --wayland-text-input-version=3` in their launch flags.

## Limine theme (manual on purpose)

The repo ships the ingredients; you paste them (needs sudo, `/boot` is the ESP — CachyOS hooks may rewrite `limine.conf`, so never let a script touch it):

```bash
cat external/catppuccin-limine/themes/mocha/catppuccin-mocha-pink.conf  # pick a flavor
sudo nano /boot/limine.conf        # paste theme at the TOP of the file
sudo cp boot/limine/limine-splash.png /boot/limine-splash.png
# + global option (before first entry):  wallpaper: boot():/limine-splash.png
```

## Keybinds

| Key | Action |
|---|---|
| `Mod+Alt+L` | qylock lockscreen |
| `Mod+Shift+L` | Noctalia session lock |
| `Mod+Q` | Close window |

`[keybinds]` in `configs/umbriel/config.toml` **replaces** Umbriel's defaults entirely — add new binds there.

## Repo layout

```
configs/          # live configs, mirrored from ~/.config (+ zsh/bash in $HOME)
configs/qylock/theme   # chosen lockscreen/SDDM theme (single source of truth)
wallpapers/       # logos + pfps (CozyPixels 1.9GB downloaded by install.sh)
external/         # submodules: qylock, MikuPlymouth, catppuccin-limine
fonts/qylock/     # fonts upstream doesn't track — patched in by install.sh
icons/YAMIS/      # icon theme (upstream deleted)
install.sh / sync.sh / validate.sh
```

## Sync workflow

- **Machine → repo:** `./sync.sh` (mirrors live configs back, commits + pushes)
- **Repo → machine:** `./install.sh` (deploys + restores everything incl. lockscreen/SDDM theme)
- Logs for both: `~/.cache/umbriel-dots/` (30-day retention)

## Credits

[Noctara-Dots](https://github.com/deadduck-09/noctara-dots) · [qylock](https://github.com/Darkkal44/qylock) · [MikuPlymouth](https://github.com/Thang1191/MikuPlymouth) · [CozyPixels](https://github.com/SleepyCatHey/CozyPixels) · [catppuccin/limine](https://github.com/catppuccin/limine) · [Noctalia](https://github.com/noctalia-dev/noctalia-shell) / [Umbriel](https://docs.noctalia.dev/umbriel/) · [fcitx5-lotus](https://github.com/LotusInputMethod/fcitx5-lotus)
