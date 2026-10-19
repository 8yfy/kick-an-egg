"""Deterministic tutorial PNGs extending the existing Kick an Egg SVG icon language.
Run with the bundled Python. Sources are editable SVGs; PNGs are actual 512px RGBA assets.
"""
import importlib.util
import argparse
import json
from pathlib import Path
import subprocess
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "tutorial"
SOURCE = OUT / "src"
spec = importlib.util.spec_from_file_location("game_icons", ROOT / "tools/icons/make_icons.py")
icons = importlib.util.module_from_spec(spec)
spec.loader.exec_module(icons)
GOLD = "#ffd43a"


def make(name):
    icon = icons.Icon()
    if name == "FocusArrow":
        path = 'd="M35 88 H125 V40 L222 128 L125 216 V168 H35 Q25 168 25 158 V98 Q25 88 35 88Z"'
        icon.raw(f'<path {path} transform="translate(0 5)" fill="#080a10" stroke="#080a10" stroke-width="22" stroke-linejoin="round"/>')
        icon.raw(f'<path {path} fill="#fff2ed" stroke="#fff2ed" stroke-width="11" stroke-linejoin="round"/>')
        icon.shape("path", path, "#ff493e", 4)
        icon.gloss("path", 'd="M39 100 H137 V67 L192 117 H39 Q35 117 35 111 V104 Q35 100 39 100Z"', .45)
    elif name == "Pointer":
        icon.shape("path", 'd="M38 91 H132 V43 L220 128 L132 213 V165 H38 Z"', GOLD)
        icon.gloss("path", 'd="M50 102 H145 V72 L194 120 H50 Z"', .5)
        icon.sparkle(166, 107, 10)
    elif name == "WorldArrow":
        icon.shape("path", 'd="M87 35 H169 V122 H216 L128 220 L40 122 H87 Z"', "#e49313", 16)
        icon.shape("path", 'd="M87 27 H161 V114 H208 L120 206 L40 114 H87 Z"', GOLD, 10)
        icon.gloss("path", 'd="M99 40 H146 V115 L120 145 H99 Z"', .48)
        icon.sparkle(135, 61, 12)
    elif name == "Checkmark":
        icon.shape("path", 'd="M35 125 L77 89 L112 131 L188 43 L228 78 L113 214 Z"', "#78ee3b", 16)
        icon.gloss("path", 'd="M50 124 L76 102 L111 147 L193 57 L211 75 L111 180 Z"', .45)
    elif name == "Sparkle":
        icon.shape("path", 'd="M128 25 Q145 107 227 128 Q145 147 128 231 Q109 148 27 128 Q108 110 128 25Z"', GOLD, 10)
        icon.gloss("path", 'd="M128 55 L143 115 L195 128 L131 135 L119 193 L117 135 L60 128 L117 118 Z"', .65)
    elif name == "TargetRing":
        icon.raw('<circle cx="128" cy="128" r="92" fill="none" stroke="#1d1030" stroke-width="23" opacity=".35"/>')
        icon.raw('<circle cx="128" cy="128" r="92" fill="none" stroke="#ffd43a" stroke-width="14"/>')
        icon.raw('<path d="M67 59 A92 92 0 0 1 188 59" fill="none" stroke="#fff8c9" stroke-width="7" stroke-linecap="round"/>')
        for x, y in [(128, 24), (232, 128), (128, 232), (24, 128)]:
            icon.raw(f'<circle cx="{x}" cy="{y}" r="6" fill="#fff4ae"/>')
    else:
        icon.shape("path", 'd="M38 121 L128 38 L218 121 L191 150 L128 94 L65 150 Z M38 184 L128 101 L218 184 L191 213 L128 157 L65 213Z"', GOLD, 11)
        icon.gloss("path", 'd="M57 119 L128 54 L200 119 L189 130 L128 78 L68 130Z"', .55)
    return icon.svg(shadow=name not in {"TargetRing", "PathMarker"})


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("names", nargs="*", choices=["FocusArrow", "Pointer", "WorldArrow", "Checkmark", "Sparkle", "TargetRing", "PathMarker"])
    args = parser.parse_args()
    SOURCE.mkdir(parents=True, exist_ok=True)
    chrome = Path(r"C:\Program Files\Google\Chrome\Application\chrome.exe")
    manifest = OUT / "local-assets.json"
    results = json.loads(manifest.read_text(encoding="utf-8")) if manifest.exists() else {}
    for name in args.names or ["FocusArrow", "Pointer", "WorldArrow", "Checkmark", "Sparkle", "TargetRing", "PathMarker"]:
        svg, png = SOURCE / f"{name}.svg", OUT / f"{name}.png"
        svg.write_text(make(name), encoding="utf-8")
        subprocess.run([str(chrome), "--headless=new", "--disable-gpu", "--hide-scrollbars",
                        "--no-first-run", "--default-background-color=00000000", "--window-size=512,512",
                        f"--screenshot={png}", svg.as_uri()], check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                       creationflags=subprocess.CREATE_NO_WINDOW)
        image = Image.open(png).convert("RGBA")
        alpha = image.getchannel("A")
        assert image.size == (512, 512) and alpha.getextrema() == (0, 255)
        assert image.getpixel((0, 0))[3] == 0
        image.save(png)
        results[name] = {"file": f"assets/tutorial/{name}.png", "size": [512, 512], "alpha": True}
        print(f"{name}: 512x512 RGBA, transparent corners", flush=True)
    manifest.write_text(json.dumps(results, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
