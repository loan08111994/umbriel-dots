#!/usr/bin/env bash
# ==============================================================================
# umbriel-dots installer
# Umbriel compositor + Noctalia shell + qylock + MikuPlymouth
# Repo: https://github.com/loan08111994/umbriel-dots
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# --- Log file — mọi output (kể cả lỗi, prompt) ghi vào ~/.cache/umbriel-dots ---
# ~/.cache nằm ngoài repo → không bị sync.sh nhét vào git. Log cũ >30 ngày tự xóa.
LOG_DIR="$HOME/.cache/umbriel-dots"
readonly LOG_DIR
mkdir -p "$LOG_DIR"
find "$LOG_DIR" -name '*.log' -mtime +30 -delete 2>/dev/null || true
LOG_FILE="$LOG_DIR/install-$(date +%Y-%m-%d-%H%M%S).log"
readonly LOG_FILE
set -E   # ERR trap chạy cả trong hàm/subshell
exec > >(tee -a "$LOG_FILE") 2>&1

trap 'echo -e "${RED:-}✘ Script FAILED tại dòng $LINENO (exit=$?) — xem log: $LOG_FILE${NC:-}" >&2' ERR

# --- Paths ---
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_DIR
readonly CONFIGS_DIR="$REPO_DIR/configs"
readonly EXTERNAL_DIR="$REPO_DIR/external"

TIMESTAMP="$(date +%Y-%m-%d-%H%M%S)"
readonly TIMESTAMP
readonly BACKUP_DIR="$HOME/.config-backup-$TIMESTAMP"

# --- Colors ---
readonly NC='\033[0m'
readonly BOLD='\033[1m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly CYAN='\033[0;36m'
readonly RED='\033[0;31m'

log()  { echo -e "${CYAN}::${NC} $*"; }
ok()   { echo -e "${GREEN}✔${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
die()  { echo -e "${RED}✘${NC} $*" >&2; exit 1; }

log "Log file: $LOG_FILE"

# --- Flags ---
ASSUME_YES=0
for arg in "$@"; do
    case "$arg" in
        -y|--yes) ASSUME_YES=1 ;;
        -h|--help)
            echo "Usage: ./install.sh [-y|--yes]"
            echo "  -y, --yes   Trả lời YES tự động cho toàn bộ prompt"
            echo "              (packages, paru, MikuPlymouth, timer, wallpapers, chsh fish)"
            echo "              Pacman/paru dùng --noconfirm: chọn default provider (=1)"
            echo "              khi package có nhiều nguồn (CachyOS extra + cachyos-extra-*)."
            echo "              Lưu ý: sudo password vẫn phải nhập tay khi được hỏi."
            exit 0 ;;
        *) die "Unknown option: $arg (dùng --help)" ;;
    esac
done

# Xin quyền sudo NGAY ĐẦU — nhập password 1 lần duy nhất lúc script bắt đầu.
# Các step dài (tải submodule 638MB, wallpaper 1.9GB) có thể vượt 15 phút timestamp
# của sudo → từng step cần sudo sẽ refresh lại (sudo -v) ngay trước khi chạy.
log "Xin quyền sudo trước (password nhập 1 lần duy nhất ở đây)..."
sudo -v || die "Không lấy được quyền sudo — dừng."

# Submodules PHẢI có nguyên liệu (qylock themes, MikuPlymouth...) — nếu clone thiếu
# --recurse-submodules thì tự init, không thì SDDM/qylock sẽ cài hụt → theme mặc định.
# (Đặt SAU khi định nghĩa log/ok/warn — hàm màu phải có trước khi gọi.)
if [ -f "$REPO_DIR/.gitmodules" ] && [ ! -f "$EXTERNAL_DIR/qylock/quickshell.sh" ]; then
    log "Submodules thiếu — tự init (git submodule update --init --recursive)..."
    if ( cd "$REPO_DIR" && git submodule update --init --recursive ); then
        ok "Submodules sẵn sàng"
    else
        warn "Init submodules thất bại (mạng?) — chạy tay: cd $REPO_DIR && git submodule update --init --recursive"
    fi
fi

# ask <prompt> — in prompt ra terminal và trả về "y"/"n"
# Chế độ --yes: tự trả "y" không chờ input
ask() {
    local prompt="$*"
    if [ "$ASSUME_YES" -eq 1 ]; then
        echo -e "${CYAN}::${NC} ${prompt} [y/N] y (auto)" >&2
        echo "y"
    else
        local reply
        read -rp "${prompt} [y/N] " reply
        if [[ "${reply:-}" =~ ^[Yy]$ ]]; then echo "y"; else echo "n"; fi
    fi
}

