import w2lib as L

# Import-pipeline test pack: axis marker + representative Sakura bush (Claude 2026-10-02)
GREY, RED, BLUE, GREEN = L.P("9AA3B0"), L.P("E8413C"), L.P("3A7BEA"), L.P("49C25B")
mk = L.Model("W2Test_Axis", at=(-20, 0, 0))
L.rbox(mk, GREY, (0, 0, 0), (4, 2, 1), r=0.15, base=True, part="Base")
L.sphere(mk, RED, (2.5, 0, 0.5), 0.5, part="PlusX")
L.sphere(mk, BLUE, (0, -1.5, 0.5), 0.5, part="FrontMinusY")
L.cyl(mk, GREEN, (0, 0, 1), r=0.25, h=3, part="Up")

LEAF, PINK, PALE, BARK = L.P("5FB35A"), L.P("FF9CC6"), L.P("FFE3EF"), L.P("8A5A3C")
bush = L.Model("BlossomBush", at=(0, 0, 0))
L.blob(bush, LEAF, (0, 0, 1.6), rad=2.4, n=5, seed=3, flat=0.75, part="Leaves")
import random
rnd = random.Random(7)
for i in range(14):
    import math
    a = rnd.uniform(0, 6.283); d = rnd.uniform(0.6, 2.4); z = rnd.uniform(1.4, 3.3)
    L.sphere(bush, PINK if i % 3 else PALE, (math.cos(a) * d, math.sin(a) * d, z), rnd.uniform(0.45, 0.75), seg=10, rings=7, part="Blossoms")
L.cyl(bush, BARK, (0, 0, 0), r=0.5, r2=0.35, h=0.8, seg=10, part="Stem")
models = [mk, bush]

objs = L.realize(models, 'W2_Test')
