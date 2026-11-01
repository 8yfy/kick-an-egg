# Honeyback Beetle (Zone 1 Meadow, Uncommon): a golden honeycomb beetle built to the user's reference
# (images/6.webp, "Honeyplate Beetle"), Roblox primitives only (Frost Serpent method). A dark brown beetle under a big
# round dome tiled with gold honeycomb cells (some with glowing amber centres), white flowers and green leaves on the
# dome, a gold hex plate on the thorax and head, two glowing white eyes, antennae with yellow tips, six chunky legs
# with green leaf pads and yellow feet, and two big amber glass wings raised behind in a V.
# Joints: Body, Head, AntennaL/R, ShellL/R (the dome halves, they part for Honeywing Lift), WingL/R, LegL1-3,
# LegR1-3 (front to back; L1 R2 L3 / R1 L2 R3 are the alternating tripods).
import math

from mathutils import Matrix, Vector

from kit import anatomy as A
from kit.rbx import C3, CF, J, cf, frame, look, use
from v3 import top_parts as T

NAME, RARITY = "Honeyback Beetle", "Uncommon"
PAL = dict(main="6B4022", dark="4A2C16", light="F6E3B4", glow="FFB02E", gold="F7C531", honey="F7C531",
           honey2="B8730C", amber="FF9A1C", yellow="F5C72E", leaf="5FB544", leaf3="8FD44A", flower="FFFFFF",
           flower2="F2F2EA", pollen="FFC93C", eye="FFF8E0", glass="FFB02E", vein="D9800F", ink="1A0F08")
CONCEPT = "Honeyback Beetle: a beetle under a golden honeycomb dome, flowers, amber wings, leaf-padded legs"
HEADER = '''--!strict
-- Honeyback Beetle (Zone 1 Meadow, Uncommon). Zone 1 Meadow roster (Config/Pets).
-- Pet: a dark brown beetle under a big round dome tiled with gold honeycomb cells (some glowing amber), white flowers
--      and leaves on the dome, gold hex plates on the thorax and head, glowing white eyes, yellow-tipped antennae, six
--      chunky legs with green leaf pads and yellow feet, two big amber wings raised behind. Joints: Body, Head,
--      AntennaL/R, ShellL/R, WingL/R, LegL1-3, LegR1-3.
-- Egg: a golden honeycomb egg glowing amber between the cells, white flowers and leaves at the base.
-- BAKED FILE: modelled in Blender from Roblox primitives by tools/blender/pets (zone1/honeyback_beetle.py,
-- zone1/eggs.py).
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)
'''
SCALE = 1.1

E0 = Vector((0, 2.0, 0.45))  # the dome: an ellipsoid of these radii, filled by four balls and tiled with cells
ER = Vector((1.95, 1.55, 1.95))


def hexcell(k, name, pos, normal, size, col="gold", core=None, up=(0, 0, -1)):
    """Honeycomb cell lying on a surface: three bars at 60 degrees make a regular hexagon `size` across the flats;
    laid edge to edge, the shell between cells reads as the comb lines. `core` adds a glowing amber centre."""
    f = T.plane_frame(pos, normal, up)
    for i in range(3):
        k.p("%s%d" % (name, i + 1), (size, size * 0.577, 0.2), f * cf(rz=60 * i), col, studs=False)
    if core:
        k.p(name + "Core", (size * 0.5, size * 0.5 * 0.577, 0.15), f * CF((0, 0, 0.02)) * cf(rz=90), core,
            material="Neon", studs=False)


def on_dome(az, el, lift=0.0):
    """Point and normal on the dome at azimuth az (0 = front) and elevation el (degrees)."""
    a, e = math.radians(az), math.radians(el)
    d = Vector((math.cos(e) * math.sin(a), math.sin(e), -math.cos(e) * math.cos(a)))
    p = E0 + Vector((d.x * ER.x, d.y * ER.y, d.z * ER.z))
    n = Vector(((p - E0).x / ER.x ** 2, (p - E0).y / ER.y ** 2, (p - E0).z / ER.z ** 2)).normalized()
    return p + n * lift, n