# paru flags — --yes mode: --noconfirm để AUR cũng chạy hết không vướng prompt
PARU_FLAGS=(--needed)
if [ "$ASSUME_YES" -eq 1 ]; then
    PARU_FLAGS+=(--noconfirm)
fi
readonly -a PARU_FLAGS

# --- What we deploy ---
readonly CONFIG_ITEMS=(
    umbriel
    noctalia
    kitty
    fastfetch
    cava
    btop
    nvim
    yazi
    rmpc
    mpd
    mpv
    fish
    fcitx5
    hypr
    niri
    gtk-3.0
    gtk-4.0
)

# --- Sanity checks ---
log "Checking prerequisites..."
for cmd in git rsync; do
    command -v "$cmd" >/dev/null || die "Missing: $cmd"
done

# Umbriel + Noctalia are the core of this rice
command -v umbriel >/dev/null || warn "umbriel not found in PATH — install it first (https://docs.noctalia.dev/umbriel/)"
command -v noctalia >/dev/null || warn "noctalia not found in PATH — install it first (https://github.com/noctalia-dev/noctalia-shell)"

# ==============================================================================
# Step 0.5: Optional — cài packages còn thiếu
# Chiến lược: pacman (official repos) trước, paru chỉ lo phần AUR còn thiếu
# ==============================================================================
if [[ "$(ask "Install missing packages?")" == "y" ]]; then
    # --- 1) Repo packages qua pacman (CachyOS repo có sẵn umbriel/noctalia!) ---
    readonly BIN_LIST=(nvim kitty fastfetch cava btop yazi rmpc mpd mpv fish starship rsync git shellcheck thunar umbriel noctalia quickshell xwayland-satellite nwg-look zsh fcitx5 fcitx5-configtool fzf sddm qt6-5compat qt6-svg qt6-multimedia qt6-multimedia-ffmpeg gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly)
    readonly PKG_LIST=(neovim kitty fastfetch cava btop yazi rmpc mpd mpv fish starship rsync git shellcheck thunar umbriel noctalia quickshell xwayland-satellite nwg-look zsh fcitx5 fcitx5-configtool fzf sddm qt6-5compat qt6-svg qt6-multimedia qt6-multimedia-ffmpeg gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly)
    MISSING_PKGS=()
    for i in "${!BIN_LIST[@]}"; do
        command -v "${BIN_LIST[$i]}" >/dev/null 2>&1 || MISSING_PKGS+=("${PKG_LIST[$i]}")
    done
    # Packages không có binary riêng — check trực tiếp bằng pacman -Q
    readonly DIRECT_PKGS=(xdg-desktop-portal-umbriel fcitx5-gtk fcitx5-qt cachyos-zsh-config \
        gvfs udisks2 thunar-volman)
    for p in "${DIRECT_PKGS[@]}"; do
        pacman -Q "$p" >/dev/null 2>&1 || MISSING_PKGS+=("$p")
    done

    if [ "${#MISSING_PKGS[@]}" -eq 0 ]; then
        ok "Repo packages đủ hết rồi"
    else
        log "Repo packages thiếu: ${MISSING_PKGS[*]}"
        # pacman --noconfirm: tự chọn default provider (=1) khi package có nhiều
    # sources (CachyOS có extra + cachyos-extra-* song song) — không hỏi số nữa
    sudo -v
    if sudo pacman -S --needed --noconfirm "${MISSING_PKGS[@]}"; then
            ok "Repo packages đã cài xong"
        else
            warn "pacman cài lỗi — xem output ở trên, thiếu gì sẽ phải cài tay"
        fi
    fi

    # --- 2) AUR fallback qua paru: chỉ những gì pacman KHÔNG có ---
    # Trên Arch thường (không có repo CachyOS) → dùng bản -git; GUI apps chỉ có AUR
    readonly FALLBACK_BINS=(umbriel noctalia xdg-desktop-portal-umbriel quickshell)
    readonly FALLBACK_PKGS=(umbriel-git noctalia-git xdg-desktop-portal-umbriel-git quickshell)
    # Package "thay thế" cũng tính là đã cài (portal không có binary, -git/stable đều được)
    readonly FALLBACK_ALT_PKGS=("" "" "xdg-desktop-portal-umbriel-git" "quickshell")
    readonly GUI_AUR_PKGS=(visual-studio-code-bin zen-browser-bin helium-browser-bin spotify obsidian-bin fcitx5-lotus-bin)
    AUR_MISSING=()
    for i in "${!FALLBACK_BINS[@]}"; do
        command -v "${FALLBACK_BINS[$i]}" >/dev/null 2>&1 && continue
        pacman -Q "${FALLBACK_BINS[$i]}" >/dev/null 2>&1 && continue
        alt="${FALLBACK_ALT_PKGS[$i]}"
        [ -n "$alt" ] && pacman -Q "$alt" >/dev/null 2>&1 && continue
        AUR_MISSING+=("${FALLBACK_PKGS[$i]}")
    done
    for p in "${GUI_AUR_PKGS[@]}"; do
        pacman -Q "$p" >/dev/null 2>&1 || AUR_MISSING+=("$p")
    done

    if [ "${#AUR_MISSING[@]}" -eq 0 ]; then
        ok "AUR packages đủ hết rồi"
    elif ! command -v paru >/dev/null 2>&1; then
        warn "Thiếu AUR packages: ${AUR_MISSING[*]}"
        if [[ "$(ask "Thử cài paru qua pacman rồi chạy tiếp?")" == "y" ]]; then
            sudo -v
            if sudo pacman -S --needed --noconfirm paru; then
                for p in "${AUR_MISSING[@]}"; do
                    log "Cài AUR: $p"
                    paru -S "${PARU_FLAGS[@]}" "$p" || warn "Không cài được $p — kiểm tra tên package trên AUR"
                done
            else
                warn "pacman không có paru — cài tay: paru -S paru-bin (AUR) hoặc dùng yay thay thế"
            fi
        else
            warn "Bỏ qua — còn thiếu AUR packages: ${AUR_MISSING[*]}"
        fi
    else
        for p in "${AUR_MISSING[@]}"; do
            log "Cài AUR: $p"
            paru -S "${PARU_FLAGS[@]}" "$p" || warn "Không cài được $p — kiểm tra tên package trên AUR"
        done
    fi
