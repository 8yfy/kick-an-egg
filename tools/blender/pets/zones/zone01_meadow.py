# Zone 1 Meadow (greens, cream, soft tan; leaves, sprouts, flowers, bark): the data the kit builds and bakes into
# src/shared/Builders/Models/Baked/Zone01.luau. One entry per pair: pet (body plan + parameters + features),
# egg (shell paint + decorations) and a 3+1 palette (three main colours + one Neon glow accent).
ZONE = dict(n=1, name="Meadow", ground="5DAE4A")

HEADER = """--!strict
-- Zone 1 Meadow: egg + pet block data for Sprout Pup, Bumble Bloc and Meadow Stag (docs/EggPetPlan.md).
-- BAKED FILE: modelled in Blender from Roblox primitives (assets/blender/pets/Zone01.blend) by the pet kit in
-- tools/blender/pets (data: zones/zone01_meadow.py). Change the data there and re-bake instead of editing by hand.
-- Pets/Zone01.luau and Eggs/Zone01.luau point their entries here. Each joint group starts with its pivot part.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)
"""

SPROUT_PUP = dict(
    key="SproutPup",
    rarity="Common",
    title=[
        "01 Sprout Pup (Common, quadruped): a chibi leaf puppy with its head cocked, one leaf ear up and one",
        "flopped, a seedling on its head, a leaf tail and a glowing leaf pendant. Egg: cream under a leafy cap with",
        "a pinked leaf edge, a paw print and a sprout.",
    ],
    palette=dict(main="70CC48", dark="3A9438", light="FAF2D2", glow="96FF6E", sprig="B4EE74", blush="FF9CB0"),
    pet=dict(
        plan="quadruped",
        body=dict(pts=[(0, 1.2, 1.1), (0, 1.3, 0.1), (0, 1.45, -0.85)], n=2, w=[(0, 1.75), (1, 1.9)],
                  t=[(0, 1.2), (1, 1.32)], col=("main",), hinge=False),
        front=dict(x=0.6, y=1.0, z=-0.62, len=[0.6], ang=[0], w=0.58, col="main",
                   foot=dict(size=(0.72, 0.32, 0.84), col="light", fwd=0.1)),
        back=dict(x=0.64, y=1.0, z=0.9, len=[0.6], ang=[0], w=0.6, col="main",
                  foot=dict(size=(0.72, 0.32, 0.8), col="light", fwd=0.06)),
        head=dict(kind="block", at=(0, 3.0, -1.0), size=(2.5, 2.05, 2.0), roll=8, yaw=-6, hinge=False,
                  face="light", muzzle=(1.0, 0.56, 0.42, -0.5), muzzle_col="light",
                  eyes=dict(style="cute", x=0.56, y=0.12, w=0.5, h=0.62, look_in=0.04, lift=0.09),
                  cheeks=dict(x=0.86, y=-0.32, w=0.36, h=0.18, lift=0.09)),
        tail=dict(kind="leaf", pts=[(0, 1.55, 1.25), (0, 1.9, 1.5)], dir=(0, 0.75, 0.66), len=1.0, w=0.52,
                  col="sprig", stem_col="dark"),
        features=[
            ("ears", dict(kind="leaf", at=(1.24, 0.74, 0.15), len=1.5, w=0.86, col="dark",
                          droop=((0.5, 0.86, 0.06), (0.22, -1, 0.06)), normals=((0, 0, -1), (1, 0, 0)))),
            ("sprout", dict(at=(0, 1.0, 0.05), stem=0.55, leaf=0.95, w=0.5, col="sprig", stem_col="dark")),
            ("collar", dict(s=1.0, col="dark", gem="glow")),
        ],
    ),
    egg=dict(
        h=3.9, w=3.0,
        paint=[(1, 3, "light"), (4, -2, "main"), (-1, -1, "sprig")],
        deco=[
            ("drips", dict(name="Leaf", y=3 * 3.9 / 7, lengths=(0.5, 0.42, 0.5), col="main", per_face=3,
                           spread=0.82, point=True)),
            ("paw", dict(a=-22, y=0.62, col="dark", s=1.05)),
            ("sprout", dict(stem=0.42, leaf=0.66, w=0.36, col="sprig", stem_col="dark")),
        ],
    ),
)