def build(name="Z1_HoneybackBeetle_Pet", offset=(0, 0, 0)):
    from zone1.crownstag import flower

    k = A.Kit(A.Pal(PAL))
    coll = use(name, offset)

    # ---- body: a dark brown underbody and thorax ----------------------------------------------------------------------
    J("Body")
    k.hinge("Body", (0, 1.5, 0.3))
    k.p("Underbody", (2.9, 0.9, 3.7), CF(Vector((0, 1.4, 0.45))), "dark")
    k.p("Belly", (2.2, 0.3, 3.0), CF(Vector((0, 0.9, 0.5))), "main", studs=False)
    k.p("Thorax", (2.1, 1.15, 1.1), CF(Vector((0, 1.75, -1.6))), "main")
    hexcell(k, "ThoraxHex", Vector((0, 2.34, -1.6)), (0, 1, -0.15), 0.9, core="amber")

    # ---- the dome: two halves of studded honey balls tiled with gold honeycomb, flowers and leaves -------------------
    cells = []
    for el, n, size in ((12, 12, 0.98), (35, 10, 0.95), (57, 7, 0.88), (76, 4, 0.74), (90, 1, 0.7)):
        for i in range(n):
            az = 360 * (i + 0.5 * (el in (35, 76))) / n
            if el < 20 and (az < 30 or az > 330):
                continue  # the thorax sits here
            cells.append((az, el, size))
    flowers = ((330, 48), (115, 34), (215, 58))
    for sx, sd in A.SIDES:
        J("Shell" + sd)
        k.hinge("Shell" + sd, (sx * 0.3, 3.2, -0.4))
        for j, dz in enumerate((-0.45, 0.45)):
            k.p("Dome%s%d" % (sd, j + 1), (3.0, 3.0, 3.0), CF(E0 + Vector((sx * 0.45, -0.05, dz))), "honey2",
                shape="Ball")
        n = 0
        for az, el, size in cells:
            side = -1 if math.sin(math.radians(az)) < -1e-6 or (abs(math.sin(math.radians(az))) < 1e-6 and az > 90)\
                else 1
            if side != sx:
                continue
            if any(abs(az - fa) < 20 and abs(el - fe) < 14 for fa, fe in flowers):
                continue
            n += 1
            p, nrm = on_dome(az, el, 0.03)
            hexcell(k, "Comb%s%d" % (sd, n), p, nrm, size, core="amber" if n % 3 == 0 else None,
                    up=(0, 1, 0) if el < 85 else (0, 0, -1))
        for i, (fa, fe) in enumerate(flowers):
            if (math.sin(math.radians(fa)) < 0) != (sx < 0):
                continue
            p, nrm = on_dome(fa, fe, 0.12)
            flower(k, "Flower%s%d" % (sd, i + 1), p, nrm, 0.85, petal="flower", petal2="flower2", centre="pollen")
            for j, d in enumerate((Vector((0.6, -0.4, 0.5)), Vector((-0.6, -0.4, 0.3)))):
                A.leaf(k, "FlowerLeaf%s%d_%d" % (sd, i + 1, j + 1), p - nrm * 0.02, d + nrm * 0.3, 0.75, 0.42,
                       "leaf" if j else "leaf3", thick=0.1, normal=nrm)

    # ---- wings: two big amber glass wings raised behind the dome in a V ------------------------------------------------
    for sx, sd in A.SIDES:
        J("Wing" + sd)
        root = Vector((sx * 0.45, 3.1, 0.2))
        k.hinge("Wing" + sd, root)
        d = Vector((sx * 0.55, 0.8, 0.3)).normalized()
        hint = Vector((0, 0.35, -1))
        c = look(root + d * 1.45, d, hint)
        k.p("Wing" + sd, (1.5, 2.6, 0.08), c, "glass", material="Glass", transp=0.25, studs=False)
        k.p("WingTip" + sd, (1.06, 1.06, 0.08), look(root + d * 2.75, d, hint) * cf(rz=45), "glass", material="Glass",
            transp=0.25, studs=False)
        k.p("WingRoot" + sd, (0.9, 0.6, 0.08), look(root + d * 0.25, d, hint), "glass", material="Glass", transp=0.25,
            studs=False)
        for i, (x, ln, rz) in enumerate(((0.0, 2.7, 0), (-0.35, 1.8, 12), (0.38, 1.7, -12))):
            k.p("WingVein%s%d" % (sd, i + 1), (0.07, ln, 0.1), c * CF((x, 0.1, 0.01)) * cf(rz=rz), "vein",
                studs=False)
        k.p("WingEdge" + sd, (0.1, 2.6, 0.12), c * CF((-sx * 0.76, 0, 0.01)), "vein", studs=False)

    # ---- head: dark brown, a gold hex plate, glowing white eyes, mandibles ---------------------------------------------
    J("Head")
    k.hinge("Head", (0, 1.7, -2.1))
    k.p("Head", (1.5, 1.15, 1.05), CF(Vector((0, 1.6, -2.55))), "dark")
    k.p("Brow", (1.3, 0.28, 0.4), CF(Vector((0, 2.2, -2.75))), "main", studs=False)
    hexcell(k, "HeadHex", Vector((0, 2.2, -2.45)), (0, 1, -0.45), 0.85, core="amber")
    for sx, sd in A.SIDES:
        k.p("EyeRim" + sd, (0.4, 0.56, 0.06), CF(Vector((sx * 0.38, 1.62, -3.1))), "ink", studs=False)
        k.p("Eye" + sd, (0.28, 0.44, 0.06), CF(Vector((sx * 0.38, 1.62, -3.14))), "eye", material="Neon", studs=False)
        k.seg("Mandible" + sd, (sx * 0.3, 1.12, -3.0), (sx * 0.12, 0.98, -3.35), 0.2, 0.16, "main", studs=False)

    # ---- antennae: two bent segments with yellow tips -------------------------------------------------------------------
    for sx, sd in A.SIDES:
        J("Antenna" + sd)
        base = Vector((sx * 0.4, 2.15, -2.75))
        k.hinge("Antenna" + sd, base)
        pts = A.branch(k, "Antenna" + sd, base, (((sx * 0.25, 1, -0.35), 0.8), ((sx * 0.4, 0.45, -0.8), 0.7)),
                       "main", w0=0.18, taper=0.9)
        k.p("AntennaTip" + sd, (0.32, 0.32, 0.38), look(pts[2], Vector((sx * 0.4, 0.45, -0.8)), (0, 1, 0)),
            "yellow", studs=False)

    # ---- legs: six chunky legs, femur up and out to the knee with a leaf pad, tibia down to a yellow foot ------------
    for sx, sd in A.SIDES:
        for i, (z, dz) in enumerate(((-1.25, -0.45), (0.25, 0.0), (1.55, 0.45))):
            joint = "Leg%s%d" % (sd, i + 1)
            J(joint)
            hip = Vector((sx * 1.3, 1.25, z))
            k.hinge(joint, hip)
            knee = Vector((sx * 2.0, 1.6, z + dz))
            foot = Vector((sx * 2.3, 0.3, z + dz * 1.5))
            k.seg("Femur" + joint, hip, knee, 0.56, 0.56, "main")
            k.seg("Tibia" + joint, knee, foot, 0.46, 0.46, "dark")
            k.p("Pad" + joint, (0.56, 0.32, 0.6), CF(hip.lerp(knee, 0.55) + Vector((0, 0.3, 0))), "leaf")
            k.p("PadTop" + joint, (0.4, 0.14, 0.42), CF(hip.lerp(knee, 0.55) + Vector((0, 0.5, 0))), "leaf3",
                studs=False)
            k.p("Foot" + joint, (0.5, 0.3, 0.6), CF(Vector((foot.x, 0.15, foot.z))), "yellow", studs=False)

    J("Root")
    off = Matrix.Translation(C3 @ Vector(coll["rbx_offset"]))
    for ob in coll.objects:
        ob.matrix_world = off @ Matrix.Scale(SCALE, 4) @ off.inverted() @ ob.matrix_world
    return coll