fi

# ==============================================================================
# Step 1: Backup existing configs
# ==============================================================================
log "Backing up existing ~/.config items to $BACKUP_DIR ..."
mkdir -p "$BACKUP_DIR"
for item in "${CONFIG_ITEMS[@]}"; do
    if [ -e "$HOME/.config/$item" ]; then
        cp -a "$HOME/.config/$item" "$BACKUP_DIR/"
    fi
done
# Loose files
[ -f "$HOME/.config/starship.toml" ] && cp -a "$HOME/.config/starship.toml" "$BACKUP_DIR/"
[ -f "$HOME/.gtkrc-2.0" ] && cp -a "$HOME/.gtkrc-2.0" "$BACKUP_DIR/"
[ -f "$HOME/.config/kdeglobals" ] && cp -a "$HOME/.config/kdeglobals" "$BACKUP_DIR/"
# zsh lives in $HOME, not ~/.config
[ -f "$HOME/.zshrc" ] && cp -a "$HOME/.zshrc" "$BACKUP_DIR/"
[ -f "$HOME/.p10k.zsh" ] && cp -a "$HOME/.p10k.zsh" "$BACKUP_DIR/"
[ -f "$HOME/.zshenv" ] && cp -a "$HOME/.zshenv" "$BACKUP_DIR/"
# bash too
[ -f "$HOME/.bashrc" ] && cp -a "$HOME/.bashrc" "$BACKUP_DIR/"
[ -f "$HOME/.bash_profile" ] && cp -a "$HOME/.bash_profile" "$BACKUP_DIR/"
# Noctalia state (settings thật sự của `noctalia settings` UI)
if [ -d "$HOME/.local/state/noctalia" ]; then
    mkdir -p "$BACKUP_DIR/noctalia-state"
    cp -a "$HOME/.local/state/noctalia/settings.toml" "$HOME/.local/state/noctalia/state.toml" \
        "$BACKUP_DIR/noctalia-state/" 2>/dev/null || true
fi
ok "Backup done. Restore anytime from: $BACKUP_DIR"

# ==============================================================================
# Step 2: Deploy configs
# ==============================================================================
log "Deploying configs..."
for item in "${CONFIG_ITEMS[@]}"; do
    [ -d "$CONFIGS_DIR/$item" ] || { warn "Skipping missing $item"; continue; }
    rsync -a "$CONFIGS_DIR/$item/" "$HOME/.config/$item/"
    ok "$HOME/.config/$item"
