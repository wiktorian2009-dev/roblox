import sys; sys.path.insert(0, r'C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender')
import math, random
from mathutils import Vector

# Natural mist bank (Claude 2026-10-03): elliptical, layered stratus puffs; dense core -> transparent wispy edges.
# Authored in Roblox axes (X = travel, Y = up, Z = width) and converted with R2B.
from w2lib import *
def R2B(p): return Vector((-p[0], p[2], p[1]))
models = []
mb = Model("MistBank"); models.append(mb)
rq = random.Random(21)
W_, H_ = 205.0, 125.0
CORE, MID, EDGE, LOW = P("F7F9FF", "SP", .3), P("F2F5FF", "SP", .5), P("EEF2FC", "SP", .72), P("E4E8F5", "SP", .42)
n = 0
while n < 78:
    u, v = rq.uniform(-1, 1), rq.uniform(-1, 1)
    e = u * u + v * v
    if e > 1: continue
    z = u * W_; y = 18 + v * H_ * (.85 if v > 0 else .55); x = rq.uniform(-15, 15)
    r = rq.uniform(20, 34) * (1.15 - .45 * e)
    if y < -28: pc, part = LOW, "Low"
    elif e < .3: pc, part = CORE, "Core"
    elif e < .65: pc, part = MID, "Mid"
    else: pc, part = EDGE, "Edge"
    sphere(mb, pc, R2B((x, y, z)), r, scl=(.6, 1.65, .72), rot=(0, rq.uniform(-6, 6), rq.uniform(-10, 10)), seg=10, rings=6, part=part)
    n += 1
for i in range(14):   # wisps along the top
    a = -1 + 2 * i / 13; z = a * W_ * .8 + rq.uniform(-12, 12); y = 18 + H_ * .85 * math.sqrt(max(0, 1 - a * a)) + rq.uniform(-8, 6)
    sphere(mb, P("F4F7FF", "SP", .8), R2B((rq.uniform(-10, 10), y, z)), rq.uniform(16, 26), scl=(.4, 2.4, .35), seg=10, rings=6, part="Wisps")

objs = realize(models, 'W2_Mist')
