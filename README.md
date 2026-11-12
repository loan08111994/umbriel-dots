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
  > ⚠️ Settings thật của Noctalia nằm ở `~/.local/state/noctalia/settings.toml` (UI `noctalia settings` ghi vào đây), còn `~/.config/noctalia/settings.toml` chỉ là override layer. Repo này lưu cả hai: `configs/noctalia/` (override) + `configs/noctalia-state/` (settings thật).
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
├── wallpapers/           # logo mặc định + nguồn wallpapers
│   ├── Pfps-and-logos/   # avatar mèo khóc + icon.png (lockscreen sticker)
│   └── (CozyPixels ~1.9GB — install.sh sẽ hỏi trước khi tải về
│         ~/Pictures/Wallpapers: Catppuccin, Nord, One Dark, anime, live...)
├── external/             # git submodules
│   ├── qylock/           # github.com/Darkkal44/qylock
│   └── MikuPlymouth/     # github.com/Thang1191/MikuPlymouth
├── install.sh
├── sync.sh               # đồng bộ ngược máy → repo
└── README.md
```

## 🚀 Quick Start

```bash
# 1. Clone cùng submodules
git clone --recurse-submodules https://github.com/loan08111994/umbriel-dots
cd umbriel-dots

# 2. Cài deps — install.sh sẽ tự hỏi: pacman trước cho repo packages,
#    paru chỉ lo phần AUR còn thiếu. Cài tay thì:
sudo pacman -S --needed umbriel noctalia xdg-desktop-portal-umbriel quickshell \
    neovim kitty fastfetch cava btop yazi rmpc mpd mpv fish starship rsync shellcheck thunar code
# AUR chỉ cần cho: GUI apps + (Arch thường không có repo CachyOS thì thêm core -git)
paru -S --needed zen-browser-bin helium-browser-bin spotify obsidian-bin

# 3. Chạy installer (tự backup config cũ vào ~/.config-backup-<timestamp>)
./install.sh
#   → deploy toàn bộ ~/.config
#   → cài qylock vào ~/.local/share/quickshell-lockscreen
#   → hỏi ý muốn cài MikuPlymouth (cần sudo, sửa mkinitcpio + grub)
#   → hỏi ý muốn bật miku-rotate.timer: tự chạy install.sh mỗi ngày 1 phút
#     sau boot để xoay vòng đủ 37 clips (Plymouth chỉ giữ ~10 clips/lần)
#   → cài logo mặc định vào ~/Pictures/Pfps-and-logos (avatar + icon.png)
#   → HỎI trước khi tải CozyPixels wallpapers (~1.9GB) về ~/Pictures/Wallpapers
#     (bỏ qua tự động nếu máy đã có sẵn)

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
- [CozyPixels](https://github.com/SleepyCatHey/CozyPixels) — wallpaper collection + logo mèo
- [Noctalia](https://github.com/noctalia-dev/noctalia-shell) + [Umbriel](https://docs.noctalia.dev/umbriel/) — shell & compositor
