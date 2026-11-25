#!/usr/bin/env python3
"""Fit Noctalia widgets to the active screen, preserving aspect ratio.

Run automatically by install.sh / the noctalia-widget-fit timer, or by hand:

    python3 ~/umbriel-dots/scripts/noctalia-fit-widgets.py

What it does (only when something actually changed):
  * rewrites /home/nevil -> $HOME in Noctalia's saved state
  * renames the output saved in settings (eDP-1 on the source machine) to the
    connected output on this machine
  * rescales lockscreen AND desktop widget geometry from its saved placement
    size to the current screen, scaling positions per axis but box sizes by a
    single factor (so widgets never stretch on ultrawide / tall screens), then
    clamping boxes inside the screen
  * if the saved wallpaper is missing, uses the first image found in the
    wallpaper directories
"""

from __future__ import annotations

import argparse
import glob
import os
import pathlib
import re
import subprocess
import sys

HOME = pathlib.Path.home()
DEFAULT_SETTINGS = HOME / ".local/state/noctalia/settings.toml"
DEFAULT_STATE = HOME / ".local/state/noctalia/state.toml"
GEOM_RE = re.compile(
    r"^(\s*)(cx|cy|box_width|box_height|placement_width|placement_height)"
    r"(\s*=\s*)(-?[0-9.]+)"
)


def log(msg: str) -> None:
    print(f"   ↳ {msg}")


def detect_output() -> str:
    """Connected connector from sysfs; prefer laptop panels."""
    status = sorted(pathlib.Path("/sys/class/drm").glob("card*-*/status"))
    first = ""
    for f in status:
        try:
            if f.read_text().strip() != "connected":
                continue
        except OSError:
            continue
        # card1-eDP-1 -> eDP-1
        name = f.parent.name.partition("-")[2]
        if not name:
            continue
        if name.startswith(("eDP", "LVDS", "DSI")):
            return name
        first = first or name
    return first


def detect_mode(output: str) -> tuple[int, int] | None:
    """Preferred mode (WxH) of a connector from sysfs."""
    if not output:
        return None
    for f in pathlib.Path("/sys/class/drm").glob(f"card*-{output}/modes"):
        try:
            first = f.read_text().splitlines()[0]
        except (OSError, IndexError):
            continue
        m = re.match(r"^(\d+)x(\d+)", first)
        if m:
            return int(m.group(1)), int(m.group(2))
    return None


def fmt(v: float) -> str:
    v = round(v, 2)
    if abs(v - round(v)) < 1e-9:
        return f"{int(round(v))}.0"
    return f"{v:.2f}".rstrip("0").rstrip(".") or "0"


def is_widget(section: str) -> bool:
    return (
        section.startswith(("[lockscreen_widgets.widget.", "[desktop_widgets.widget."))
        and ".settings]" not in section
    )


def split_blocks(lines: list[str]) -> list[tuple[str, int, int]]:
    """[(section_name, header_index, first_line_after_block), ...]"""
    blocks: list[tuple[str, int, int]] = []
    current: str | None = None
    start = 0
    for i, line in enumerate(lines):
        s = line.strip()
        if s.startswith("[") and s.endswith("]"):
            if current is not None:
                blocks.append((current, start, i))
            current, start = s, i
    if current is not None:
        blocks.append((current, start, len(lines)))
    return blocks


def fit_geometry(text: str, nw: int, nh: int) -> tuple[str, bool]:
    lines = text.splitlines()
    blocks = split_blocks(lines)

    old_w = old_h = None
    for section, a, b in blocks:
        if not is_widget(section):
            continue
        for line in lines[a + 1 : b]:
            m = re.match(r"\s*placement_width\s*=\s*([0-9.]+)", line)
            if m and old_w is None:
                old_w = float(m.group(1))
            m = re.match(r"\s*placement_height\s*=\s*([0-9.]+)", line)
            if m and old_h is None:
                old_h = float(m.group(1))
        if old_w and old_h:
            break
    if not old_w or not old_h:
        return text, False

    sx, sy = nw / old_w, nh / old_h
    if abs(sx - 1.0) < 1e-6 and abs(sy - 1.0) < 1e-6:
        return text, False
    # One uniform factor for box sizes: positions follow each axis, boxes never
    # get stretched when the aspect ratio changes (ultrawide, 4:3, portrait...).
    scale = max(0.4, min(sx, sy, 3.0))
    changed = False

    for section, a, b in blocks:
        if not is_widget(section):
            continue
        values: dict[str, tuple[int, float, str, str]] = {}
        for i in range(a + 1, b):
            m = GEOM_RE.match(lines[i])
            if m:
                values[m.group(2)] = (i, float(m.group(4)), m.group(1), m.group(3))
        if not values:
            continue

        bw = values["box_width"][1] * scale if "box_width" in values else None
        bh = values["box_height"][1] * scale if "box_height" in values else None

        for key, (i, val, indent, eq) in values.items():
            if key == "placement_width":
                new = float(nw)
            elif key == "placement_height":
                new = float(nh)
            elif key == "box_width":
                new = val * scale
            elif key == "box_height":
                new = val * scale
            elif key == "cx":
                new = nw / 2 + (val - old_w / 2) * sx
                if bw:
                    new = min(max(new, bw / 2), max(bw / 2, nw - bw / 2))
            elif key == "cy":
                new = nh / 2 + (val - old_h / 2) * sy
                if bh:
                    new = min(max(new, bh / 2), max(bh / 2, nh - bh / 2))
            else:
                continue
            line = f"{indent}{key}{eq}{fmt(new)}"
            if line != lines[i]:
                lines[i] = line
                changed = True

    if changed:
        log(
            f"widget {int(old_w)}x{int(old_h)} -> {nw}x{nh} "
            f"(scale {scale:.2f}, aspect-preserving)"
        )
    return "\n".join(lines) + "\n", changed


