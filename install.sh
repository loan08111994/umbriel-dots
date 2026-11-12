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
read -rp "Install missing packages? [y/N] " instpkgs
if [[ "${instpkgs:-}" =~ ^[Yy]$ ]]; then
    # --- 1) Repo packages qua pacman ---
    readonly BIN_LIST=(nvim kitty fastfetch cava btop yazi rmpc mpd mpv fish starship rsync git shellcheck thunar code)
    readonly PKG_LIST=(neovim kitty fastfetch cava btop yazi rmpc mpd mpv fish starship rsync git shellcheck thunar code)
    MISSING_PKGS=()
    for i in "${!BIN_LIST[@]}"; do
        command -v "${BIN_LIST[$i]}" >/dev/null 2>&1 || MISSING_PKGS+=("${PKG_LIST[$i]}")
    done

    if [ "${#MISSING_PKGS[@]}" -eq 0 ]; then
        ok "Repo packages đủ hết rồi"
    else
        log "Repo packages thiếu: ${MISSING_PKGS[*]}"
        if sudo pacman -S --needed "${MISSING_PKGS[@]}"; then
            ok "Repo packages đã cài xong"
        else
            warn "pacman cài lỗi — xem output ở trên, thiếu gì sẽ phải cài tay"
        fi
    fi

    # --- 2) AUR packages qua paru (những gì pacman không có) ---
    # Core: umbriel/noctalia stack | GUI: zen, helium, spotify, obsidian
    readonly AUR_PKGS=(umbriel-git noctalia-git xdg-desktop-portal-umbriel-git quickshell \
                       zen-browser-bin helium-browser-bin spotify obsidian-bin)
    AUR_MISSING=()
    for p in "${AUR_PKGS[@]}"; do
        pacman -Q "$p" >/dev/null 2>&1 || AUR_MISSING+=("$p")
    done

    if [ "${#AUR_MISSING[@]}" -eq 0 ]; then
        ok "AUR packages đủ hết rồi"
    elif ! command -v paru >/dev/null 2>&1; then
        warn "Thiếu AUR packages: ${AUR_MISSING[*]}"
        read -rp "Thử cài paru qua pacman rồi chạy tiếp? [y/N] " getparu
        if [[ "${getparu:-}" =~ ^[Yy]$ ]]; then
            if sudo pacman -S --needed paru; then
                for p in "${AUR_MISSING[@]}"; do
                    log "Cài AUR: $p"
                    paru -S --needed "$p" || warn "Không cài được $p — kiểm tra tên package trên AUR"
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
            paru -S --needed "$p" || warn "Không cài được $p — kiểm tra tên package trên AUR"
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

# ==============================================================================
# Step 4: MikuPlymouth (boot splash) — needs root
# ==============================================================================
log "MikuPlymouth needs root privileges."
if [ -f "$EXTERNAL_DIR/MikuPlymouth/install.sh" ]; then
    read -rp "Install MikuPlymouth now? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        ( cd "$EXTERNAL_DIR/MikuPlymouth" && sudo bash install.sh ) \
            || warn "MikuPlymouth install failed — run manually: cd $EXTERNAL_DIR/MikuPlymouth && sudo ./install.sh"
    else
        warn "Skipped. Install later: cd $EXTERNAL_DIR/MikuPlymouth && sudo ./install.sh"
    fi

    # --- Optional: daily clip rotation (all 37 clips) via systemd timer ---
    echo
    log "Bonus: Plymouth chỉ giữ được ~10 clips một lúc (giới hạn RAM/initramfs)."
    log "Timer miku-rotate chạy install.sh mỗi ngày 1 phút sau boot để xoay vòng qua đủ 37 clips."
    read -rp "Enable daily clip rotation (systemd timer)? [y/N] " rotate
    if [[ "$rotate" =~ ^[Yy]$ ]]; then
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
    read -rp "Download CozyPixels wallpapers vào $HOME/Pictures/Wallpapers? [y/N] " getwps
    if [[ "${getwps:-}" =~ ^[Yy]$ ]]; then
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
# Done
# ==============================================================================
echo
echo -e "${BOLD}Deployed!${NC}"
echo -e "  • Lock screen:  ${CYAN}Mod+Alt+L${NC} (qylock)  |  Noctalia lock: ${CYAN}Mod+Shift+L${NC}"
echo -e "  • Umbriel config: ~/.config/umbriel/config.toml  (auto-reloads)"
echo -e "  • Noctalia UI:    noctalia settings"
echo -e "  • NOTE: umbriel config hardcodes ${CYAN}/home/nevil${NC} in Mod+Alt+L —"
echo -e "          change it to your \$HOME path if deploying on another machine."
