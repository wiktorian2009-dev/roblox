import sys
def h(path):
    b = open(path, "rb").read()
    if b.startswith(b"\xef\xbb\xbf"): b = b[3:]
    x = 0
    for c in b: x = (x * 31 + c) % 2147483647
    return len(b), x
for p in sys.argv[1:]: print(p, *h(p))