def section_text(text: str, name: str) -> str:
    m = re.search(
        r"^[ \t]*\[" + re.escape(name) + r"\][ \t]*\n(.*?)(?=^[ \t]*\[|\Z)",
        text,
        re.M | re.S,
    )
    return m.group(1) if m else ""


def wallpaper_fallback(text: str, roots: list[str]) -> tuple[str, bool]:
    sec = section_text(text, "wallpaper.default")
    m = re.search(r'^[ \t]*path[ \t]*=[ \t]*"([^"]*)"', sec, re.M)
    if not m:
        return text, False
    old = m.group(1)
    if os.path.isfile(os.path.expanduser(old)):
        return text, False

    candidates: list[str] = []
    for root in roots:
        if not root or not os.path.isdir(root):
            continue
        for ext in ("png", "jpg", "jpeg", "webp"):
            candidates.extend(
                glob.glob(os.path.join(root, "**", f"*.{ext}"), recursive=True)
            )
        if candidates:
            break
    if not candidates:
        print(f"   ! wallpaper {old} không tồn tại và không tìm thấy ảnh thay thế")
        return text, False
    new = sorted(candidates, key=lambda p: (p.count(os.sep), p))[0]
    log(f"wallpaper không tồn tại -> {new}")
    return text.replace(old, new), True


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--settings", default=str(DEFAULT_SETTINGS))
    ap.add_argument("--state", default=str(DEFAULT_STATE))
    ap.add_argument("--output", help="override detected output")
    ap.add_argument("--mode", help="override detected mode, e.g. 2560x1440")
    ap.add_argument("--wallpaper-dir", action="append", default=[])
    ap.add_argument("--no-reload", action="store_true")
    args = ap.parse_args()

    settings = pathlib.Path(args.settings)
    if not settings.is_file():
        print(f"Noctalia settings not found: {settings}", file=sys.stderr)
        return 1

    output = args.output or detect_output()
    mode = args.mode
    if not mode and output:
        found = detect_mode(output)
        mode = f"{found[0]}x{found[1]}" if found else ""

    text = settings.read_text(encoding="utf-8")
    changed = False

    # 1) Hardcoded source paths -> this machine's $HOME (settings + state)
    if "/home/nevil" in text:
        text = text.replace("/home/nevil", str(HOME))
        changed = True
    state = pathlib.Path(args.state)
    if state.is_file():
        state_text = state.read_text(encoding="utf-8")
        if "/home/nevil" in state_text:
            state.write_text(state_text.replace("/home/nevil", str(HOME)), encoding="utf-8")

    # 2) Saved output -> connected output (covers eDP-1 from the source machine)
    m = re.search(r'^[ \t]*output[ \t]*=[ \t]*"([^"]+)"', text, re.M)
    saved_output = m.group(1) if m else "eDP-1"
    if output and saved_output != output:
        n = text.count(saved_output)
        text = text.replace(saved_output, output)
        log(f"output {saved_output} -> {output} ({n} chỗ)")
        changed = True

    # 3) Aspect-aware widget fit
    m = re.match(r"^(\d+)x(\d+)$", mode or "")
    if m:
        text, fit_changed = fit_geometry(text, int(m.group(1)), int(m.group(2)))
        changed = changed or fit_changed

    # 4) Wallpaper fallback
    roots = args.wallpaper_dir or [str(HOME / "Pictures/Wallpapers")]
    text, wp_changed = wallpaper_fallback(text, roots)
    changed = changed or wp_changed

    if changed:
        settings.write_text(text, encoding="utf-8")
        if not args.no_reload:
            try:
                subprocess.run(
                    ["noctalia", "msg", "config-reload"],
                    check=False,
                    capture_output=True,
                    timeout=5,
                )
            except (OSError, subprocess.SubprocessError):
                pass
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
