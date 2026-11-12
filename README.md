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
- [Bộ gõ tiếng Việt (fcitx5 + Lotus)](#️-bộ-gõ-tiếng-việt-fcitx5--lotus)
- [Limine theme](#-limine-theme-bootloader)
- [Keybinds chính](#-keybinds-chính)
- [Credits](#-credits)

---

## 🌙 Overview

Dotfile cá nhân được extract trực tiếp từ máy đang chạy, gồm:

- **Umbriel** — compositor native của hệ Noctalia ([docs](https://docs.noctalia.dev/umbriel/)), config đã tinh chỉnh keybinds, autostart Noctalia, NVIDIA workaround.
  > 🌈 **Border màu theo wallpaper:** template chính chủ của Noctalia (Settings → Templates → Compositors → Umbriel) sinh `~/.config/umbriel/noctalia.toml` từ palette matugen của wallpaper — viền focus, unfocus, title bar, overview tint tự đổi màu mỗi lần đổi wallpaper. File được umbriel include qua `[include.optional]` và **tự reload** khi Noctalia render lại.
- **Icon theme YAMIS** (yet-another-monochrome-icon-set, by `dirn` — repo gốc không còn public, đã track trong `icons/YAMIS/`) — mặc định cho GTK3/4 (`settings.ini`) và Qt (qua `QT_QPA_PLATFORMTHEME=gtk3` + `[Icons]` trong kdeglobals). `install.sh` chép vào `~/.local/share/icons`.
- **fcitx5 + Lotus** — bộ gõ tiếng Việt Wayland-native ([fcitx5-lotus](https://github.com/LotusInputMethod/fcitx5-lotus), AUR) — profile trong repo đã bật `lotus` làm IM mặc định; env vars trong fish config. Xem section riêng bên dưới.
- **zsh + Powerlevel10k** — theme prompt (repo CachyOS `zsh-theme-powerlevel10k` + `cachyos-zsh-config`); `configs/zsh/` track `.zshrc` + `.p10k.zsh`, deploy vào `$HOME`.
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
│   ├── kitty/ fastfetch/ cava/ btop/ nvim/ yazi/ rmpc/ mpd/ mpv/ fish/ fcitx5/
│   ├── hypr/ niri/       # fallback nếu dùng compositor khác
│   ├── gtk-3.0/ gtk-4.0/ # noctalia.css theme
│   ├── zsh/              # .zshrc + .p10k.zsh (Powerlevel10k) — deploy vào $HOME
│   └── starship.toml
├── wallpapers/           # logo mặc định + nguồn wallpapers
│   ├── Pfps-and-logos/   # avatar mèo khóc + icon.png (lockscreen sticker)
│   └── (CozyPixels ~1.9GB — install.sh sẽ hỏi trước khi tải về
│         ~/Pictures/Wallpapers: Catppuccin, Nord, One Dark, anime, live...)
├── external/             # git submodules
│   ├── qylock/           # github.com/Darkkal44/qylock
│   ├── MikuPlymouth/     # github.com/Thang1191/MikuPlymouth
│   └── catppuccin-limine/ # github.com/catppuccin/limine — theme bootloader
├── boot/
│   └── limine/           # limine-splash.png — wallpaper cho màn hình boot
├── fonts/
│   └── qylock/           # font thiếu trong upstream (Genshin, minecraft, nier-automata,
│                         #   star-rail, terraria) — install.sh chép vào theme khi cần
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
sudo pacman -S --needed umbriel noctalia xdg-desktop-portal-umbriel quickshell xwayland-satellite nwg-look \
    neovim kitty fastfetch cava btop yazi rmpc mpd mpv fish starship rsync shellcheck thunar code \
    zsh cachyos-zsh-config zsh-theme-powerlevel10k fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool \
    gvfs udisks2 thunar-volman
# AUR chỉ cần cho: GUI apps + fcitx5-lotus + (Arch thường không có repo CachyOS thì thêm core -git)
paru -S --needed zen-browser-bin helium-browser-bin spotify obsidian-bin fcitx5-lotus-bin

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
- qylock: font của một số theme (Genshin, Minecraft, Nier Automata, Star Rail, Terraria) **không nằm trong upstream repo** — `install.sh` tự chép từ `fonts/qylock/<theme>/font/` vào `external/qylock/themes/*/font/` sau khi cài. `osumania` và `windows_7` không có font ở đâu cả — theme đó dùng font mặc định của hệ thống (vẫn hoạt động).
- Cập nhật submodules: `git submodule update --remote`

## ⌨️ Bộ gõ tiếng Việt (fcitx5 + Lotus)

Bộ gõ: [fcitx5-lotus](https://github.com/LotusInputMethod/fcitx5-lotus) (AUR) làm addon của fcitx5. Cài đặt tự động:

```bash
paru -S --needed fcitx5-lotus-bin          # addon Lotus (prebuilt)
sudo udevadm control --reload-rules && sudo udevadm trigger   # quyền /dev/uinput
sudo systemctl enable --now fcitx5-lotus-server@$(whoami).service  # system unit!
```

Config trong repo đã có sẵn phần còn lại:

- **`configs/fish/config.fish`**, **`configs/zsh/zshenv`**, **`configs/bash/bashrc`** — env vars IM (`GTK_IM_MODULE`, `QT_IM_MODULE`, `XMODIFIERS=@im=fcitx`...) đặt cho cả 3 shell: fish (block `is-login`), zsh (`.zshenv` — đọc bởi mọi invocation), bash (`.bashrc` — trước check interactive). Umbriel khởi từ shell nào cũng kế thừa
- **`configs/fcitx5/profile`** — `DefaultIM=lotus` + layout `us`
- **Autostart:** `[general].autostart = ["noctalia", "fcitx5 -d"]` trong `configs/umbriel/config.toml` (lớp XDG autostart của package fcitx5 cũng tự chạy — 2 lớp không xung đột, fcitx5 single-instance)

Dùng: `Ctrl+Space` bật/tắt tiếng Việt • settings trong `fcitx5-configtool` hoặc icon Lotus ở tray Noctalia.

Kiểm tra: `fcitx5-diagnose | grep -i wayland` — phải thấy `frontend:wayland_v2` + InputContext của app.

> Electron/Chromium (zen, code, spotify...): cần flag `--enable-wayland-ime --wayland-text-input-version=3` khi launch để IM hoạt động trơn tru trên Wayland.

## 🥾 Limine theme (bootloader)

Máy dùng Limine (CachyOS: `/boot/limine.conf`). Repo có sẵn:

- **`external/catppuccin-limine/`** — 4 flavors × 10 accents: `themes/mocha/catppuccin-mocha-pink.conf`...
- **`boot/limine/limine-splash.png`** — ảnh splash (phố sakura) cho màn hình boot

Cách tự config (cần sudo vì `/boot` là ESP):

```bash
# 1. Chọn theme — xem màu từng accent:
cat external/catppuccin-limine/themes/mocha/catppuccin-mocha-pink.conf

# 2. Paste nội dung theme vào ĐẦU /boot/limine.conf:
sudo nano /boot/limine.conf

# 3. Copy splash lên ESP và trỏ vào config (global option — đặt trước entry đầu tiên):
sudo cp boot/limine/limine-splash.png /boot/limine-splash.png
#    → thêm vào /boot/limine.conf:
#    wallpaper: boot():/limine-splash.png
#    wallpaper_style: centered        # tiled | centered | stretched (mặc định stretched)
#    backdrop: 1e1e2e                 # màu vùng trống khi dùng centered (RRGGBB)

# 4. Chỉnh branding text (trống = ẩn):
#    interface_branding:

# 5. Khởi động lại để xem kết quả
```

> ⚠️ Lưu ý CachyOS: `limine-mkinitcpio-hook` + `limine-snapper-sync` có thể **ghi đè** các mục trong `limine.conf` khi cập nhật kernel — chỉnh phần theme ở đầu file, giữ nguyên các mục `entry:` mà hook sinh ra.

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
- [catppuccin/limine](https://github.com/catppuccin/limine) — theme bootloader Limine
- [Noctalia](https://github.com/noctalia-dev/noctalia-shell) + [Umbriel](https://docs.noctalia.dev/umbriel/) — shell & compositor
