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
    hypr
    niri
    gtk-3.0
    gtk-4.0
)

# File lẻ: "nguồn:đích"
readonly EXTRA_FILES=(
    "$LIVE_CONFIG/starship.toml:$REPO_DIR/configs/starship.toml"
    "$HOME/.gtkrc-2.0:$REPO_DIR/configs/gtkrc-2.0"
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
    [ -f "$src" ] && cp "$src" "$dst"
done

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
