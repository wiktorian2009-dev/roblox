# luaparts.py - parses C.Parts from a PlowConfig.luau source (the disk mirror is hash-identical to live Studio).
import re

ROW = re.compile(r'^\t(\w+) = \{Slot = "(\w+)", Name = "((?:[^"\\]|\\.)*)", Model = "(\w+)", Rarity = "(\w+)", Band = (\d+), Role = "(\w)", Theme = "([^"]*)", Kind = "(\w+)", Price = ([0-9.e+]+),\s*\n\t\tDesc = "((?:[^"\\]|\\.)*)", Stats = \{([^}]*)\}\},', re.M)

def parse(path):
    src = open(path, encoding="utf-8").read()
    out = {}
    for m in ROW.finditer(src):
        stats = {}
        for kv in m.group(12).split(","):
            k, v = kv.split("=")
            stats[k.strip()] = float(v)
        out[m.group(1)] = {"slot": m.group(2), "name": m.group(3), "model": m.group(4), "rarity": m.group(5), "band": int(m.group(6)),
                           "role": m.group(7), "theme": m.group(8), "kind": m.group(9), "price": float(m.group(10)), "desc": m.group(11), "stats": stats}
    return out

if __name__ == "__main__":
    import sys
    p = parse(sys.argv[1])
    print(len(p))