done

# File lẻ: starship.toml, gtkrc-2.0
cp "$CONFIGS_DIR/starship.toml" "$HOME/.config/starship.toml" 2>/dev/null || warn "starship.toml not found"
cp "$REPO_DIR/configs/gtkrc-2.0" "$HOME/.gtkrc-2.0" 2>/dev/null || true

# Noctalia settings THẬT nằm ở ~/.local/state/noctalia (UI `noctalia settings` ghi vào đây)
log "Installing Noctalia state settings..."
mkdir -p "$HOME/.local/state/noctalia"
cp "$CONFIGS_DIR/noctalia-state/settings.toml" "$HOME/.local/state/noctalia/settings.toml" 2>/dev/null \
    || warn "noctalia-state/settings.toml missing"
cp "$CONFIGS_DIR/noctalia-state/state.toml" "$HOME/.local/state/noctalia/state.toml" 2>/dev/null || true

# Icon theme YAMIS (yet-another-monochrome) → ~/.local/share/icons
if [ -d "$REPO_DIR/icons/YAMIS" ]; then
    log "Installing YAMIS icon theme..."
    mkdir -p "$HOME/.local/share/icons"
    rsync -a --delete "$REPO_DIR/icons/YAMIS/" "$HOME/.local/share/icons/YAMIS/"
    ok "$HOME/.local/share/icons/YAMIS"
fi

# kdeglobals: [Icons] chỉ icon theme cho Qt/KDE apps (GTK đã set trong settings.ini)
if [ -f "$CONFIGS_DIR/kdeglobals" ]; then
    cp "$CONFIGS_DIR/kdeglobals" "$HOME/.config/kdeglobals"
    ok "$HOME/.config/kdeglobals"
fi

# zsh + Powerlevel10k theme (deploy vào $HOME)
if [ -f "$CONFIGS_DIR/zsh/zshrc" ]; then
    cp "$CONFIGS_DIR/zsh/zshrc" "$HOME/.zshrc"
    ok "$HOME/.zshrc"
fi
if [ -f "$CONFIGS_DIR/zsh/p10k.zsh" ]; then
    cp "$CONFIGS_DIR/zsh/p10k.zsh" "$HOME/.p10k.zsh"
    ok "$HOME/.p10k.zsh"
fi
if [ -f "$CONFIGS_DIR/zsh/zshenv" ]; then
    cp "$CONFIGS_DIR/zsh/zshenv" "$HOME/.zshenv"
    ok "$HOME/.zshenv"
fi

# bash (env IM vars + aliases)
if [ -f "$CONFIGS_DIR/bash/bashrc" ]; then
    cp "$CONFIGS_DIR/bash/bashrc" "$HOME/.bashrc"
    ok "$HOME/.bashrc"
fi
if [ -f "$CONFIGS_DIR/bash/bash_profile" ]; then
    cp "$CONFIGS_DIR/bash/bash_profile" "$HOME/.bash_profile"
    ok "$HOME/.bash_profile"
fi

# fcitx5: profile có sẵn IM "lotus" (thêm Lotus từ fcitx5-configtool trên máy cũ
# — install chỉ cần cài fcitx5-lotus-bin là nhận ngay)

# Portable paths — /home/nevil hardcode (lấy từ máy gốc) → $HOME của máy đích.
# Ảnh hưởng tới: keybind Mod+Alt+L (lock.sh), fish, niri fallback, gtkrc, noctalia state.
if grep -rlq "/home/nevil" "$HOME/.config" "$HOME/.gtkrc-2.0" 2>/dev/null; then
    log "Rewriting hardcoded /home/nevil → $HOME ..."
    grep -rlZ "/home/nevil" "$HOME/.config" "$HOME/.gtkrc-2.0" 2>/dev/null \
        | xargs -0 -r sed -i "s|/home/nevil|$HOME|g"
    ok "All deployed configs now point to $HOME"
fi

ok "Deploy done"

# ==============================================================================
# Step 3: qylock (Quickshell lockscreen)
# ==============================================================================
log "Installing qylock..."
QS_LOCK_DIR="$HOME/.local/share/quickshell-lockscreen"
readonly QS_LOCK_DIR
if [ -x "$QS_LOCK_DIR/lock.sh" ] && [ -L "$QS_LOCK_DIR/themes_link" ]; then
    ok "qylock lockscreen đã cài ($QS_LOCK_DIR) — bỏ qua"
    ok "  themes_link → $(readlink "$QS_LOCK_DIR/themes_link")"