BUMBLE_BLOC = dict(
    key="BumbleBloc",
    rarity="Uncommon",
    title=[
        "02 Bumble Bloc (Uncommon, insect): a chubby hovering bumblebee with a fuzzy cream collar, a striped",
        "abdomen curling down to a honey-dipper stinger, glass wings and dangling legs. Egg: honey stripes, a wax",
        "honeycomb band, honey dripping off the top, glass wing nubs and antennae.",
    ],
    palette=dict(main="FFCD28", dark="2A2226", light="FFF2D2", glow="FFA51E", glass="DDF2FF", blush="FF8CBE",
                 wax="F5B63A"),
    pet=dict(
        plan="insect",
        body=dict(
            thorax=dict(at=(0, 2.45, 0.15), size=(1.7, 1.6, 1.5), col="main"),
            abdomen=dict(pts=[(0, 2.0, 2.55), (0, 2.38, 1.7), (0, 2.45, 0.8)], n=4,
                         w=[(0, 1.35), (0.5, 2.25), (1, 1.85)], t=[(0, 1.25), (0.5, 2.1), (1, 1.75)],
                         col=("dark", "main"), stretch=1.08),
        ),
        head=dict(kind="round", at=(0, 2.75, -1.42), size=(2.1, 1.9, 1.7), neck=(0, 2.4, -0.7), col="dark",
                  face="main", eyes=dict(style="cute", x=0.5, y=0.08, w=0.62, h=0.7, look_in=0.05, lift=0.09),
                  cheeks=dict(x=0.8, y=-0.38, w=0.34, h=0.2, lift=0.09), mouth=dict(w=0.4, y=-0.5, lift=0.09)),
        antennae=dict(x=0.42, y=0.92, z=-0.15, out=0.4, up=1.0, fwd=-0.3, len=0.85, tip=0.34, tip_col="glow"),
        wings=dict(root=(0.55, 3.2, 0.45), span=2.4, chord=1.2, rise=48, sweep=18, caps=(True, False), transp=0.22),
        legs=dict(w=0.14, col="dark",
                  front=[dict(hip=(0.55, 1.85, -0.2), out=0.22, drop=(-0.42, -0.36), fwd=-0.15)],
                  rear=[dict(hip=(0.5, 1.85, 0.3), out=0.3, drop=(-0.45, -0.4), fwd=0.05),
                        dict(hip=(0.45, 1.95, 0.75), out=0.3, drop=(-0.5, -0.45), fwd=0.22)]),
        features=[
            ("fuzz", dict(at=(0, 2.6, -0.6), size=(2.22, 2.22, 0.62), col="light", axis="z")),
            ("dipper", dict(len=1.0, r=0.56, col="dark", rings=3, ring_col="wax", drip=None)),
        ],
    ),
    egg=dict(
        h=4.1, w=3.1,
        paint=[(1, 1, "dark"), (2, 2, "main"), (3, 3, "dark"), (4, 4, "main"), (5, 5, "dark"), (6, 7, "wax")],
        deco=[
            ("hexband", dict(y=2.05, per_side=1, size=0.62, col="wax")),
            ("drips", dict(name="Honey", y=5 * 4.1 / 7 + 0.05, lengths=(0.45, 0.8, 0.4, 0.7), col="glow", w=0.3,
                           per_face=1, material="Neon", drop=0.36)),
            ("wingnubs", dict(y=2.7, size=(0.1, 1.2, 1.4), tilt=24, back=0.3, out=0.32)),
            ("antennae", dict(x=0.32, len=0.75, lean=24, tip=0.3, tip_col="glow")),
        ],
    ),
)

