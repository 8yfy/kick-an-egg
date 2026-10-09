"""Kick the Egg UI icon set: writes SVG sources to assets/ui-icons/src and renders transparent 512 px PNGs
to assets/ui-icons with headless Chrome.

Style: glossy cartoon — 3-stop vertical gradients, a soft shade on the lower half, specular gloss strips,
sparkle glints, a thick dark outline (drawn under the fill) and a hard cartoon drop shadow.

usage:  python -I tools/icons/make_icons.py [chrome.exe]
"""
import math
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "assets", "ui-icons", "src")
OUT = os.path.join(ROOT, "assets", "ui-icons")
CHROME = sys.argv[1] if len(sys.argv) > 1 else r"C:\Program Files\Google\Chrome\Application\chrome.exe"
INK = "#1d1030"
FONT = "Arial Black, Segoe UI Black, sans-serif"


def hex2rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def rgb2hex(c):
    return "#%02x%02x%02x" % tuple(max(0, min(255, round(v))) for v in c)


def mix(h, t, k):
    a, b = hex2rgb(h), hex2rgb(t)
    return rgb2hex([a[i] + (b[i] - a[i]) * k for i in range(3)])


class Icon:
    def __init__(self):
        self.defs = []
        self.body = []
        self.grads = {}
        self.n = 0

    def grad(self, color):
        if color not in self.grads:
            gid = "g%d" % len(self.grads)
            self.grads[color] = gid
            self.defs.append(
                f'<linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1">'
                f'<stop offset="0" stop-color="{mix(color, "#ffffff", 0.42)}"/>'
                f'<stop offset="0.5" stop-color="{color}"/>'
                f'<stop offset="1" stop-color="{mix(color, "#000000", 0.28)}"/></linearGradient>'
            )
        return self.grads[color]

    def shape(self, tag, geom, color, outline=14, shade=True):
        """Filled shape with gradient, outline under the fill, and a soft bottom shade overlay."""
        g = self.grad(color)
        self.body.append(
            f'<{tag} {geom} fill="url(#{g})" stroke="{INK}" stroke-width="{outline}" '
            f'stroke-linejoin="round" stroke-linecap="round" paint-order="stroke"/>'
        )
        if shade:
            self.body.append(f'<{tag} {geom} fill="url(#shade)"/>')

    def raw(self, s):
        self.body.append(s)

    def gloss(self, tag, geom, opacity=0.6):
        self.body.append(f'<{tag} {geom} fill="#ffffff" opacity="{opacity}"/>')

    def sparkle(self, x, y, s):
        d = (f"M{x} {y - s} Q{x + s * 0.18} {y - s * 0.18} {x + s} {y} Q{x + s * 0.18} {y + s * 0.18} {x} {y + s} "
             f"Q{x - s * 0.18} {y + s * 0.18} {x - s} {y} Q{x - s * 0.18} {y - s * 0.18} {x} {y - s} Z")
        self.body.append(f'<path d="{d}" fill="#ffffff" opacity="0.95"/>')

    def text(self, x, y, s, size, color="#ffffff", anchor="middle", outline=10, rotate=0):
        tr = f' transform="rotate({rotate} {x} {y})"' if rotate else ""
        self.body.append(
            f'<text x="{x}" y="{y}" font-family="{FONT}" font-weight="900" font-size="{size}" text-anchor="{anchor}" '
            f'fill="{color}" stroke="{INK}" stroke-width="{outline}" stroke-linejoin="round" paint-order="stroke"{tr}>{s}</text>'
        )

    def svg(self, shadow=True):
        filt = (
            '<filter id="drop" x="-20%" y="-20%" width="140%" height="140%">'
            f'<feDropShadow dx="0" dy="7" stdDeviation="0" flood-color="{INK}" flood-opacity="0.45"/></filter>'
        )
        shade = ('<linearGradient id="shade" x1="0" y1="0" x2="0" y2="1">'
                 '<stop offset="0.5" stop-color="#000" stop-opacity="0"/>'
                 '<stop offset="1" stop-color="#000" stop-opacity="0.18"/></linearGradient>')
        group = f'<g filter="url(#drop)">' if shadow else "<g>"
        return (
            '<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 256 256">'
            f"<defs>{filt}{shade}{''.join(self.defs)}</defs>{group}{''.join(self.body)}</g></svg>"
        )


def poly(points):
    return 'points="' + " ".join(f"{x:.1f},{y:.1f}" for x, y in points) + '"'