elif [ -f "$EXTERNAL_DIR/qylock/quickshell-lockscreen/lock.sh" ]; then
    # Cài thẳng KHÔNG hỏi gì — replicate đúng các bước cơ học của quickshell.sh
    # (copy wrapper + themes_link + ghi theme). Upstream chỉ hỏi tương tác để
    # CHỌN theme qua fzf — repo đã track theme rồi nên không cần hỏi.
    # Muốn chọn theme khác tương tác: chạy ./external/qylock/quickshell.sh
    QS_THEME="$(cat "$CONFIGS_DIR/qylock/theme" 2>/dev/null || echo nier-automata)"
    readonly QS_THEME
    log "Installing lockscreen with repo theme: $QS_THEME"
    rm -rf "$QS_LOCK_DIR"
    if cp -r "$EXTERNAL_DIR/qylock/quickshell-lockscreen" "$QS_LOCK_DIR" \
        && ln -sfn "$EXTERNAL_DIR/qylock/themes" "$QS_LOCK_DIR/themes_link" \
        && chmod +x "$QS_LOCK_DIR/lock.sh" \
        && sed -i "s|export QS_THEME=.*$|export QS_THEME=\"\${1:-$QS_THEME}\"|" "$QS_LOCK_DIR/lock.sh"; then
        ok "qylock installed — lock.sh default theme: $QS_THEME"
    else
        warn "qylock install thất bại — chạy tay: ./external/qylock/quickshell.sh"
    fi
    # Theme có submenu variant (terraria/Genshin/clockwork/man-bicycle/osumania)
    # cần chọn thời gian/random — ở đây dùng default upstream; chỉnh tay trong
    # $QS_LOCK_DIR/themes_link/$QS_THEME/theme.conf nếu muốn.
    case "$QS_THEME" in
        terraria|Genshin|clockwork/*|man-bicycle|osumania)
            warn "Theme '$QS_THEME' có variant options — dùng default upstream. Chỉnh: themes_link/$QS_THEME/theme.conf" ;;
    esac
else
    warn "qylock submodule not initialized. Run: git submodule update --init --recursive"
fi

# Upstream qylock KHÔNG track font của một số theme (bỏ trống font/).
# Repo giữ font thiếu ở fonts/qylock/<theme>/font/ — chép vào submodule nếu thiếu.
# (quickshell.sh tạo themes_link -> clone qylock này, nên font phải nằm đúng chỗ.)
if [ -d "$REPO_DIR/fonts/qylock" ] && [ -d "$EXTERNAL_DIR/qylock/themes" ]; then
    log "Patching qylock themes with missing fonts..."
    for theme_dir in "$REPO_DIR"/fonts/qylock/*/; do
        theme="$(basename "$theme_dir")"
        dest="$EXTERNAL_DIR/qylock/themes/$theme/font"
        # Theme phải tồn tại trong submodule; chép khi dest thiếu (hoặc chỉ có .gitkeep)
        if [ -d "$EXTERNAL_DIR/qylock/themes/$theme" ] \
            && [ -z "$(find "$dest" -type f ! -name '.gitkeep' -print -quit 2>/dev/null)" ]; then
            mkdir -p "$dest"
            cp -a "$theme_dir"/font/. "$dest/"
            ok "qylock font: $theme"
        fi
    done
fi

# qylock: khôi phục theme đang chọn (quickshell.sh ghi đè nó ở trên)
if [ -f "$CONFIGS_DIR/qylock/theme" ]; then
    mkdir -p "$HOME/.config/qylock"
    cp "$CONFIGS_DIR/qylock/theme" "$HOME/.config/qylock/theme"
    ok "qylock theme restored: $(cat "$HOME/.config/qylock/theme" 2>/dev/null || echo '?')"
fi

