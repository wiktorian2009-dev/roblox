# catalog2.py - stats, prices and offer roles for the 135-part catalog (90 existing + 45 role-M parts).
# Existing parts keep the formulas of catalog.py (PlowExpansion20261005); the tunables below may reprice them.
# Role M parts sit on a band's ladder between its practical A part (position 0) and its premium B part (position n+1):
# performance and price are interpolated geometrically, so every step up the ladder is a noticeable, affordable improvement.
import json, math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, "..", "data"))
import catalog_spec3 as spec   # 2026-10-05 task 7: 150 parts = the 135 rebalance parts + 15 bodies
import catalog as CAT1
import gamedata as G

P = dict(CAT1.P)
P.update({
    "PremiumGear": 1.12,   # B gear vs A gear of the same band
    "MidPower": 1.0,       # extra multiplier on interpolated M power (1 = pure geometric interpolation)
    "MidPriceSkew": 1.0,   # >1 pushes M prices toward B, <1 toward A
    "BandPriceMult": {},   # band -> multiplier on every A/M/B price of that band (repricing lever)
    "BPriceShare": {},     # band -> override of P["PB"] for that band's B parts
    # growth split between slots: blades grow BG2 per band, gears GG2; engines give back the difference so the product of the three
    # (= build power of a band's practical parts, which field HP is tuned against) stays what it was.
    "BG2": 1.15, "GG2": 1.07, "PremiumBlade": None,
    "ArchSpread": 1.0,     # exponent on engine / gear archetype power modifiers (<1 = archetypes become milder sidegrades)
    # BODY (task 7): Snow efficiency per band (A bodies), premium bonus, and price as a share of the band's practical / premium part price
    "BodySnowPerBand": 0.04, "BodySnowPremium": 0.04, "BodyPrice": 0.15, "BodyPriceB": 0.3, "BodyPrice1": 150,
})
OLD_BG, OLD_GG = 1.15, 1.07
def eg2():
    f = (OLD_BG * OLD_GG) / (P["BG2"] * P["GG2"])
    return [g * f for g in P["EG"]]
ENGINE_ARCH, BLADE_ARCH, GEAR_ARCH = CAT1.ENGINE_ARCH, CAT1.BLADE_ARCH, CAT1.GEAR_ARCH
FIXED_PRICE = CAT1.FIXED_PRICE
stage_cost, next_stage_cost, level, nice = CAT1.stage_cost, CAT1.next_stage_cost, CAT1.level, CAT1.nice

def ladders(parts):
    """(slot, band) -> {pid: (position, steps)} for A / M / B parts (M in spec order)"""
    out = {}
    for slot in ("Blade", "Engine", "Gear"):
        for k in range(1, 15):
            row = [p for p in parts if p["slot"] == slot and p["band"] == k]
            a = [p for p in row if p["role"] == "A"]; b = [p for p in row if p["role"] == "B"]; m = [p for p in row if p["role"] == "M"]
            if not m: continue
            steps = len(m) + 1
            lad = {}
            if a: lad[a[0]["id"]] = (0, steps)
            for i, p in enumerate(m): lad[p["id"]] = (i + 1, steps)
            if b: lad[b[0]["id"]] = (steps, steps)
            out[(slot, k)] = lad
    return out

def price_of(p, k, role):
    if role == "S": return 0
    if p["id"] in FIXED_PRICE: return FIXED_PRICE[p["id"]]
    if k == 1: return {"Blade": 120, "Engine": 300, "Gear": 220}[p["slot"]] if role == "A" else 650
    bm = P["BandPriceMult"].get(k, 1.0)
    if role == "A": return P["PA"] * stage_cost(k) * bm
    if role == "B": return P["BPriceShare"].get(k, P["PB"]) * next_stage_cost(k) * bm
    return P["PC"] * next_stage_cost(k + 1)

