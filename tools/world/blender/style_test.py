import os, sys
sys.path.insert(0, os.path.dirname(__file__))
import kit, lib_nature as N
OUT = os.path.join(os.path.dirname(__file__), "..", "out")
kit.reset()
assets = [
    N.tree_round("TreeRoundA", 11, height=16, width=12),
    N.tree_ball("TreeBallA", 5),
    N.pine("PineA", 7),
    N.pine("PineSnowA", 8, snow=True),
    N.bush("BushA", 3, flowers=4),
    N.rock("RockA", 21),
    N.bank("BankA", 4),
    N.mound("HillA", 9),
    N.mountain("MountainA", 13),
    N.flowers("FlowersA", 2),
    N.grass("GrassA", 6),
    N.slab_stack("SlabA", 31),
]
roots = [x.build()[0] for x in assets]
kit.preview(roots[:6], os.path.join(OUT, "style_test_1.png"), size=300)
kit.preview(roots[6:], os.path.join(OUT, "style_test_2.png"), size=300)
print("DONE")
