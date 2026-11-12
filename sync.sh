#!/usr/bin/env bash
# ==============================================================================
# sync.sh — đồng bộ ngược: máy thật (~/.config) → repo → GitHub
# Chạy cuối ngày sau khi chỉnh config, nó sẽ:
#   1. rsync (mirror) các config đang sống vào configs/
#   2. git add + hiển thị diff để bạn xem trước
#   3. hỏi commit message (Enter = message tự động) rồi push
#
# Ngược với install.sh (repo → ~/.config).
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# --- Log file — mọi output ghi vào ~/.cache/umbriel-dots (ngoài repo) ---
LOG_DIR="$HOME/.cache/umbriel-dots"
readonly LOG_DIR
mkdir -p "$LOG_DIR"
find "$LOG_DIR" -name '*.log' -mtime +30 -delete 2>/dev/null || true
LOG_FILE="$LOG_DIR/sync-$(date +%Y-%m-%d-%H%M%S).log"
readonly LOG_FILE
set -E
exec > >(tee -a "$LOG_FILE") 2>&1

trap 'echo "✘ sync FAILED tại dòng $LINENO (exit=$?) — xem log: $LOG_FILE" >&2' ERR

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_DIR
readonly CONFIGS_DIR="$REPO_DIR/configs"
readonly LIVE_CONFIG="$HOME/.config"

# Phải trùng với CONFIG_ITEMS trong install.sh
readonly ITEMS=(
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

# File lẻ: "nguồn:đích"
readonly EXTRA_FILES=(
    "$LIVE_CONFIG/starship.toml:$REPO_DIR/configs/starship.toml"
    "$HOME/.gtkrc-2.0:$REPO_DIR/configs/gtkrc-2.0"
    "$HOME/.local/state/noctalia/settings.toml:$REPO_DIR/configs/noctalia-state/settings.toml"
    "$HOME/.local/state/noctalia/state.toml:$REPO_DIR/configs/noctalia-state/state.toml"
    "$HOME/.config/kdeglobals:$REPO_DIR/configs/kdeglobals"
    "$HOME/.zshrc:$REPO_DIR/configs/zsh/zshrc"
    "$HOME/.p10k.zsh:$REPO_DIR/configs/zsh/p10k.zsh"
    "$HOME/.zshenv:$REPO_DIR/configs/zsh/zshenv"
    "$HOME/.bashrc:$REPO_DIR/configs/bash/bashrc"
    "$HOME/.bash_profile:$REPO_DIR/configs/bash/bash_profile"
    "$HOME/.config/qylock/theme:$REPO_DIR/configs/qylock/theme"
)

readonly GREEN='\033[0;32m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

log() { echo -e "${CYAN}::${NC} $*"; }
ok()  { echo -e "${GREEN}✔${NC} $*"; }

command -v git >/dev/null   || { echo "Missing: git"   >&2; exit 1; }
command -v rsync >/dev/null || { echo "Missing: rsync" >&2; exit 1; }

# ------------------------------------------------------------------------------
# Bước 1: mirror configs đang sống vào repo
# ------------------------------------------------------------------------------
log "Mirroring live configs vào repo..."
for item in "${ITEMS[@]}"; do
    if [ -d "$LIVE_CONFIG/$item" ]; then
        rsync -a --delete "$LIVE_CONFIG/$item/" "$CONFIGS_DIR/$item/"
    else
        echo "  (bỏ qua — không có $LIVE_CONFIG/$item)"
    fi
done
for pair in "${EXTRA_FILES[@]}"; do
    src="${pair%%:*}"
    dst="${pair#*:}"
    if [ -f "$src" ]; then
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
    fi
done

# Logo/pfps (nhỏ, mirror ngược cả thư mục)
if [ -d "$HOME/Pictures/Pfps-and-logos" ]; then
    mkdir -p "$REPO_DIR/wallpapers/Pfps-and-logos"
    rsync -a --delete "$HOME/Pictures/Pfps-and-logos/" "$REPO_DIR/wallpapers/Pfps-and-logos/"
fi

# Icon theme YAMIS (mirror ngược — ít đổi nhưng giữ repo luôn khớp máy)
if [ -d "$HOME/.local/share/icons/YAMIS" ]; then
    mkdir -p "$REPO_DIR/icons/YAMIS"
    rsync -a --delete "$HOME/.local/share/icons/YAMIS/" "$REPO_DIR/icons/YAMIS/"
fi

# ------------------------------------------------------------------------------
# Bước 2: xem có gì thay đổi không
# ------------------------------------------------------------------------------
cd "$REPO_DIR"
git add -A
if git diff --cached --quiet; then
    ok "Không có gì thay đổi — máy và repo đã đồng bộ."
    exit 0
fi

echo
log "Các thay đổi sẽ được commit:"
git diff --cached --stat
echo

# ------------------------------------------------------------------------------
# Bước 3: commit + push
# ------------------------------------------------------------------------------
DEFAULT_MSG="sync: update configs from machine ($(date +%Y-%m-%d\ %H:%M))"
readonly DEFAULT_MSG
read -rp "Commit message [${DEFAULT_MSG}]: " MSG || MSG=""
MSG="${MSG:-$DEFAULT_MSG}"

git commit -m "$MSG"
git push
ok "Đã push lên GitHub — repo giờ khớp với máy thật."
ok "Log: $LOG_FILE"
