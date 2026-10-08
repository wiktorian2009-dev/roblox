# price_diff.py - compare part prices between two PlowConfig files (old live vs freshly generated).
import re, sys
def parts(p):
    s = open(p, encoding="utf-8").read()
    return {m.group(1): float(m.group(2)) for m in re.finditer(r'\t(\w+) = \{Slot = "\w+".*?Price = ([0-9.e+]+),', s)}
a, b = parts(sys.argv[1]), parts(sys.argv[2])
ch = [(k, a[k], b[k]) for k in a if k in b and abs(a[k] - b[k]) > 1e-9]
print(len(a), "->", len(b), "parts; changed", len(ch), "up", sum(1 for _, x, y in ch if y > x), "down", sum(1 for _, x, y in ch if y < x))
for k, x, y in sorted(ch, key=lambda t: t[1])[:60]: print("%-22s %10.3g -> %10.3g (x%.2f)" % (k, x, y, y / x))
