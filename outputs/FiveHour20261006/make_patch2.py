# make_patch2.py (2026-10-06, Claude): Studio patch scripts (Luau) that turn the live sources (= before2/) into game/src, line by line.
# Every changed line is located by a unique key (part id, {Id = "..."} entry, or the full old line) and replaced with the new line.
# usage: python make_patch2.py <beforeDir> -> writes patch_<File>.luau next to this script
import difflib, os, re, sys
ROOT = r"C:\Users\wikto\Desktop\Roblox Gra"
S = os.path.join(ROOT, "game", "src", "ReplicatedStorage")
B = os.path.join(ROOT, "outputs", "FiveHour20261006", sys.argv[1] if len(sys.argv) > 1 else "before2")
OUT = os.path.join(ROOT, "outputs", "FiveHour20261006")
def key(line):
    m = re.match(r'^(\t\w+ = \{Slot)', line) or re.match(r'^(\s*\{Id = "\w+",)', line)
    return m.group(1) if m else None
def lq(s): return "[==[" + s + "]==]"
for f in ("StageConfig", "PlowConfig", "PetConfig", "UpgradeConfig", "ActivityConfig"):
    a = open(os.path.join(B, f + ".luau"), encoding="utf-8").read().split("\n")
    b = open(os.path.join(S, f + ".luau"), encoding="utf-8").read().split("\n")
    ops, inserts = [], []
    for tag, i1, i2, j1, j2 in difflib.SequenceMatcher(None, a, b, autojunk=False).get_opcodes():
        if tag == "equal": continue
        if tag == "replace" and i2 - i1 == j2 - j1:
            for x, y in zip(a[i1:i2], b[j1:j2]):
                k = key(x)
                if not k or key(y) != k or sum(1 for l in a if l.startswith(k)) != 1: k = x   # fall back to the whole old line
                ops.append((k, y))
        elif tag == "insert" and i1 > 0:
            inserts.append((a[i1 - 1], "\n".join(b[j1:j2])))   # insert after this (unique) old line
        else:
            ops.append(("\n".join(a[i1:i2]), "\n".join(b[j1:j2])))   # whole old block -> new block
    lines = ["local s = game.ReplicatedStorage.%s.Source" % f, "local n = 0",
             "local function rep(k, new) local i = s:find(k, 1, true); assert(i, k:sub(1, 60)); local j = s:find('\\n', i + 1, true) or (#s + 1)",
             "\tif k:find('\\n') then j = i + #k end",
             "\ts = s:sub(1, i - 1) .. new .. s:sub(j); n += 1 end",
             "local function after(k, new) local i = s:find(k .. '\\n', 1, true); assert(i, k:sub(1, 60)); local j = i + #k",
             "\ts = s:sub(1, j - 1) .. '\\n' .. new .. s:sub(j); n += 1 end"]
    for k, y in ops: lines.append("rep(%s, %s)" % (lq(k), lq(y)))
    for k, y in inserts: lines.append("after(%s, %s)" % (lq(k), lq(y)))
    lines.append("game.ReplicatedStorage.%s.Source = s" % f)
    lines.append("return '%s ' .. n .. ' edits, ' .. #s .. ' bytes'" % f)
    open(os.path.join(OUT, "patch_%s.luau" % f), "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")
    print(f, len(ops), "replacements", len(inserts), "inserts", sum(len(l) for l in lines), "chars")
