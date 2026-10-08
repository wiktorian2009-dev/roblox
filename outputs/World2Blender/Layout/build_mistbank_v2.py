import sys; sys.path.insert(0, r'C:\Users\wikto\Desktop\Roblox Gra\outputs\World2Blender')
import math, random
from mathutils import Vector

# Natural mist bank v2 (Claude 2026-10-03): fewer, bigger, fully smooth puffs; dense core -> very soft edges; faint veils soften the outline.
from w2lib import *
def R2B(p): return Vector((-p[0], p[2], p[1]))
models = []
mb = Model("MistBankV2"); models.append(mb)
rq = random.Random(33)
W_, H_ = 200.0, 120.0
BANDS = {"Core": P("F8FAFF", "SP", .38), "Mid": P("F3F6FF", "SP", .58), "Edge": P("EFF3FD", "SP", .76), "Low": P("E6EAF6", "SP", .48)}
n = 0
while n < 44:
    u, v = rq.uniform(-1, 1), rq.uniform(-1, 1)
    e = u * u + v * v
    if e > 1: continue
    z = u * W_; y = 20 + v * H_ * (.85 if v > 0 else .55); x = rq.uniform(-12, 12)
    r = rq.uniform(32, 48) * (1.12 - .4 * e)
    part = "Low" if y < -26 else ("Core" if e < .35 else ("Mid" if e < .68 else "Edge"))
    sphere(mb, BANDS[part], R2B((x, y, z)), r, scl=(.55, 1.5, .75), rot=(0, rq.uniform(-5, 5), rq.uniform(-8, 8)), seg=16, rings=10, part=part)
    n += 1
for i in range(10):
    a = -1 + 2 * i / 9; z = a * W_ * .8 + rq.uniform(-10, 10); y = 20 + H_ * .85 * math.sqrt(max(0, 1 - a * a)) + rq.uniform(-6, 4)
    sphere(mb, P("F5F8FF", "SP", .86), R2B((rq.uniform(-8, 8), y, z)), rq.uniform(22, 30), scl=(.4, 2.3, .4), seg=16, rings=8, part="Wisps")
for i, (z, y, r) in enumerate([(-90, 10, 110), (80, 25, 120), (0, 60, 100)]):
    sphere(mb, P("F6F8FF", "SP", .88), R2B((0, y, z)), r, scl=(.35, 1.3, .7), seg=18, rings=10, part="Veils")
for k in list(mb.parts.keys()): mb.sharp[k] = 180

objs = realize(models, 'W2_Mist2')