# ==============================================================================
# Step 3.5: fcitx5-lotus — server unit + udev (nếu addon đã được cài qua AUR)
# ==============================================================================
if command -v fcitx5-lotus-server >/dev/null 2>&1; then
    log "Setting up fcitx5-lotus..."
    if ! systemctl is-enabled "fcitx5-lotus-server@$(id -un).service" >/dev/null 2>&1; then
        if [[ "$(ask "Enable fcitx5-lotus-server (system unit + udev rules)?")" == "y" ]]; then
            sudo -v
            if sudo udevadm control --reload-rules \
                && sudo udevadm trigger \
                && sudo modprobe uinput \
                && sudo systemctl enable --now "fcitx5-lotus-server@$(id -un).service"; then
                ok "fcitx5-lotus-server enabled — bộ gõ dùng ngay"
            else
                warn "Setup thất bại — làm tay: xem README mục 'Vietnamese input method'"
            fi
        fi
    else
        ok "fcitx5-lotus-server đã enabled — bỏ qua"
    fi
fi

# ==============================================================================
# Step 4: MikuPlymouth (boot splash) — needs root
# ==============================================================================
log "MikuPlymouth needs root privileges."
if [ -f "$EXTERNAL_DIR/MikuPlymouth/install.sh" ]; then
    if [[ "$(ask "Install MikuPlymouth now?")" == "y" ]]; then
        # Pipe 'y' vào: sudo vẫn hỏi password qua tty riêng, còn prompt ẩn nào
        # bên trong script con (mkinitcpio/limine hook...) đều được auto-yes
        sudo -v
        ( cd "$EXTERNAL_DIR/MikuPlymouth" && printf 'y\ny\ny\ny\ny\ny\n' | sudo bash install.sh ) \
            || warn "MikuPlymouth install failed — run manually: cd $EXTERNAL_DIR/MikuPlymouth && sudo ./install.sh"
    else
        warn "Skipped. Install later: cd $EXTERNAL_DIR/MikuPlymouth && sudo ./install.sh"
    fi

    # --- Optional: daily clip rotation (all 37 clips) via systemd timer ---
    echo
    log "Bonus: Plymouth chỉ giữ được ~10 clips một lúc (giới hạn RAM/initramfs)."
    log "Timer miku-rotate chạy install.sh mỗi ngày 1 phút sau boot để xoay vòng qua đủ 37 clips."
    if [[ "$(ask "Enable daily clip rotation (systemd timer)?")" == "y" ]]; then
        sudo -v
        if sudo rsync -a --exclude=.git "$EXTERNAL_DIR/MikuPlymouth/" /opt/MikuPlymouth/ \
            && sudo cp /opt/MikuPlymouth/miku-rotate.service /etc/systemd/system/ \
            && sudo cp /opt/MikuPlymouth/miku-rotate.timer /etc/systemd/system/ \
            && sudo systemctl daemon-reload \
            && sudo systemctl enable --now miku-rotate.timer; then            ok "Timer enabled — xem: systemctl list-timers miku-rotate.timer | log: journalctl -u miku-rotate.service"
        else
            warn "Rotation setup failed — làm thủ công: cp external/MikuPlymouth sang /opt/MikuPlymouth rồi enable miku-rotate.timer"
        fi
    else
        warn "Skipped. Enable sau: rsync -a --exclude=.git $EXTERNAL_DIR/MikuPlymouth/ /opt/MikuPlymouth/ && sudo cp /opt/MikuPlymouth/miku-rotate.{service,timer} /etc/systemd/system/ && sudo systemctl daemon-reload && sudo systemctl enable --now miku-rotate.timer"
    fi
else
    warn "MikuPlymouth submodule not initialized"
fi

# ==============================================================================
# Step 5: Wallpapers (CozyPixels) + logo mặc định
# ==============================================================================
# --- Logo / pfps (nhẹ, cài luôn không hỏi) ---
log "Installing Pfps-and-logos (logo mặc định)..."
mkdir -p "$HOME/Pictures/Pfps-and-logos"
if [ -d "$REPO_DIR/wallpapers/Pfps-and-logos" ]; then
    rsync -a "$REPO_DIR/wallpapers/Pfps-and-logos/" "$HOME/Pictures/Pfps-and-logos/"
    ok "$HOME/Pictures/Pfps-and-logos — avatar + icon.png cho lockscreen sticker"
fi

# --- CozyPixels wallpapers (~1.9GB) — HỎI TRƯỚC KHI CÀI ---
readonly COZY_URL="https://github.com/SleepyCatHey/CozyPixels"
# Skip chỉ khi tải xong thật sự (≥100 files) — thư mục rỗng/dở dang phải tải lại.
# `|| true` trong pipeline: find lỗi (thư mục chưa tồn tại) không được phép
# chết script qua set -e + pipefail.
WP_COUNT="$(find "$HOME/Pictures/Wallpapers" -type f 2>/dev/null | wc -l || true)"
if [ "$WP_COUNT" -ge 100 ]; then
    ok "CozyPixels wallpapers đã có sẵn ở $HOME/Pictures/Wallpapers ($WP_COUNT files) — bỏ qua"
