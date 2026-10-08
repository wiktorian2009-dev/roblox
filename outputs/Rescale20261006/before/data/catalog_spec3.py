# catalog_spec3.py - the 150-part catalog = catalog_spec2 (135 parts: 45 blades / 45 engines / 45 running gear, unchanged)
# + 15 BODY parts (2026-10-05, task 7). Body is the fourth slot: a replaceable visual shell on the invariant chassis frame
# (root, seat and attach points stay the same), with a small bounded PvE effect: Snow efficiency (+% Snow from plow clearing)
# and one modest handling trait (Grip = +traction, Turn = +turn, Steady = +stability). One body per progression band plus the free
# starter; band 7 (Absolute Zero) and band 14 (Cosmic) bodies are the premium (role B) showpieces of their world.
import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import catalog_spec2 as base2
BANDS = base2.BANDS

# (id, name, band, role, rarity, model, trait archetype, short visual brief)
BODIES = [
    ("body_starter", "Classic Plow Cab", 1, "S", "Starter", "BodyStarter", "classic", "the original red plow cab: open seat, roll bar, hood with lights, rear engine deck"),
    ("body_frosthauler", "Frost Hauler", 1, "A", "Common", "BodyFrostHauler", "steady", "boxy snow-white pickup tub with blue stripes, a tall roll cage and a light bar"),
    ("body_dunerunner", "Dune Runner", 2, "A", "Common", "BodyDuneRunner", "nimble", "sand-coloured buggy with a tubular frame, roof rack and a spare tire"),
    ("body_gravehauler", "Grave Hauler", 3, "A", "Uncommon", "BodyGraveHauler", "grip", "dark purple hearse-style cab with a lantern, bone trim and arched windows"),
    ("body_geodecrawler", "Geode Crawler", 4, "A", "Uncommon", "BodyGeodeCrawler", "steady", "slate rock-armoured hull with cyan crystal spikes on the fenders"),
    ("body_arcadekart", "Arcade Kart", 5, "A", "Rare", "BodyArcadeKart", "nimble", "blocky pixel kart body with neon pink and cyan trims and a scoreboard spoiler"),
    ("body_safari", "Safari Cruiser", 6, "A", "Rare", "BodySafari", "grip", "green safari jeep with bamboo bars, a canvas roof and a roof crate"),
    ("body_polartitan", "Polar Titan", 7, "B", "Epic", "BodyPolarTitan", "titan", "heavy armoured ice truck with a big ram bumper, frost plating and glowing cyan seams"),
    ("body_pagoda", "Pagoda Wagon", 8, "A", "Rare", "BodyPagoda", "nimble", "red lacquer wagon with a curved pagoda roof over the seat and paper lanterns"),
    ("body_sweettruck", "Sweet Truck", 9, "A", "Epic", "BodySweetTruck", "grip", "candy-striped truck with cupcake fender caps and a lollipop antenna"),
    ("body_reefdiver", "Reef Diver", 10, "A", "Epic", "BodyReefDiver", "steady", "rounded teal submarine hull with brass portholes, fins and a periscope"),
    ("body_toytruck", "Toy Truck", 11, "A", "Epic", "BodyToyTruck", "nimble", "chunky primary-colour toy truck with building-block studs and a wind-up key"),
    ("body_brasscarriage", "Brass Carriage", 12, "A", "Epic", "BodyBrassCarriage", "grip", "steampunk brass-and-wood carriage with pipes, gauges and a little chimney"),
    ("body_skycruiser", "Sky Cruiser", 13, "A", "Epic", "BodySkyCruiser", "nimble", "streamlined white and sky-blue cruiser with cloud puffs and small wings"),
    ("body_starcruiser", "Star Cruiser", 14, "B", "Legendary", "BodyStarCruiser", "cosmic", "sleek navy star cruiser with star-shaped neon trims, tail fins and a glowing halo ring"),
]

def all_parts():
    out = base2.all_parts()
    for (pid, name, band, role, rarity, model, arch, brief) in BODIES:
        b = BANDS[band - 1]
        out.append({"id": pid, "name": name, "slot": "Body", "band": band, "stage": b[1], "theme": b[2], "palette": b[3],
                    "role": role, "rarity": rarity, "model": model, "archetype": arch, "visualWidth": None, "brief": brief, "body": True})
    return out

if __name__ == "__main__":
    from collections import Counter
    parts = all_parts()
    c = Counter(p["slot"] for p in parts)
    assert c == {"Blade": 45, "Engine": 45, "Gear": 45, "Body": 15}, c
    assert len({p["id"] for p in parts}) == 150 and len({p["model"] for p in parts}) == 150
    print("ok", c, sum(c.values()))
