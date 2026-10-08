# apply_edits.py <file> <edits.json> : applies the same ordered exact-string edits that were applied live in Studio (multi_edit)
import json, sys
path, ed = sys.argv[1], sys.argv[2]
src = open(path, "rb").read().decode("utf-8")
for e in json.load(open(ed, encoding="utf-8")):
    old, new = e["old_string"], e["new_string"]
    n = src.count(old)
    if n != 1: raise SystemExit("edit not unique/missing (%d): %r" % (n, old[:80]))
    src = src.replace(old, new)
open(path, "wb").write(src.encode("utf-8"))
print("ok", path)
