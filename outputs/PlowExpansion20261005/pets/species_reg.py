# registry of per-species builders: @pet("Exact Name") def f(m): ... (may return finish() kwargs)
REG = {}
def pet(name):
    def deco(fn):
        REG[name] = fn; return fn
    return deco