def star(cx, cy, R, r, n=5, rot=-90):
    pts = []
    for i in range(2 * n):
        a = math.radians(rot + i * 180 / n)
        rad = R if i % 2 == 0 else r
        pts.append((cx + rad * math.cos(a), cy + rad * math.sin(a)))
    return pts


def ring_arrow(cx, cy, R, r, a0, a1, head=22):
    """Annular sector from a0 to a1 (degrees, clockwise, screen coords) with an arrowhead at a1."""
    def pt(rad, a):
        return cx + rad * math.cos(math.radians(a)), cy + rad * math.sin(math.radians(a))
    large = 1 if (a1 - a0) % 360 > 180 else 0
    o0, o1 = pt(R, a0), pt(R, a1)
    i0, i1 = pt(r, a0), pt(r, a1)
    mid = (R + r) / 2
    w = (R - r) / 2 + head
    tip = pt(mid, a1 + 26)
    ho, hi = pt(mid + w, a1), pt(mid - w, a1)
    return (f"M{o0[0]:.1f} {o0[1]:.1f} A{R} {R} 0 {large} 1 {o1[0]:.1f} {o1[1]:.1f} L{ho[0]:.1f} {ho[1]:.1f} "
            f"L{tip[0]:.1f} {tip[1]:.1f} L{hi[0]:.1f} {hi[1]:.1f} L{i1[0]:.1f} {i1[1]:.1f} "
            f"A{r} {r} 0 {large} 0 {i0[0]:.1f} {i0[1]:.1f} Z")


def egg_path(cx, top, bottom, w):
    h = bottom - top
    return (f"M{cx} {top} C{cx + w * 0.62} {top} {cx + w} {top + h * 0.55} {cx + w} {top + h * 0.66} "
            f"C{cx + w} {bottom - h * 0.06} {cx + w * 0.5} {bottom} {cx} {bottom} "
            f"C{cx - w * 0.5} {bottom} {cx - w} {bottom - h * 0.06} {cx - w} {top + h * 0.66} "
            f"C{cx - w} {top + h * 0.55} {cx - w * 0.62} {top} {cx} {top} Z")


ICONS = {}


def icon(fn):
    ICONS[fn.__name__] = fn
    return fn


@icon
def Shop(i):
    i.raw(f'<path d="M26 56 L58 56 L88 176" fill="none" stroke="{INK}" stroke-width="22" stroke-linecap="round" stroke-linejoin="round"/>')
    i.raw('<path d="M26 56 L58 56 L88 176" fill="none" stroke="#c9d3e6" stroke-width="9" stroke-linecap="round" stroke-linejoin="round"/>')
    i.shape("path", 'd="M60 82 L226 82 L204 172 L86 172 Z"', "#ff4d6d")
    i.raw('<path d="M84 112 L214 112 M92 142 L208 142" stroke="#ffffff" stroke-opacity="0.35" stroke-width="8" stroke-linecap="round"/>')
    i.gloss("rect", 'x="74" y="90" width="132" height="12" rx="6"', 0.55)
    i.shape("circle", 'cx="104" cy="204" r="19"', "#4b3b66")
    i.shape("circle", 'cx="184" cy="204" r="19"', "#4b3b66")
    i.gloss("circle", 'cx="98" cy="198" r="5"', 0.8)
    i.gloss("circle", 'cx="178" cy="198" r="5"', 0.8)
    i.shape("circle", 'cx="204" cy="64" r="30"', "#ffcf33")
    i.shape("polygon", poly(star(204, 65, 18, 8)), "#ff9f1c", outline=6, shade=False)
    i.sparkle(56, 112, 12)


@icon
def Index(i):
    i.shape("rect", 'x="56" y="30" width="152" height="194" rx="20"', "#3b82f6")
    i.shape("rect", 'x="72" y="200" width="136" height="26" rx="9"', "#fff6e5", outline=10)
    i.shape("rect", 'x="56" y="30" width="32" height="194" rx="14"', "#2559c9", outline=10)
    i.shape("path", 'd="M172 20 L172 72 L186 61 L200 72 L200 20 Z"', "#ff4d6d", outline=10)
    i.shape("circle", 'cx="148" cy="120" r="40"', "#fff6e5", outline=10)
    i.shape("polygon", poly(star(148, 122, 28, 12)), "#ffcf33", outline=7, shade=False)
    i.gloss("rect", 'x="98" y="42" width="66" height="13" rx="6.5"', 0.55)
    i.sparkle(206, 196, 11)


