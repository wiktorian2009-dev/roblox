# make_gallery.py - builds gallery/index.html (renders + catalog table + balance results). Open the HTML file in a browser.
import json, os, html
HERE = os.path.dirname(os.path.abspath(__file__))
R = os.path.join(HERE, "..")
cat = json.load(open(os.path.join(R, "data", "catalog_final.json"), encoding="utf-8"))
ev = json.load(open(os.path.join(R, "sim", "evaluation_efficient_casual_noRewards_unlucky_lucky_rebirth.json"), encoding="utf-8"))
pm = json.load(open(os.path.join(R, "parts", "manifest.json"), encoding="utf-8"))
tri = {m["model"]: m.get("tris") for m in pm["models"]}
EGGS = ["SnowyEgg", "DesertEgg", "CursedEgg", "CrystalEgg", "RetroEgg", "JungleEgg", "AbsoluteZeroEgg", "BlossomEgg", "CandyEgg", "PearlEgg", "ToyCapsuleEgg", "GearEgg", "CloudEgg", "StarEgg"]
def img(p, cap, w="100%"):
    return '<figure><img loading="lazy" src="%s" style="width:%s"><figcaption>%s</figcaption></figure>' % (p, w, html.escape(cap))
def fmt(x):
    for s, v in (("Qi", 1e18), ("Qa", 1e15), ("T", 1e12), ("B", 1e9), ("M", 1e6), ("K", 1e3)):
        if x >= v * 1000 and s == "Qi": return "%.3g Sx" % (x / 1e21) if x >= 1e21 else "%.3g Qi" % (x / 1e18)
        if x >= v: return "%.3g %s" % (x / v, s)
    return "%g" % x
rows = []
for pid, p in cat.items():
    st = ", ".join("%s %s" % (k, v) for k, v in p["stats"].items())
    rows.append("<tr><td>%s</td><td>%s</td><td>%s</td><td>%d %s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>" % (
        pid, html.escape(p["name"]), p["slot"], p["band"], html.escape(p["theme"]), p["rarity"], fmt(p["price"]), st, tri.get(p["model"], "")))
bal = []
for beh, r in ev.items():
    w1, w2 = r.get("world1_minutes"), r.get("world2_minutes")
    bal.append("<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>" % (beh,
        w1 and ("%d / %d / %d" % (w1["p10"], w1["median"], w1["p90"])), w2 and ("%d / %d / %d" % (w2["p10"], w2["median"], w2["p90"])) or "-",
        r["partsBoughtWorld1"]["median"], r.get("minutesBetweenMeaningfulUpgrades_W1", {}).get("median"), r["firstPartPurchaseMinute"]["median"]))
doc = """<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Snowplow Expansion Gallery</title>
<style>body{font-family:system-ui,sans-serif;background:#eef3fb;color:#1b2a44;margin:0;padding:16px}h1,h2{margin:.6em 0 .3em}
figure{margin:8px 0}img{border-radius:10px;box-shadow:0 2px 8px #0002;background:#fff}figcaption{font-size:13px;color:#456}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(420px,1fr));gap:10px}table{border-collapse:collapse;font-size:12px;background:#fff}
td,th{border:1px solid #cdd8ea;padding:3px 6px;text-align:left}th{background:#dbe7fb}.wrap{overflow-x:auto}</style></head><body>
<h1>Snowplow expansion - 90 parts, 70 rebuilt pets (2026-10-05)</h1>
<p>Blender renders (EEVEE) of the uploaded models. Roblox-side checks are in STATUS.md (Studio captures were unavailable during this session).</p>
<h2>Parts</h2>%s%s%s<div class="grid">%s%s%s</div>%s
<div class="grid">%s%s%s%s</div>
<h2>Pets</h2>%s%s%s<div class="grid">%s</div>
<h2>Balance (simulated, minutes: P10 / median / P90)</h2><div class="wrap"><table><tr><th>behaviour</th><th>World 1</th><th>World 2</th><th>parts bought W1</th><th>median min between meaningful upgrades</th><th>first part (min)</th></tr>%s</table></div>
<h2>Catalog</h2><div class="wrap"><table><tr><th>id</th><th>name</th><th>slot</th><th>band</th><th>rarity</th><th>price</th><th>stats</th><th>tris</th></tr>%s</table></div>
</body></html>""" % (
    img("../parts/renders/Blades.png", "30 blades"), img("../parts/renders/Engines.png", "30 engines (3/4 rear view)"), img("../parts/renders/Gears.png", "30 running-gear assemblies"),
    img("../parts/renders/Blades_600.png", "blades at thumbnail scale"), img("../parts/renders/Engines_600.png", "engines at thumbnail scale"), img("../parts/renders/Gears_600.png", "gears at thumbnail scale"),
    img("../parts/renders/Vehicles.png", "8 representative complete vehicles (front and rear)"),
    img("../parts/renders/Fit_side.png", "fit check side"), img("../parts/renders/Fit_top.png", "fit check top"), img("../parts/renders/Fit_front.png", "fit check front"), img("../parts/renders/Fit_rear.png", "fit check rear"),
    img("../pets/renders/sheet_all.png", "all 70 rebuilt pets"), img("../pets/renders/sheet_all_gold.png", "all 70 Golden variants (runtime recolour rule)"), img("../pets/renders/sheet_small96.png", "pets at inventory scale (~96 px)"),
    "".join(img("../pets/renders/sheet_%s.png" % e, e) + img("../pets/renders/sheet_%s_gold.png" % e, e + " golden") for e in EGGS),
    "".join(bal), "".join(rows))
open(os.path.join(HERE, "index.html"), "w", encoding="utf-8").write(doc)
print("ok")