def build():
    parts = spec.all_parts()
    lads = ladders(parts)
    byid = {p["id"]: p for p in parts}
    out = {}
    for p in parts:
        k, role, slot = p["band"], p["role"], p["slot"]
        prem = role == "B"; legend = role == "C" and k == 7
        if slot == "Body":
            arch = p["archetype"]
            snow = 0.0 if role == "S" else P["BodySnowPerBand"] * k + (P["BodySnowPremium"] if role == "B" else 0.0)
            tr = {"classic": {}, "steady": {"Stability": round(0.1 + 0.01 * k, 2)}, "nimble": {"Turn": round(0.03 + 0.003 * k, 3)},
                  "grip": {"Grip": round(0.02 + 0.003 * k, 3)}, "titan": {"Grip": 0.05, "Stability": 0.25}, "cosmic": {"Grip": 0.06, "Turn": 0.06}}[arch]
            stats = dict({"Snow": round(snow, 3)}, **tr)
            price = 0  # set in the second pass below, from the real built blade prices of the same band
            out[p["id"]] = dict(p, stats=stats, price=price)
            continue
        frac = 0.0
        if role == "M":
            pos, steps = lads[(slot, k)][p["id"]]; frac = pos / steps
        if slot == "Engine":
            sp, pm, acc = ENGINE_ARCH[p["archetype"]]
            pm = pm ** P["ArchSpread"]
            pw = P["E1"] * level(eg2(), k) * pm
            if prem: pw *= P["PremiumPower"]
            if role == "M": pw *= P["PremiumPower"] ** frac * P["MidPower"]
            if legend: pw *= P["LegendC"]
            if role == "S": pw, sp, acc = 1.0, 24, 1.6
            if role == "C" and k == 1: pw, sp, acc = P.get("BalancedPower", 4.5) * pm, 30, 1.5   # rebalance: 3.5 keeps it below the Desert premium engine
            if role == "A" and k == 1: pw = 2.2 * pm
            speed = min(40, sp + 0.45 * (k - 1) + (2 if prem else (2 * frac if role == "M" else 0)) + (3 if legend else 0))
            stats = {"Speed": round(speed, 1), "Power": round(pw, 3 if pw < 10 else 1) if pw < 1e4 else nice(pw), "AccelTime": acc}
        elif slot == "Blade":
            so, ha = BLADE_ARCH[p["archetype"]]
            pb_ = P["PremiumBlade"] or P["PremiumPower"] ** 0.5
            lv = level([P["BG2"]] * 13, k) * (pb_ if prem else 1) * (1.6 if legend else 1)
            if role == "M": lv *= pb_ ** frac * P["MidPower"] ** 0.5
            w = round(p["visualWidth"] - 0.5, 1)
            if role == "S": so, ha, lv, w = 1.0, 1.0, 1.0, 7.0
            if p["id"] == "blade_wide": w = 12.0
            stats = {"Width": w, "Soft": round(so * lv, 2), "Hard": round(ha * lv, 2)}
        else:
            sm, tr, tu, pv, st, pm = GEAR_ARCH[p["archetype"]]
            pm = pm ** P["ArchSpread"]
            lv = level([P["GG2"]] * 13, k) * (P["PremiumGear"] if prem else 1) * ((P["PremiumGear"] * 1.15 if P.get("LegendGearFix") else 1.15) if legend else 1)
            if role == "M": lv *= P["PremiumGear"] ** frac
            if role == "S": sm, tr, tu, pv, st, pm, lv = 1.0, 0.55, 1.0, 0.15, 1.0, 1.0, 1.0
            if p["id"] == "gear_tracks": sm, tr, tu, pv, st, pm, lv = 0.85, 0.95, 0.9, 0.75, 1.7, 1.15, 1.0
            stats = {"SpeedMult": sm, "Traction": tr, "Turn": tu, "Pivot": pv, "Stability": st, "PowerMult": round(pm * lv, 3)}
        if role == "M":
            lad = lads[(slot, k)]
            a_id = next(i for i, (pos, s) in lad.items() if pos == 0)
            b_id = next(i for i, (pos, s) in lad.items() if pos == s)
            pa, pb = price_of(byid[a_id], k, "A"), price_of(byid[b_id], k, "B")
            f = min(0.95, frac ** (1.0 / P["MidPriceSkew"]))
            price = nice(pa * (pb / pa) ** f)
        else:
            price = price_of(p, k, role)
            price = nice(price) if price >= 100 else price
        out[p["id"]] = dict(p, stats=stats, price=price)
    # bodies: a share of the same band's practical (A) or premium (B) blade price; band 1 practical body is a fixed early price
    for pid, p in out.items():
        if p["slot"] != "Body" or p["role"] == "S": continue
        ref = [q["price"] for q in out.values() if q["slot"] == "Blade" and q["band"] == p["band"] and q["role"] == p["role"]]
        if p["band"] == 1 and p["role"] == "A": p["price"] = P["BodyPrice1"]
        elif ref: p["price"] = nice((P["BodyPriceB"] if p["role"] == "B" else P["BodyPrice"]) * min(ref))
    if P.get("BodySmooth"):
        # RESCALE 2026-10-06: one body per world would jump with the early gates (x80-x90); bodies are a small Snow bonus, so their
        # prices are spaced evenly (geometric) from the first to the last body in band order instead
        bodies = sorted((p for p in out.values() if p["slot"] == "Body" and p["role"] != "S"), key=lambda p: (p["band"], p["role"]))
        lo, hi = bodies[0]["price"], bodies[-1]["price"]
        for i, p in enumerate(bodies):
            p["price"] = nice(lo * (hi / lo) ** (i / max(1, len(bodies) - 1)))
    return out

if __name__ == "__main__":
    c = build()
    for slot in ("Blade", "Engine", "Gear", "Body"):
        for pid, p in sorted(((i, q) for i, q in c.items() if q["slot"] == slot), key=lambda kv: (kv[1]["band"], kv[1]["price"])):
            print("%-6s %2d %s %-24s %10.3g %s" % (slot, p["band"], p["role"], p["name"], p["price"], p["stats"]))