@icon
def Rebirth(i):
    i.shape("path", f'd="{ring_arrow(128, 132, 98, 64, 200, 330)}"', "#ff4d8d")
    i.shape("path", f'd="{ring_arrow(128, 132, 98, 64, 20, 150)}"', "#ffb020")
    i.shape("polygon", poly(star(128, 134, 36, 15)), "#ffe14d", outline=10)
    i.gloss("path", 'd="M70 92 Q96 50 140 44 Q118 58 100 86 Z"', 0.5)
    i.sparkle(212, 60, 12)


@icon
def Trade(i):
    i.shape("polygon", poly([(28, 64), (146, 64), (146, 32), (226, 92), (146, 152), (146, 120), (28, 120)]), "#3ddc6a")
    i.shape("polygon", poly([(228, 136), (110, 136), (110, 104), (30, 164), (110, 224), (110, 192), (228, 192)]), "#4cc3ff")
    i.gloss("rect", 'x="40" y="72" width="94" height="12" rx="6"', 0.6)
    i.gloss("rect", 'x="122" y="144" width="94" height="12" rx="6"', 0.6)
    i.sparkle(220, 40, 11)


@icon
def Settings(i):
    pts = []
    teeth = 9
    for k in range(teeth * 4):
        a = math.radians(k * 360 / (teeth * 4) - 90)
        rad = 104 if (k % 4) in (0, 1) else 82
        pts.append((128 + rad * math.cos(a), 130 + rad * math.sin(a)))
    i.shape("polygon", poly(pts), "#a9b6d0")
    i.shape("circle", 'cx="128" cy="130" r="56"', "#7c8bad", outline=10)
    i.shape("circle", 'cx="128" cy="130" r="26"', "#3a2d55", outline=8, shade=False)
    i.gloss("path", 'd="M84 80 Q110 58 150 60 Q120 70 100 96 Z"', 0.5)
    i.sparkle(208, 52, 11)


@icon
def Coins(i):
    for k, c in enumerate(["#1f9d55", "#2fb866", "#46d27c"]):
        y = 130 - k * 20
        i.shape("rect", f'x="{22 + k * 4}" y="{y}" width="172" height="84" rx="14"', c, outline=12)
    i.raw('<rect x="44" y="104" width="128" height="56" rx="10" fill="none" stroke="#1f9d55" stroke-width="5"/>')
    i.shape("rect", 'x="94" y="86" width="30" height="104" rx="6"', "#fff1b8", outline=8)
    i.shape("circle", 'cx="186" cy="174" r="50"', "#ffc83d")
    i.raw('<circle cx="186" cy="174" r="35" fill="none" stroke="#e09a12" stroke-width="7"/>')
    i.text(186, 197, "$", 62, color="#fff3c4", outline=9)
    i.gloss("rect", 'x="38" y="96" width="52" height="10" rx="5"', 0.55)
    i.gloss("path", 'd="M152 150 Q166 128 192 126 Q174 136 166 154 Z"', 0.6)


@icon
def WalkSpeed(i):
    for k, y in enumerate((96, 128, 160)):
        i.shape("rect", f'x="{14 + k * 6}" y="{y}" width="{46 - k * 8}" height="14" rx="7"', "#bfe6ff", outline=8, shade=False)
    i.shape("path", 'd="M72 66 L138 66 L148 116 L208 132 Q240 140 238 176 L238 186 L64 186 Z"', "#3fa0ff")
    i.shape("rect", 'x="56" y="176" width="190" height="30" rx="13"', "#ffffff", outline=12)
    i.shape("rect", 'x="74" y="104" width="76" height="22" rx="8"', "#ffd23f", outline=8)
    i.raw('<path d="M160 136 L176 120 M178 142 L194 126" stroke="#ffffff" stroke-width="7" stroke-linecap="round"/>')
    i.gloss("rect", 'x="84" y="76" width="44" height="12" rx="6"', 0.6)
    i.sparkle(220, 100, 11)