else
    if [ "$WP_COUNT" -gt 0 ]; then
        warn "Wallpapers dir chỉ có $WP_COUNT files — tải lại cho đủ bộ"
    fi
    echo
    log "CozyPixels: bộ sưu tập wallpaper ~1.9GB (Catppuccin, Nord, One Dark, anime, live...)"
    if [[ "$(ask "Download CozyPixels wallpapers vào $HOME/Pictures/Wallpapers?")" == "y" ]]; then
        # Clone vào ~/.cache (disk thật) — KHÔNG dùng /tmp: /tmp là tmpfs (RAM),
        # repo 1.9GB + RAM VM nhỏ → clone chết giữa chừng "No space left on device".
        COZY_TMP="$HOME/.cache/umbriel-dots/CozyPixels-clone"
        rm -rf "$COZY_TMP"
        if git clone --depth 1 "$COZY_URL" "$COZY_TMP"; then
            mkdir -p "$HOME/Pictures/Wallpapers"
            rsync -a "$COZY_TMP/" "$HOME/Pictures/Wallpapers/" \
                --exclude=.git --exclude=README.md --exclude=LICENSE --exclude=cozypixels-banner.png
            WP_COUNT="$(find "$HOME/Pictures/Wallpapers" -type f | wc -l || true)"
            WP_SIZE="$(du -sh "$HOME/Pictures/Wallpapers" 2>/dev/null | cut -f1)"
            ok "Wallpapers đã vào $HOME/Pictures/Wallpapers — $WP_COUNT files, $WP_SIZE"
            if [ "$WP_COUNT" -lt 100 ]; then
                warn "Số file thấp bất thường — kiểm tra: ls ~/Pictures/Wallpapers"
            fi
        else
            warn "Clone CozyPixels thất bại — tự clone: git clone --depth 1 $COZY_URL"
        fi
        rm -rf "$COZY_TMP"
    else
        warn "Skipped. Cài sau: git clone --depth 1 $COZY_URL rồi chép nội dung vào ~/Pictures/Wallpapers"
    fi
fi

# ==============================================================================
# Step 6: Login shell — configs fish cần fish làm login shell
# (fish config.fish đặt env IM trong block `is-login`; umbriel khởi từ shell login)
# ==============================================================================
LOGIN_SHELL="$(getent passwd "$(id -un)" | cut -d: -f7)"
readonly LOGIN_SHELL
if [ "$LOGIN_SHELL" = "$(command -v fish)" ]; then
    ok "Login shell đã là fish — không cần đổi"
else
    log "Login shell hiện tại: $LOGIN_SHELL (không phải fish)"
    if [[ "$(ask "Đổi login shell sang fish (chsh)?")" == "y" ]]; then
        # sudo chsh (root) — không hỏi password user; dùng chung sudo timestamp
        # đã cache từ các step trước (pacman/lotus/sddm) → chỉ nhập 1 password cả install
        sudo -v
        if sudo chsh -s "$(command -v fish)" "$(id -un)"; then
            ok "Login shell → fish (hiệu lực lần login sau)"
        else
            warn "chsh thất bại — chạy tay: chsh -s /usr/bin/fish"
        fi
    else
        warn "Giữ login shell cũ. Đổi sau: chsh -s /usr/bin/fish"
    fi
fi