MEADOW_STAG = dict(
    key="MeadowStag",
    rarity="Rare",
    title=[
        "03 Meadow Stag (Rare, quadruped): a proud forest stag mid-step, foreleg raised, with wide branching bark",
        "antlers in glowing blossom, a moss mantle over its shoulders, a cream chest and glowing eyes. Egg: fawn",
        "with cream dapples, a moss crown band in bloom, two little branch antlers and the Rare band.",
    ],
    palette=dict(main="B87A46", dark="5A3A24", light="F6E2BA", glow="8CFF6A", moss="5AAE40", blossom="FFF2D2"),
    pet=dict(
        plan="quadruped",
        scale=1.12,
        body=dict(pts=[(0, 2.35, 1.35), (0, 2.45, 0.35), (0, 2.62, -0.6), (0, 2.78, -1.25)], n=4,
                  w=[(0, 1.48), (0.5, 1.36), (1, 1.56)], t=[(0, 1.26), (0.55, 1.2), (1, 1.46)],
                  col=("main", "main2"), belly=dict(col="light", **{"from": 0.5})),
        front=dict(x=0.44, y=2.15, z=-0.95, len=[1.0, 0.95], ang=[0, 0], w=[0.38, 0.26], col="main",
                   foot=dict(name="Hoof", size=(0.34, 0.3, 0.42), col="dark")),
        back=dict(x=0.44, y=2.15, z=1.15, len=[0.8, 0.75, 0.62], ang=[15, -35, 5], w=[0.5, 0.32, 0.25], col="main",
                  foot=dict(name="Hoof", size=(0.34, 0.3, 0.42), col="dark")),
        pose={"ArmR": [48, -62]},
        neck=dict(pts=[(0, 2.95, -1.2), (0, 3.6, -1.55), (0, 4.25, -1.65)], n=2, w=0.78, t=0.82, col=("main",)),
        head=dict(kind="long", at=(0, 4.6, -2.02), size=(1.1, 1.0, 1.2), pitch=-10, snout=0.95, chin="light",
                  nose="dark", nose_size=(0.34, 0.2), eyes=dict(style="side", y=0.16, z=-0.14, w=0.46, h=0.28, socket=False)),
        tail=dict(kind="tuft", pts=[(0, 2.6, 1.85), (0, 2.85, 2.05)], size=(0.5, 0.62, 0.36), col="light",
                  stem_col="main"),
        features=[
            ("ears", dict(kind="leaf", at=(0.44, 0.28, 0.3), dir=(1, 0.35, 0.3), len=0.8, w=0.42, thick=0.12,
                          col="main")),
            ("antlers", dict(base=(0.32, 0.48, 0.18),
                             beams=[((0.55, 0.8, 0.2), 1.0), ((0.92, 0.42, 0.1), 1.0), ((0.6, 0.78, -0.12), 0.8)],
                             tines=[(1, (0.12, 1, -0.5), 0.7), (2, (0.3, 0.92, 0.42), 0.62)], col="dark", w0=0.27,
                             taper=0.8, blooms=("b", 1, 2), bloom_size=0.56)),
            ("mantle", dict(s0=0.45, s1=1.0, col="moss", wf=1.2, over=0.08, th=0.34, bloom=0.5,
                            blossoms=((0.85, -1), (0.6, 1)))),
        ],
    ),
    egg=dict(
        h=4.2, w=3.2,
        paint=[(1, 1, "dark"), (2, -1, "main")],
        deco=[
            ("rarity", dict(y=1.2, th=0.2, out=0.08)),
            ("band", dict(name="CrownBand", y=3.05, th=0.34, out=0.07, col="moss")),
            ("blooms", dict(y=3.05, angles=(-20, 70, 160, 250), size=0.4, lift=0.12)),
            ("plates", dict(name="Dapple", at=((-25, 2.1), (40, 2.45), (110, 1.95), (185, 2.35), (250, 2.0),
                                              (315, 2.4)), size=(0.4, 0.34, 0.14), col="light")),
            ("nubs", dict(base=(0.5, -0.32, 0.0), beams=(((0.45, 0.85, 0.15), 0.55), ((0.7, 0.6, 0.1), 0.4)),
                          col="dark", w0=0.2, blooms=("b",), bloom_size=0.34)),
        ],
    ),
)

PAIRS = [SPROUT_PUP, BUMBLE_BLOC, MEADOW_STAG]

# Matters of taste, shown side by side for the user's pick (preview.py options=1); A = the entries above.
# Picked 2026-10-29: Sprout Pup one perked + one floppy ear (A), Bumble Bloc dark head with a yellow face (B),
# Meadow Stag leaf-green glow with cream blossoms (B). Both B picks are folded into the entries above.
OPTIONS = {}

# Original VFX sprites (assets/pet-vfx/vfx_<name>.png; build.py textures=1 redraws them).
LEAF = [
    ".........###",
    "......######",
    "....########",
    "...####.####",
    "..####.#####",
    "..###.######",
    ".###.######.",
    ".##.######..",
    ".#.######...",
    "..######....",
    ".#..##......",
    "#...........",
]
BLOSSOM = [
    "....###....",
    "...#####...",
    "...#####...",
    ".##.###.##.",
    "#####.#####",
    "####.#.####",
    "#####.#####",
    ".##.###.##.",
    "...#####...",
    "...#####...",
    "....###....",
]
HONEY = [
    "....#....",
    "....#....",
    "...###...",
    "...###...",
    "..#####..",
    ".#######.",
    ".#o#####.",
    "#o#######",
    "#o#######",
    "##o######",
    ".#######.",
    "..#####..",
]


def _sprites():
    from kit import sprites as X

    return {
        "meadow_leaf": lambda p: X.pixel(p, LEAF),
        "meadow_blossom": lambda p: X.pixel(p, BLOSSOM),
        "meadow_honey": lambda p: X.pixel(p, HONEY, values={"#": 0.82, "o": 1.0}),
    }
