#!/usr/bin/env bash
# ==============================================================================
# validate.sh — kiểm tra configs/scripts trong repo
# Chạy cục bộ:  ./validate.sh
# GitHub Actions: .github/workflows/validate.yml gọi script này mỗi lần push
# ==============================================================================

set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m'

pass() { echo -e "${GREEN}PASS${NC} $*"; }
skip() { echo -e "${YELLOW}SKIP${NC} $*"; }
fail() { echo -e "${RED}FAIL${NC} $*"; exit 1; }

echo "==> umbriel-dots validation"
echo

# ------------------------------------------------------------------------------
# 1) shellcheck cho các shell scripts
# ------------------------------------------------------------------------------
if command -v shellcheck >/dev/null 2>&1; then
    shellcheck install.sh sync.sh validate.sh
    pass "shellcheck: install.sh sync.sh validate.sh"
else
    skip "shellcheck chưa cài (CI vẫn có, máy cục bộ: pacman -S shellcheck)"
fi

# ------------------------------------------------------------------------------
# 2) bash -n: check cú pháp bash không cần chạy
# ------------------------------------------------------------------------------
for f in install.sh sync.sh validate.sh; do
    bash -n "$f" || fail "Lỗi cú pháp bash: $f"
done
pass "bash -n: toàn bộ scripts hợp lệ"

# ------------------------------------------------------------------------------
# 3) TOML: parse mọi file .toml trong configs/ (umbriel, noctalia settings, ...)
#    Yêu cầu Python 3.11+ (tomllib)
# ------------------------------------------------------------------------------
python3 - <<'PYEOF' || fail "Có file .toml lỗi cú pháp (xem ở trên)"
import pathlib, sys, tomllib

bad = []
for p in sorted(pathlib.Path("configs").rglob("*.toml")):
    try:
        tomllib.loads(p.read_text(encoding="utf-8"))
        print(f"  OK   {p}")
    except Exception as e:
        bad.append(str(p))
        print(f"  ERR  {p}: {e}")

print()
if bad:
    print(f"{len(bad)} file TOML lỗi: {', '.join(bad)}")
    sys.exit(1)
print("Tất cả file .toml hợp lệ")
PYEOF
pass "TOML syntax: configs/**/*.toml"

# ------------------------------------------------------------------------------
# 4) fastfetch config.jsonc: JSONC = JSON + comments + trailing commas
#    Strip comments/trailing-comma rồi parse JSON thường
# ------------------------------------------------------------------------------
python3 - <<'PYEOF' || fail "configs/fastfetch/config.jsonc không parse được"
import json, pathlib, re, sys

p = pathlib.Path("configs/fastfetch/config.jsonc")
if not p.exists():
    print("  (không có config.jsonc, bỏ qua)")
    sys.exit(0)

txt = p.read_text(encoding="utf-8")
# strip /* */ comments, và // comments CHỈ khi ở đầu dòng hoặc sau whitespace
# (tránh ăn nhầm "//" trong URL kiểu https://...)
txt = re.sub(r"/\*.*?\*/", "", txt, flags=re.S)
txt = re.sub(r"(?m)^[ \t]*//.*$", "", txt)
txt = re.sub(r"(?m)(?<=[ \t,])//.*$", "", txt)
# strip trailing commas
txt = re.sub(r",\s*([}\]])", r"\1", txt)

try:
    json.loads(txt)
    print(f"  OK   {p}")
except json.JSONDecodeError as e:
    print(f"  ERR  {p}: {e}")
    sys.exit(1)
PYEOF
pass "JSONC syntax: fastfetch config"

echo
echo -e "${GREEN}✔ Validate hoàn tất — configs sạch lỗi.${NC}"
