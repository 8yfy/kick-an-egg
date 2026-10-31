# 63 Clockwork Titan V3 (Clockwork Factory, Divine hero), Roblox primitives only (Frost Serpent method, studs on top
# faces). Built to the user's reference (2026-10-31): a massive brass and dark-iron golem in square, heavy shapes. A
# glowing amber clock is its heart, ringed by a toothed brass rim and small gears; giant boxed pauldrons carry clock
# faces and brass spires; a helm with a crown of spires and an amber visor; red banners with gold gear emblems hang
# from the shoulders and the belt; arms with brass pistons, elbow gears, amber vents and huge segmented iron fists;
# legs with hip and knee gears, amber vents and heavy boots. Palette: brass, dark iron, amber glow, banner red.
# Joints: Body, Head, ArmL/R, LegL/R.
import math

from mathutils import Matrix, Vector

from kit import anatomy as A
from kit.rbx import C3, CF, J, cf, frame, look, use
from v3 import top_parts as T

PAL = dict(main="C9A24E", main2="A8823A", dark="34302D", iron2="4A4440", glow="FFB84A", face="F1E2B6",
           red="8E2B2B", ink="1A1614", light="F3D98C", glass="FFD99A", tip="FFF1C8")
CONCEPT = "Clockwork Titan: brass and iron golem, amber clock heart, clock pauldrons with spires, red banners"
HEADER = '''--!strict
-- 63 Clockwork Titan V3 (Clockwork Factory, Divine). Preview candidate (KICK_AN_EGG_PET_REMODEL_V3), not wired.
-- Pet: a massive brass and dark-iron golem (the user's reference): a glowing amber clock heart ringed by gears, boxed
--      pauldrons with clock faces and spires, a helm with a crown of spires and an amber visor, red banners with gear
--      emblems, pistons, elbow, hip and knee gears, amber vents, huge segmented fists and heavy boots.
-- Egg: iron and brass terraces, a glowing clock face ringed by a toothed rim, small gears, a red banner, spires on
--      top, amber vents, the Divine band.
-- BAKED FILE: modelled in Blender from Roblox primitives by tools/blender/pets (v3/clockwork_titan.py, v3/eggs_blocks.py).
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)
'''
SCALE = 1.1


def cyl(k, name, centre, axis, length, dia, col, **kw):
    """Roblox cylinders run along local X: point local X along `axis`."""
    A_ = Vector(axis).normalized()
    up = Vector((0, 1, 0)) if abs(A_.y) < 0.9 else Vector((0, 0, -1))
    Z = A_.cross(up).normalized()
    Y = Z.cross(A_).normalized()
    return k.p(name, (length, dia, dia), frame(Vector(centre), A_, Y, Z), col, shape="Cylinder", **kw)


def plated(k, name, size, centre, col_frame, col_inset, axis_front=(0, 0, -1)):
    """An armour box: a brass block with a dark iron inset plate on its front face (the reference's framed plates)."""
    c = Vector(centre)
    k.p(name, size, CF(c), col_frame)
    F = Vector(axis_front).normalized()
    if abs(F.z) > 0.5:
        k.p(name + "Inset", (size[0] * 0.72, size[1] * 0.72, 0.08), CF(c + F * (size[2] / 2 + 0.02)), col_inset,
            studs=False)
    else:
        k.p(name + "Inset", (0.08, size[1] * 0.72, size[2] * 0.72), CF(c + F * (size[0] / 2 + 0.02)), col_inset,
            studs=False)


def vent(k, name, centre, normal, n=2, h=0.6):
    """Glowing amber vent slits."""
    f = T.plane_frame(centre, normal)
    for i in range(n):
        k.p("%s%d" % (name, i + 1), (0.1, h, 0.06), f * CF(((i - (n - 1) / 2) * 0.2, 0, 0.03)), "glow",
            material="Neon", studs=False)


