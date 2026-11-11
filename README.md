<div align="center">

# 🌒 umbriel-dots

<sub><i>Nevil's personal rice — Umbriel compositor + Noctalia shell.</i></sub>

![Arch Linux](https://img.shields.io/badge/Arch-CachyOS-1793D1?logo=arch-linux&logoColor=white)
![Wayland](https://img.shields.io/badge/Wayland-Umbriel-00BFFF)
![Noctalia](https://img.shields.io/badge/Shell-Noctalia%20v5-purple)

</div>

---

## 📌 Nội dung

- [Overview](#-overview)
- [Cấu trúc repo](#-cấu-trúc-repo)
- [Quick Start](#-quick-start)
- [Keybinds chính](#-keybinds-chính)
- [Credits](#-credits)

---

## 🌙 Overview

Dotfile cá nhân được extract trực tiếp từ máy đang chạy, gồm:

- **Umbriel** — compositor native của hệ Noctalia ([docs](https://docs.noctalia.dev/umbriel/)), config đã tinh chỉnh keybinds, autostart Noctalia, NVIDIA workaround.
- **Noctalia shell v5** — settings + user templates + toàn bộ 9 plugins (catwalk, clipper, custom-sticker, dns-switcher, pomodoro, screen-recorder, timer, usb-drive-manager, video-wallpaper).
- **qylock** — lockscreen Quickshell anime-style, bind `Mod+Alt+L`.
- **MikuPlymouth** — boot splash Hatsune Miku với video clips xoay vòng ngẫu nhiên.
- Bộ desktop configs đi kèm: kitty, fastfetch, cava, btop, nvim, yazi, rmpc, mpd, mpv, fish, starship, GTK 3/4 theme css, và fallback niri/hyprland (từ Noctara-Dots).

## 📁 Cấu trúc repo

```
umbriel-dots/
├── configs/              # copy trực tiếp từ ~/.config trên máy gốc
│   ├── umbriel/          # config.toml — compositor (tự reload khi sửa)
│   ├── noctalia/         # settings.toml + user-templates.toml + plugins/
│   ├── kitty/ fastfetch/ cava/ btop/ nvim/ yazi/ rmpc/ mpd/ mpv/ fish/
│   ├── hypr/ niri/       # fallback nếu dùng compositor khác
│   ├── gtk-3.0/ gtk-4.0/ # noctalia.css theme
│   └── starship.toml
├── external/             # git submodules
│   ├── qylock/           # github.com/Darkkal44/qylock
│   └── MikuPlymouth/     # github.com/Thang1191/MikuPlymouth
├── install.sh
└── README.md
```

## 🚀 Quick Start

```bash
# 1. Clone cùng submodules
git clone --recurse-submodules https://github.com/<you>/umbriel-dots
cd umbriel-dots

# 2. Cài deps (CachyOS/Arch)
pacman -S --needed umbriel noctalia-shell kitty fastfetch cava btop \
    neovim yazi rmpc mpd mpv fish starship rsync quickshell

# 3. Chạy installer (tự backup config cũ vào ~/.config-backup-<timestamp>)
./install.sh
#   → deploy toàn bộ ~/.config
#   → cài qylock vào ~/.local/share/quickshell-lockscreen
#   → hỏi ý muốn cài MikuPlymouth (cần sudo, sửa mkinitcpio + grub)

# 4. Reboot (để Plymouth ăn mkinitcpio), vào session Umbriel
```

### Lưu ý khi deploy lên máy khác

- `configs/umbriel/config.toml` bind `Mod+Alt+L` hardcode path `/home/nevil/.local/share/quickshell-lockscreen/lock.sh` — sửa thành `$HOME/...` của bạn.
- `[keybinds]` trong config.toml **thay thế hoàn toàn** keybind mặc định của Umbriel — bind gì mới phải thêm đầy đủ vào file này.
- Noctalia settings ở `configs/noctalia/settings.toml` chỉ là phần override; phần còn lại Noctalia tự quản trong `~/.local/state/noctalia` (không track).
- qylock: một số theme font (Genshin, Minecraft, Nier Automata, Star Rail) không nằm trong upstream repo — nếu dùng theme đó phải tự chép font vào `external/qylock/themes/*/font/`.
- Cập nhật submodules: `git submodule update --remote`

## ⌨️ Keybinds chính

| Key | Action |
|---|---|
| `Mod+Alt+L` | qylock lockscreen |
| `Mod+Shift+L` | Noctalia session lock |
| `Mod+Q` | Close window |
| `XF86Audio*` / `XF86MonBrightness*` | OSD qua Noctalia ( hoạt động cả khi lock) |

Danh sách đầy đủ: `~/.config/umbriel/config.toml` → `[keybinds]`.

## 🙏 Credits

- [Noctara-Dots](https://github.com/deadduck-09/noctara-dots) — base rice, nhiều desktop configs xuất phát từ đây
- [qylock](https://github.com/Darkkal44/qylock) — lockscreen
- [MikuPlymouth](https://github.com/Thang1191/MikuPlymouth) — boot splash
- [Noctalia](https://github.com/noctalia-dev/noctalia-shell) + [Umbriel](https://docs.noctalia.dev/umbriel/) — shell & compositor
