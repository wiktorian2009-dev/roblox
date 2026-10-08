# sweep.py - quick comparison of several balance variants (efficient + casual, value and legacy buyers).
import json, sys, copy, importlib
import exp, catalog2 as C2

BASE_P = copy.deepcopy(C2.P)

def one(name, v, n=12, behs=("efficient", "casual"), w2=False):
    C2.P.clear(); C2.P.update(copy.deepcopy(BASE_P))
    res, cat = exp.run(v, n, behs=behs, w2=w2)
    print("=====", name)
    exp.show(res)
    return res

if __name__ == "__main__":
    vs = json.load(open(sys.argv[1]))
    n = int(sys.argv[2]) if len(sys.argv) > 2 else 12
    w2 = len(sys.argv) > 3 and sys.argv[3] == "w2"
    for name, v in vs.items(): one(name, v, n, w2=w2)