def build(name="PK3_ClockworkTitan_Pet", offset=(0, 0, 0)):
    k = A.Kit(A.Pal(PAL))
    coll = use(name, offset)

    # ---- body: waist, belt, banner, chest with the clock heart and gears ------------------------------------------
    J("Body")
    k.hinge("Body", (0, 3.0, 0))
    k.p("Waist", (1.9, 1.0, 1.4), CF(Vector((0, 2.75, 0.05))), "dark")
    k.p("Belt", (2.1, 0.32, 1.55), CF(Vector((0, 3.25, 0.05))), "main")
    cyl(k, "Buckle", (0, 3.25, -0.82), (0, 0, -1), 0.12, 0.5, "main2", studs=False)
    T.banner(k, "WaistBanner", (0, 3.1, -0.86), (0, 0, -1), 0.8, 1.7, "red", "main", emblem=True)
    k.p("Chest", (3.0, 2.5, 2.0), CF(Vector((0, 4.6, 0.0))), "dark")
    k.p("ChestTop", (2.7, 0.42, 1.8), CF(Vector((0, 6.05, 0.0))), "main")
    for sx, sd in A.SIDES:
        plated(k, "ChestPlate" + sd, (0.62, 2.2, 0.3), (sx * 1.2, 4.6, -1.08), "main", "iron2")
        plated(k, "SidePlate" + sd, (0.3, 2.0, 1.6), (sx * 1.58, 4.55, 0.0), "main", "iron2", axis_front=(sx, 0, 0))
        vent(k, "ChestVent" + sd, (sx * 1.2, 3.75, -1.25), (0, 0, -1), n=2, h=0.4)
    cc = Vector((0, 4.7, -1.12))
    T.clock(k, "Heart", cc, (0, 0, -1), 0.9, "glow", "main", "ink", "ink", glow=True, rim_n=18, hands=(-40, 70))
    T.teeth(k, "HeartTooth", cc + Vector((0, 0, -0.02)), (0, 0, -1), 0.98, 16, (0.2, 0.16, 0.2), "main2")
    T.star4(k, "HeartStar", cc + Vector((0, 0, -0.14)), (0, 0, -1), 0.5, "light", core="face", mat="SmoothPlastic",
            thick=0.06)
    for i, (x, y, r) in enumerate(((-1.0, 5.55, 0.3), (1.0, 5.55, 0.3), (-1.08, 3.95, 0.26), (1.08, 3.95, 0.26),
                                   (0.0, 5.82, 0.24), (-0.62, 3.65, 0.22), (0.62, 3.65, 0.22))):
        T.small_gear(k, "Gear%d" % (i + 1), (x, y, -1.18), (0, 0, -1), r, "main", "main2")
    k.p("BackPlate", (2.6, 2.2, 0.3), CF(Vector((0, 4.6, 1.12))), "main")
    T.small_gear(k, "BackGear", (0, 4.6, 1.32), (0, 0, 1), 0.7, "main2", "main")

    # ---- head: helm with a crown of spires and an amber visor -----------------------------------------------------
    J("Head")
    k.hinge("Head", (0, 6.2, -0.1))
    k.p("Helm", (1.3, 1.15, 1.2), CF(Vector((0, 6.85, -0.15))), "dark")
    k.p("HelmFrame", (1.4, 0.22, 1.28), CF(Vector((0, 7.38, -0.15))), "main")
    k.p("Cheeks", (1.4, 0.62, 0.3), CF(Vector((0, 6.6, -0.7))), "main")
    k.p("Visor", (1.0, 0.36, 0.1), CF(Vector((0, 6.95, -0.78))), "ink", studs=False)
    for sx, sd in A.SIDES:
        k.p("Eye" + sd, (0.32, 0.12, 0.06), CF(Vector((sx * 0.24, 6.97, -0.84))) * cf(rz=-sx * 8), "glow",
            material="Neon")
        k.p("Pupil" + sd, (0.1, 0.1, 0.04), CF(Vector((sx * 0.21, 6.97, -0.88))), "tip", material="Neon", studs=False)
        k.p("Glint" + sd, (0.05, 0.05, 0.03), CF(Vector((sx * 0.32, 7.01, -0.89))), "glint", material="Neon",
            studs=False)
    for i, (x, h, z) in enumerate(((0, 1.1, -0.15), (-0.42, 0.75, -0.25), (0.42, 0.75, -0.25), (-0.5, 0.55, 0.25),
                                   (0.5, 0.55, 0.25))):
        T.spire(k, "Crown%d" % (i + 1), (x, 7.48, z), h, 0.24 if i else 0.3, "main", "light")
    T.small_gear(k, "BrowGear", (0, 7.3, -0.8), (0, 0, -1), 0.2, "main", "main2")

    # ---- arms: boxed pauldron with a clock and spires, banner, pistons, elbow gear, vents, huge fist -----------------
    for sx, sd in A.SIDES:
        J("Arm" + sd)
        sh = Vector((sx * 1.85, 5.5, 0.0))
        k.hinge("Arm" + sd, sh)
        k.p("Pauldron" + sd, (1.75, 1.45, 1.75), CF(Vector((sx * 2.25, 5.95, 0.0))), "main")
        k.p("PauldronInset" + sd, (0.08, 1.05, 1.3), CF(Vector((sx * 3.14, 5.95, 0.0))), "dark", studs=False)
        T.clock(k, "ShoulderClock" + sd, (sx * 3.2, 5.95, 0.0), (sx, 0, 0), 0.5, "face", "main", "ink", "ink",
                rim_n=12, hands=(-50, 30))
        k.p("PauldronTop" + sd, (1.5, 0.24, 1.5), CF(Vector((sx * 2.25, 6.8, 0.0))), "dark")
        for j, (dx, dz, h) in enumerate(((0.55, -0.55, 0.85), (0.55, 0.55, 0.7), (-0.2, 0.0, 0.6))):
            T.spire(k, "ShoulderSpire%s%d" % (sd, j + 1), (sx * (2.25 + dx), 6.9, dz), h, 0.22, "main", "light")
        T.banner(k, "Banner" + sd, (sx * 2.3, 5.25, -0.92), (0, 0, -1), 0.7, 1.9, "red", "main", emblem=True)
        el = Vector((sx * 2.4, 3.85, -0.1))
        k.p("UpperArm" + sd, (0.8, 1.3, 0.8), CF((sh + el) / 2 + Vector((sx * 0.25, 0, 0))), "dark")
        for j, dz in enumerate((-0.25, 0.25)):
            cyl(k, "Piston%s%d" % (sd, j + 1), (sx * 2.85, 4.65, dz), (0, 1, 0), 1.1, 0.24, "main")
        cyl(k, "Elbow" + sd, el, (1, 0, 0), 0.7, 0.85, "main2")
        T.small_gear(k, "ElbowGear" + sd, el + Vector((sx * 0.38, 0, 0)), (sx, 0, 0), 0.38, "main", "main2")
        plated(k, "Forearm" + sd, (1.15, 1.5, 1.15), (sx * 2.45, 2.85, -0.15), "main", "dark")
        vent(k, "ArmVent" + sd, (sx * 3.04, 2.9, -0.15), (sx, 0, 0), n=2, h=0.7)
        k.p("ArmBand" + sd, (1.2, 0.16, 1.2), CF(Vector((sx * 2.45, 3.5, -0.15))), "main2", studs=False)
        k.p("Fist" + sd, (1.25, 1.0, 1.25), CF(Vector((sx * 2.45, 1.65, -0.25))), "dark")
        for j, dx in enumerate((-0.42, -0.14, 0.14, 0.42)):
            k.p("Knuckle%s%d" % (sd, j + 1), (0.26, 0.3, 0.3), CF(Vector((sx * 2.45 + dx, 1.95, -0.92))), "main")
            k.p("Finger%s%d" % (sd, j + 1), (0.26, 0.42, 0.24), CF(Vector((sx * 2.45 + dx, 1.42, -0.92))), "iron2",
                studs=False)
        k.p("Thumb" + sd, (0.3, 0.5, 0.3), CF(Vector((sx * 1.86, 1.75, -0.7))) * cf(rz=sx * 20), "iron2", studs=False)

    # ---- legs: hip gear, thigh, knee gear, shin with vents, heavy boot ------------------------------------------------
    for sx, sd in A.SIDES:
        J("Leg" + sd)
        hp = Vector((sx * 0.75, 2.4, 0.05))
        k.hinge("Leg" + sd, hp)
        k.p("Thigh" + sd, (1.0, 1.0, 1.1), CF(Vector((sx * 0.8, 2.0, 0.05))), "main")
        k.p("ThighInset" + sd, (0.7, 0.7, 0.08), CF(Vector((sx * 0.8, 2.0, -0.53))), "dark", studs=False)
        T.small_gear(k, "HipGear" + sd, (sx * 1.35, 2.3, 0.05), (sx, 0, 0), 0.5, "main", "main2")
        k.p("Shin" + sd, (1.05, 1.2, 1.15), CF(Vector((sx * 0.82, 0.95, 0.05))), "dark")
        vent(k, "ShinVent" + sd, (sx * 0.82, 0.98, -0.53), (0, 0, -1), n=2, h=0.55)
        T.small_gear(k, "KneeGear" + sd, (sx * 0.82, 1.55, -0.62), (0, 0, -1), 0.3, "main", "main2")
        k.p("Boot" + sd, (1.3, 0.42, 1.6), CF(Vector((sx * 0.84, 0.21, -0.12))), "main")
        k.p("BootToe" + sd, (1.2, 0.3, 0.4), CF(Vector((sx * 0.84, 0.15, -0.98))), "dark", studs=False)
    J("Root")
    off = Matrix.Translation(C3 @ Vector(coll["rbx_offset"]))
    for ob in coll.objects:
        ob.matrix_world = off @ Matrix.Scale(SCALE, 4) @ off.inverted() @ ob.matrix_world
    return coll