# ==============================================================================
# Step 7: SDDM display manager — màn hình login dùng cùng theme qylock
# (SDDM theme = copy của external/qylock/themes/<theme>, tên đọc từ
#  ~/.config/qylock/theme — tức là lockscreen và login screen luôn đồng bộ)
# Tự động hoàn toàn — không hỏi (enable + theme đều là thao tác an toàn/khôi phục)
# ==============================================================================
if pacman -Q sddm >/dev/null 2>&1; then
    sudo -v   # refresh timestamp — các step tải nặng trước đó có thể đã vượt 15 phút
    if systemctl is-enabled sddm.service >/dev/null 2>&1; then
        ok "sddm.service đã enabled — bỏ qua"
    else
        log "Enabling sddm.service..."
        if sudo systemctl enable sddm.service; then
            ok "sddm.service enabled"
        else
            warn "enable thất bại — chạy tay: sudo systemctl enable sddm"
        fi
    fi

    # Login theme = cùng theme với lockscreen (đã restore từ repo ở trên) — tự động
    SDDM_THEME="$(cat "$HOME/.config/qylock/theme" 2>/dev/null || echo pixel-dusk-city)"
    log "SDDM theme sẽ dùng: $SDDM_THEME"

    # 1) Theme files — chỉ copy khi chưa có (giữ bản user đã chỉnh nếu có)
    if [ -d "/usr/share/sddm/themes/$SDDM_THEME" ]; then
        ok "Theme files đã có trong /usr/share/sddm/themes"
    elif [ -d "$EXTERNAL_DIR/qylock/themes/$SDDM_THEME" ]; then
        log "Copying theme files..."
        if sudo mkdir -p /usr/share/sddm/themes \
            && sudo cp -a "$EXTERNAL_DIR/qylock/themes/$SDDM_THEME" /usr/share/sddm/themes/; then
            ok "Theme files copied"
        else
            warn "Copy thất bại — làm tay: sudo cp -a external/qylock/themes/$SDDM_THEME /usr/share/sddm/themes/"
        fi
    else
        warn "Theme '$SDDM_THEME' không có trong qylock submodule"
    fi

    # 2) theme.conf — LUÔN đảm bảo Current=$SDDM_THEME (khác trước đây: chỉ ghi khi
    #    copy theme → nếu lần chạy trước copy xong nhưng ghi conf fail (sudo hết
    #    hạn), lần sau skip luôn → SDDM vĩnh viễn dùng theme default).
    #    Logic theo upstream sddm.sh: sed in-place, không clobber setting khác.
    QY_SDDM_CONF="/etc/sddm.conf.d/theme.conf"
    if sudo mkdir -p /etc/sddm.conf.d && [ ! -f "$QY_SDDM_CONF" ]; then
        if printf '[Theme]\nCurrent=%s\n' "$SDDM_THEME" | sudo tee "$QY_SDDM_CONF" >/dev/null; then
            ok "theme.conf created → $SDDM_THEME"
        else
            warn "Không ghi được $QY_SDDM_CONF — làm tay: echo '[Theme]' ... Current=$SDDM_THEME"
        fi
    elif grep -q '^Current=' "$QY_SDDM_CONF" 2>/dev/null; then
        if grep -q "^Current=$SDDM_THEME\$" "$QY_SDDM_CONF"; then
            ok "theme.conf đã trỏ đúng $SDDM_THEME"
        else
            if sudo sed -i "s|^Current=.*|Current=$SDDM_THEME|" "$QY_SDDM_CONF"; then
                ok "theme.conf updated → $SDDM_THEME"
            else
                warn "Không sửa được $QY_SDDM_CONF"
            fi
        fi
    elif grep -q '^\[Theme\]' "$QY_SDDM_CONF" 2>/dev/null; then
        if sudo sed -i "/^\[Theme\]/a Current=$SDDM_THEME" "$QY_SDDM_CONF"; then
            ok "theme.conf → $SDDM_THEME (chèn vào section [Theme] có sẵn)"
        else
            warn "Không chèn được Current= vào $QY_SDDM_CONF"
        fi
    else
        if printf '[Theme]\nCurrent=%s\n' "$SDDM_THEME" | sudo tee "$QY_SDDM_CONF" >/dev/null; then
            ok "theme.conf → $SDDM_THEME"
        else
            warn "Không ghi được $QY_SDDM_CONF"
        fi
    fi
else
    warn "sddm chưa cài — bỏ qua Step 7 (cài sddm rồi chạy lại để có login theme)"
fi

# ==============================================================================
# Done
# ==============================================================================
echo
echo -e "${BOLD}Deployed!${NC}"
echo -e "  • Lock screen:  ${CYAN}Mod+Alt+L${NC} (qylock)  |  Noctalia lock: ${CYAN}Mod+Shift+L${NC}"
echo -e "  • Umbriel config: ~/.config/umbriel/config.toml  (auto-reloads)"
echo -e "  • Noctalia UI:    noctalia settings"
echo -e "  • NOTE: hardcoded /home/nevil in deployed configs was rewritten to your"
echo -e "          \$HOME automatically (including the Mod+Alt+L lock.sh path)."
echo -e "  • Full log: ${CYAN}$LOG_FILE${NC}"
