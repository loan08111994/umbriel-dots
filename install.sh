#!/usr/bin/env bash
# ==============================================================================
# umbriel-dots installer
# Umbriel compositor + Noctalia shell + qylock + MikuPlymouth
# Repo: https://github.com/loan08111994/umbriel-dots
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

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
    readonly BIN_LIST=(nvim kitty fastfetch cava btop yazi rmpc mpd mpv fish starship rsync git shellcheck thunar code umbriel noctalia quickshell xwayland-satellite nwg-look zsh fcitx5 fcitx5-configtool)
    readonly PKG_LIST=(neovim kitty fastfetch cava btop yazi rmpc mpd mpv fish starship rsync git shellcheck thunar code umbriel noctalia quickshell xwayland-satellite nwg-look zsh fcitx5 fcitx5-configtool)
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
    readonly GUI_AUR_PKGS=(zen-browser-bin helium-browser-bin spotify obsidian-bin fcitx5-lotus-bin)
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
        mv "$HOME/.config/$item" "$BACKUP_DIR/"
    fi
done
# Loose files
[ -f "$HOME/.config/starship.toml" ] && mv "$HOME/.config/starship.toml" "$BACKUP_DIR/"
[ -f "$HOME/.gtkrc-2.0" ] && mv "$HOME/.gtkrc-2.0" "$BACKUP_DIR/"
[ -f "$HOME/.config/kdeglobals" ] && mv "$HOME/.config/kdeglobals" "$BACKUP_DIR/"
# zsh lives in $HOME, not ~/.config
[ -f "$HOME/.zshrc" ] && mv "$HOME/.zshrc" "$BACKUP_DIR/"
[ -f "$HOME/.p10k.zsh" ] && mv "$HOME/.p10k.zsh" "$BACKUP_DIR/"
[ -f "$HOME/.zshenv" ] && mv "$HOME/.zshenv" "$BACKUP_DIR/"
# bash too
[ -f "$HOME/.bashrc" ] && mv "$HOME/.bashrc" "$BACKUP_DIR/"
[ -f "$HOME/.bash_profile" ] && mv "$HOME/.bash_profile" "$BACKUP_DIR/"
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

ok "Deploy done"

# ==============================================================================
# Step 3: qylock (Quickshell lockscreen)
# ==============================================================================
log "Installing qylock..."
if [ -f "$EXTERNAL_DIR/qylock/quickshell.sh" ]; then
    bash "$EXTERNAL_DIR/qylock/quickshell.sh" || warn "qylock install failed — run it manually later"
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

# ==============================================================================
# Step 4: MikuPlymouth (boot splash) — needs root
# ==============================================================================
log "MikuPlymouth needs root privileges."
if [ -f "$EXTERNAL_DIR/MikuPlymouth/install.sh" ]; then
    if [[ "$(ask "Install MikuPlymouth now?")" == "y" ]]; then
        ( cd "$EXTERNAL_DIR/MikuPlymouth" && sudo bash install.sh ) \
            || warn "MikuPlymouth install failed — run manually: cd $EXTERNAL_DIR/MikuPlymouth && sudo ./install.sh"
    else
        warn "Skipped. Install later: cd $EXTERNAL_DIR/MikuPlymouth && sudo ./install.sh"
    fi

    # --- Optional: daily clip rotation (all 37 clips) via systemd timer ---
    echo
    log "Bonus: Plymouth chỉ giữ được ~10 clips một lúc (giới hạn RAM/initramfs)."
    log "Timer miku-rotate chạy install.sh mỗi ngày 1 phút sau boot để xoay vòng qua đủ 37 clips."
    if [[ "$(ask "Enable daily clip rotation (systemd timer)?")" == "y" ]]; then
        if sudo rsync -a --exclude=.git "$EXTERNAL_DIR/MikuPlymouth/" /opt/MikuPlymouth/ \
            && sudo cp /opt/MikuPlymouth/miku-rotate.service /etc/systemd/system/ \
            && sudo cp /opt/MikuPlymouth/miku-rotate.timer /etc/systemd/system/ \
            && sudo systemctl daemon-reload \
            && sudo systemctl enable --now miku-rotate.timer; then
            ok "Timer enabled — xem: systemctl list-timers miku-rotate.timer | log: journalctl -u miku-rotate.service"
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
if [ -d "$HOME/Pictures/Wallpapers/Catppuccin" ]; then
    ok "CozyPixels wallpapers đã có sẵn ở $HOME/Pictures/Wallpapers — bỏ qua"
else
    echo
    log "CozyPixels: bộ sưu tập wallpaper ~1.9GB (Catppuccin, Nord, One Dark, anime, live...)"
    if [[ "$(ask "Download CozyPixels wallpapers vào $HOME/Pictures/Wallpapers?")" == "y" ]]; then
        TMP_COZY="$(mktemp -d)"
        if git clone --depth 1 "$COZY_URL" "$TMP_COZY/CozyPixels"; then
            mkdir -p "$HOME/Pictures/Wallpapers"
            rsync -a "$TMP_COZY/CozyPixels/" "$HOME/Pictures/Wallpapers/" \
                --exclude=.git --exclude=README.md --exclude=LICENSE --exclude=cozypixels-banner.png
            ok "Wallpapers đã vào $HOME/Pictures/Wallpapers"
        else
            warn "Clone CozyPixels thất bại — tự clone: git clone --depth 1 $COZY_URL"
        fi
        rm -rf "$TMP_COZY"
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
        if chsh -s "$(command -v fish)" "$(id -un)"; then
            ok "Login shell → fish (hiệu lực lần login sau)"
        else
            warn "chsh thất bại — chạy tay: chsh -s /usr/bin/fish"
        fi
    else
        warn "Giữ login shell cũ. Đổi sau: chsh -s /usr/bin/fish"
    fi
fi

# ==============================================================================
# Done
# ==============================================================================
echo
echo -e "${BOLD}Deployed!${NC}"
echo -e "  • Lock screen:  ${CYAN}Mod+Alt+L${NC} (qylock)  |  Noctalia lock: ${CYAN}Mod+Shift+L${NC}"
echo -e "  • Umbriel config: ~/.config/umbriel/config.toml  (auto-reloads)"
echo -e "  • Noctalia UI:    noctalia settings"
echo -e "  • NOTE: umbriel config hardcodes ${CYAN}/home/nevil${NC} in Mod+Alt+L —"
echo -e "          change it to your \$HOME path if deploying on another machine."
