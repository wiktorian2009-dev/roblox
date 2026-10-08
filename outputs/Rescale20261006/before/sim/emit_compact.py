# emit_compact.py - compact Luau payload of the generated C.Parts block (rows with indexed theme/description), so Studio can rebuild
# exactly the same text as build/PlowConfig.luau (verified by the hash afterwards).
import json, os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(HERE, "..", "build", "PlowConfig.luau"), encoding="utf-8").read()
a = src.index("C.Parts = {\n") + len("C.Parts = {\n"); b = src.index("\n}\nfor id, def in pairs(C.Parts)")
block = src[a:b]
ROW = re.compile(r'^\t(\w+) = \{Slot = "(\w+)", Name = ("(?:[^"\\]|\\.)*"), Model = "(\w+)", Rarity = "(\w+)", Band = (\d+), Role = "(\w)", Theme = ("[^"]*"), Kind = "(\w+)", Price = ([^,]+),\n\t\tDesc = ("(?:[^"\\]|\\.)*"), Stats = \{([^}]*)\}\},$', re.M)
rows = ROW.findall(block)
assert len(rows) == 135, len(rows)
descs, themes = [], []
out = []
for r in rows:
    if r[7] not in themes: themes.append(r[7])
    if r[10] not in descs: descs.append(r[10])
    out.append('{"%s","%s",%s,"%s","%s",%s,"%s",%d,"%s","%s",%d,"%s"}' % (r[0], r[1], r[2], r[3], r[4], r[5], r[6], themes.index(r[7]) + 1, r[8], r[9], descs.index(r[10]) + 1, r[11]))
lua = "local TH={" + ",".join(themes) + "}\nlocal DE={" + ",".join(descs) + "}\nlocal RO={" + ",\n".join(out) + "}\n"
# rebuild check in python (same format as gen_lua2)
rebuilt = "\n".join('\t%s = {Slot = "%s", Name = %s, Model = "%s", Rarity = "%s", Band = %s, Role = "%s", Theme = %s, Kind = "%s", Price = %s,\n\t\tDesc = %s, Stats = {%s}},' % (r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11]) for r in rows)
assert rebuilt == block
open(os.path.join(HERE, "..", "build", "parts_compact.lua"), "w", encoding="utf-8", newline="\n").write(lua)
print(len(lua), "chars")
