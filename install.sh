#!/usr/bin/env bash
# ==============================================================================
# umbriel-dots installer
# Umbriel compositor + Noctalia shell + qylock + MikuPlymouth
# Repo: https://github.com/<you>/umbriel-dots
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# --- Paths ---
readonly REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIGS_DIR="$REPO_DIR/configs"
readonly EXTERNAL_DIR="$REPO_DIR/external"
readonly TIMESTAMP="$(date +%Y-%m-%d-%H%M%S)"
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
ok "Backup done. Restore anytime from: $BACKUP_DIR"

# ==============================================================================
# Step 2: Deploy configs
# ==============================================================================
log "Deploying configs..."
for item in "${CONFIG_ITEMS[@]}"; do
    [ -d "$CONFIGS_DIR/$item" ] || { warn "Skipping missing $item"; continue; }
    rsync -a "$CONFIGS_DIR/$item/" "$HOME/.config/$item/"
    ok "~/.config/$item"
done

cp "$CONFIGS_DIR/starship.toml" "$HOME/.config/starship.toml" 2>/dev/null || warn "starship.toml not found"
cp "$REPO_DIR/configs/gtkrc-2.0" "$HOME/.gtkrc-2.0" 2>/dev/null || true
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
else
    warn "MikuPlymouth submodule not initialized"
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