@icon
def Power(i):
    i.shape("polygon", poly(star(150, 116, 96, 58, n=9, rot=-80)), "#ffd23f", shade=False)
    i.raw('<g transform="rotate(-24 120 150)">')
    i.shape("path", 'd="M58 70 L120 70 L128 116 L190 130 Q220 138 218 170 L218 180 L50 180 Z"', "#ff5a3c")
    i.shape("rect", 'x="42" y="170" width="184" height="28" rx="12"', "#ffffff", outline=12)
    for x in (70, 110, 150, 190):
        i.shape("rect", f'x="{x}" y="196" width="18" height="16" rx="5"', "#4b3b66", outline=7, shade=False)
    i.gloss("rect", 'x="68" y="80" width="42" height="12" rx="6"', 0.6)
    i.raw("</g>")
    i.sparkle(222, 42, 12)


@icon
def PetSlots(i):
    i.shape("path", f'd="{egg_path(116, 22, 232, 84)}"', "#fff1d0")
    for cx, cy, rx, ry in ((88, 128, 18, 15), (140, 96, 13, 12), (128, 178, 20, 16)):
        i.raw(f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="#ffb347"/>')
    i.gloss("ellipse", 'cx="86" cy="76" rx="12" ry="28" transform="rotate(20 86 76)"', 0.6)
    i.shape("circle", 'cx="194" cy="190" r="40"', "#3ddc6a")
    i.raw('<path d="M194 168 L194 212 M172 190 L216 190" stroke="#ffffff" stroke-width="13" stroke-linecap="round"/>')


@icon
def Pets(i):
    i.shape("ellipse", 'cx="128" cy="168" rx="62" ry="54"', "#ffa040")
    for cx, cy in ((56, 104), (98, 58), (158, 58), (200, 104)):
        i.shape("ellipse", f'cx="{cx}" cy="{cy}" rx="26" ry="31"', "#ffa040")
    i.gloss("ellipse", 'cx="104" cy="146" rx="22" ry="9"', 0.55)
    for cx, cy in ((92, 44), (152, 44)):
        i.gloss("circle", f'cx="{cx}" cy="{cy}" r="6"', 0.7)
    i.sparkle(216, 40, 11)


@icon
def Hatch(i):
    i.shape("path", f'd="{egg_path(128, 18, 236, 92)}"', "#fff1d0")
    for cx, cy, rx, ry in ((94, 132, 20, 16), (152, 98, 14, 13), (140, 186, 22, 17)):
        i.raw(f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="#7bd3ff"/>')
    i.raw(f'<path d="M62 150 L86 136 L104 156 L126 136 L148 158 L170 138 L194 152" fill="none" stroke="{INK}" stroke-width="7" stroke-linejoin="round" stroke-linecap="round"/>')
    i.gloss("ellipse", 'cx="94" cy="72" rx="13" ry="30" transform="rotate(20 94 72)"', 0.6)
    i.sparkle(212, 44, 12)


@icon
def Sound(i):
    i.shape("rect", 'x="34" y="96" width="50" height="66" rx="12"', "#a9b6d0")
    i.shape("path", 'd="M80 96 L140 52 L140 206 L80 162 Z"', "#7c8bad")
    for r, w in ((40, 15), (70, 15)):
        i.raw(f'<path d="M{150 + r * 0.3} {129 - r} Q{150 + r * 1.3} 129 {150 + r * 0.3} {129 + r}" fill="none" stroke="{INK}" stroke-width="{w + 12}" stroke-linecap="round"/>')
        i.raw(f'<path d="M{150 + r * 0.3} {129 - r} Q{150 + r * 1.3} 129 {150 + r * 0.3} {129 + r}" fill="none" stroke="#4cc3ff" stroke-width="{w}" stroke-linecap="round"/>')
    i.gloss("rect", 'x="44" y="104" width="30" height="10" rx="5"', 0.6)


@icon
def Close(i):
    i.raw('<g transform="rotate(45 128 128)">')
    i.shape("rect", 'x="104" y="30" width="48" height="196" rx="20"', "#ff4d5e")
    i.shape("rect", 'x="30" y="104" width="196" height="48" rx="20"', "#ff4d5e")
    i.raw('<rect x="106" y="32" width="44" height="192" rx="18" fill="url(#g0)"/>')
    i.raw("</g>")
    i.gloss("rect", 'x="86" y="56" width="16" height="44" rx="8" transform="rotate(-45 94 78)"', 0.55)


@icon
def CoinBoost(i):
    i.shape("circle", 'cx="118" cy="138" r="90"', "#ffc83d")
    i.raw('<circle cx="118" cy="138" r="66" fill="none" stroke="#e09a12" stroke-width="10"/>')
    i.text(118, 176, "$", 108, color="#fff3c4", outline=12)
    i.gloss("path", 'd="M48 112 Q66 64 116 56 Q80 78 66 120 Z"', 0.6)
    i.shape("rect", 'x="150" y="22" width="92" height="60" rx="16"', "#3ddc6a")
    i.text(196, 70, "x2", 46, outline=9)


@icon
def Gamepasses(i):
    i.shape("polygon", poly([(32, 92), (82, 132), (128, 52), (174, 132), (224, 92), (204, 196), (52, 196)]), "#ffc83d")
    i.shape("rect", 'x="46" y="180" width="164" height="38" rx="12"', "#ff9f1c")
    i.text(128, 210, "VIP", 30, outline=8)
    for cx, cy, c in ((128, 132, "#ff4d6d"), (82, 156, "#4cc3ff"), (174, 156, "#3ddc6a")):
        i.shape("circle", f'cx="{cx}" cy="{cy}" r="15"', c, outline=7, shade=False)
    for cx, cy in ((32, 92), (128, 52), (224, 92)):
        i.shape("circle", f'cx="{cx}" cy="{cy}" r="14"', "#ffe680", outline=8, shade=False)
    i.gloss("path", 'd="M60 120 L84 140 L110 96 L86 128 Z"', 0.5)
    i.sparkle(212, 42, 12)


@icon
def Luck(i):
    i.raw(f'<path d="M128 140 Q150 196 186 228" fill="none" stroke="{INK}" stroke-width="24" stroke-linecap="round"/>')
    i.raw('<path d="M128 140 Q150 196 186 228" fill="none" stroke="#2fb866" stroke-width="11" stroke-linecap="round"/>')
    for ang in (0, 90, 180, 270):
        i.raw(f'<g transform="rotate({ang} 128 120)">')
        i.shape("path", 'd="M128 120 C96 102 70 80 86 56 C98 38 120 44 128 62 C136 44 158 38 170 56 C186 80 160 102 128 120 Z"', "#3ddc6a", outline=12)
        i.raw("</g>")
    i.gloss("ellipse", 'cx="104" cy="66" rx="12" ry="7" transform="rotate(-30 104 66)"', 0.6)
    i.sparkle(216, 44, 12)


@icon
def Quests(i):
    i.shape("rect", 'x="52" y="40" width="152" height="180" rx="10"', "#fff1c9")
    i.shape("rect", 'x="40" y="26" width="176" height="30" rx="15"', "#e8c27a", outline=12)
    i.shape("rect", 'x="40" y="204" width="176" height="30" rx="15"', "#e8c27a", outline=12)
    for k, y in enumerate((96, 136, 176)):
        i.raw(f'<path d="M74 {y} L86 {y + 12} L106 {y - 10}" fill="none" stroke="#2fb866" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>')
        i.raw(f'<rect x="118" y="{y - 4}" width="{70 - k * 12}" height="10" rx="5" fill="#d9b77a"/>')
    i.gloss("rect", 'x="54" y="32" width="70" height="9" rx="4.5"', 0.6)


@icon
def New(i):
    i.shape("polygon", poly(star(128, 128, 112, 84, n=14, rot=-90)), "#ff3b55")
    i.text(128, 150, "NEW", 58, outline=12, rotate=-10)
    i.sparkle(212, 44, 12)


def glow_svg():
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 256 256"><defs>'
            '<radialGradient id="r" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#fff7c2" stop-opacity="0.9"/>'
            '<stop offset="0.45" stop-color="#fff2a0" stop-opacity="0.35"/><stop offset="1" stop-color="#fff" stop-opacity="0"/>'
            '</radialGradient></defs><circle cx="128" cy="128" r="128" fill="url(#r)"/></svg>')


def main():
    os.makedirs(SRC, exist_ok=True)
    names = list(ICONS) + ["Glow"]
    for name in names:
        if name == "Glow":
            svg = glow_svg()
        else:
            ic = Icon()
            ICONS[name](ic)
            svg = ic.svg()
        path = os.path.join(SRC, name + ".svg")
        with open(path, "w", encoding="utf-8") as f:
            f.write(svg)
        out = os.path.join(OUT, name + ".png")
        subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--default-background-color=00000000",
                        "--window-size=512,512", f"--screenshot={out}", "file:///" + path.replace("\\", "/")],
                       check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print(name, os.path.getsize(out))


if __name__ == "__main__":
    main()
