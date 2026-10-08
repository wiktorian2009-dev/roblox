# catalog_spec2.py - the 135-part catalog = the 90 existing parts (catalog_spec.py, ids and models unchanged) + 45 new parts.
# New parts have role "M" (mid-band practical step): they sit between a band's practical A part and its premium B part, placed
# where the simulation measured long stretches without a meaningful purchase (rebalance 2026-10-05). Per slot: Cursed 1,
# Crystal 2, Retro 1, Jungle 1, Absolute Zero 2, Sakura 1, Candy 2, Atlantis 1, Toybox 1, Clockwork 2, Cloud 1.
import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import catalog_spec as base

BANDS = base.BANDS

# (id, name, band, role, rarity, model, archetype, visual width (blades only), short visual brief)
NEW_BLADES = [
    ("blade_bonechill", "Bonechill Scoop", 3, "M", "Uncommon", "BladeBonechill", "scoop", 10.0, "curved violet scoop with a ribcage of bone ribs on the face and a wispy green lip"),
    ("blade_geodeshovel", "Geode Shovelhead", 4, "M", "Uncommon", "BladeGeodeShovel", "segmented", 10.0, "slate shovel-head blade split into geode halves showing cyan crystal interiors"),
    ("blade_amethyst", "Amethyst Wedge", 4, "M", "Rare", "BladeAmethyst", "vshape", 9.5, "compact V-wedge of stacked purple amethyst slabs with a silver spine"),
    ("blade_joystick", "Joystick Sweeper", 5, "M", "Rare", "BladeJoystick", "pixel", 11.5, "wide pixel sweeper with a row of chunky arcade buttons and two joystick end posts"),
    ("blade_canopy", "Canopy Scoop", 6, "M", "Rare", "BladeCanopy", "scoop", 11.5, "broad leaf-shaped scoop of overlapping green fronds on a bamboo frame"),
    ("blade_frostbite", "Frostbite Cleaver", 7, "M", "Rare", "BladeFrostbite", "icebreaker", 9.0, "narrow frosted icebreaker with icicle teeth hanging from the lower edge"),
    ("blade_polar", "Polar Sweeper", 7, "M", "Epic", "BladePolar", "sweeper", 12.5, "wide white sweeper with blue frost stripes and snowflake rivets"),
    ("blade_lotus", "Lotus Wedge", 8, "M", "Epic", "BladeLotus", "vshape", 10.0, "V-wedge shaped like an opening lotus flower, pink petals on a dark lacquer frame"),
    ("blade_gumdrop", "Gumdrop Sweeper", 9, "M", "Rare", "BladeGumdrop", "sweeper", 12.0, "wide wafer sweeper topped with a row of colourful gumdrops"),
    ("blade_taffy", "Taffy Breaker", 9, "M", "Epic", "BladeTaffy", "toothed", 9.5, "toothed blade of twisted pink-and-white taffy ropes"),
    ("blade_reef", "Reef Splitter", 10, "M", "Epic", "BladeReef", "vshape", 10.0, "teal V-splitter with coral fins and a pearl-studded keel"),
    ("blade_crayon", "Crayon Scraper", 11, "M", "Epic", "BladeCrayon", "straight", 10.5, "straight scraper built from giant crayons laid side by side, pointed tips forward"),
    ("blade_piston", "Piston Scoop", 12, "M", "Rare", "BladePiston", "scoop", 11.5, "brass scoop pushed by two visible pistons with copper rivet bands"),
    ("blade_sprocket", "Sprocket Breaker", 12, "M", "Epic", "BladeSprocket", "mechanical", 10.0, "mechanical breaker with a spinning sprocket wheel set into the cutting edge"),
    ("blade_rainbow", "Rainbow Sweeper", 13, "M", "Epic", "BladeRainbow", "sweeper", 13.0, "wide arched sweeper with rainbow bands and fluffy cloud end caps"),
]
NEW_ENGINES = [
    ("engine_cauldron", "Cauldron Burner", 3, "M", "Uncommon", "EngineCauldron", "industrial", None, "bubbling witch cauldron engine with green glow and twin bone pipes"),
    ("engine_shardspinner", "Shard Spinner", 4, "M", "Uncommon", "EngineShardSpinner", "turbine", None, "turbine with a spinning ring of cyan crystal shards"),
    ("engine_quartzpiston", "Quartz Piston", 4, "M", "Rare", "EngineQuartzPiston", "compact", None, "compact block with three clear quartz piston columns"),
    ("engine_cartridge", "Cartridge Cruncher", 5, "M", "Rare", "EngineCartridge", "twin", None, "twin engine shaped like stacked game cartridges with pixel vents"),
    ("engine_totem", "Totem Torque", 6, "M", "Rare", "EngineTotem", "industrial", None, "stacked totem-pole engine with carved faces and a leafy crown exhaust"),
    ("engine_frostpiston", "Frost Piston", 7, "M", "Rare", "EngineFrostPiston", "compact", None, "compact frosted piston engine with ice-blue cooling fins"),
    ("engine_glacierv6", "Glacier V6", 7, "M", "Epic", "EngineGlacierV6", "twin", None, "V6 block carved from glacier ice with six frosty exhaust stacks"),
    ("engine_bonsai", "Bonsai Drive", 8, "M", "Epic", "EngineBonsai", "compact", None, "compact drive with a tiny bonsai tree growing from a lacquer housing"),
    ("engine_taffytwister", "Taffy Twister", 9, "M", "Rare", "EngineTaffyTwister", "turbine", None, "turbine with a twisting taffy-pull rotor and candy-stripe cowl"),
    ("engine_cocoa", "Cocoa Cruiser", 9, "M", "Epic", "EngineCocoa", "industrial", None, "chocolate-bar engine block with a steaming cocoa-mug stack"),
    ("engine_pearldiver", "Pearl Diver", 10, "M", "Epic", "EnginePearlDiver", "twin", None, "twin engine with clam-shell cylinder heads holding glowing pearls"),
    ("engine_toyrocket", "Rocket Toy Motor", 11, "M", "Epic", "EngineToyRocket", "turbine", None, "toy rocket motor with fins, polka dots and a big nozzle"),
    ("engine_escapement", "Escapement Drive", 12, "M", "Rare", "EngineEscapement", "clockwork", None, "open clockwork drive with a swinging escapement wheel and balance spring"),
    ("engine_steamregulator", "Steam Regulator", 12, "M", "Epic", "EngineSteamRegulator", "industrial", None, "brass steam engine with a spinning fly-ball governor and pressure gauges"),
    ("engine_galerotor", "Gale Rotor", 13, "M", "Epic", "EngineGaleRotor", "turbine", None, "wind rotor engine with three swept white blades and a gold hub"),
]
NEW_GEARS = [
    ("gear_graverollers", "Grave Rollers", 3, "M", "Uncommon", "GearGraveRollers", "bigtires", None, "chunky dark tires with tombstone-shaped tread blocks"),
    ("gear_shardtreads", "Shard Treads", 4, "M", "Uncommon", "GearShardTreads", "tracks", None, "slate tracks with crystal-shard cleats"),
    ("gear_prismskids", "Prism Skids", 4, "M", "Rare", "GearPrismSkids", "skis", None, "four faceted prism skis on slate struts"),
    ("gear_joypad", "Joypad Treads", 5, "M", "Rare", "GearJoypad", "compacttracks", None, "compact track pods shaped like game controllers with d-pad hubs"),
    ("gear_rootcrawler", "Root Crawlers", 6, "M", "Rare", "GearRootCrawler", "tracks", None, "tracks woven from tree roots with leafy guards"),
    ("gear_frostbite", "Frostbite Studs", 7, "M", "Rare", "GearFrostbite", "studded", None, "ice-blue tires studded with frost crystals"),
    ("gear_aurora", "Aurora Glide", 7, "M", "Epic", "GearAurora", "hover", None, "hover discs trailing green-violet aurora ribbons"),
    ("gear_koifin", "Koi Fin Rollers", 8, "M", "Epic", "GearKoiFin", "flotation", None, "balloon rollers painted as koi with fin-shaped guards"),
    ("gear_lollipop", "Lollipop Wheels", 9, "M", "Rare", "GearLollipop", "smalltires", None, "swirly lollipop discs as wheels with stick axles"),
    ("gear_licorice", "Licorice Tracks", 9, "M", "Epic", "GearLicorice", "compacttracks", None, "compact tracks made of braided licorice ropes"),
    ("gear_bubblehover", "Bubble Hover", 10, "M", "Epic", "GearBubbleHover", "hover", None, "hover pods inside glossy soap bubbles with shell frames"),
    ("gear_yoyo", "Yo-yo Wheels", 11, "M", "Epic", "GearYoyo", "rings", None, "giant yo-yo wheels with string-wound hubs"),
    ("gear_ratchet", "Ratchet Treads", 12, "M", "Rare", "GearRatchet", "tracks", None, "brass tracks with ratchet-tooth cleats and copper guards"),
    ("gear_pendulum", "Pendulum Skis", 12, "M", "Epic", "GearPendulum", "skis", None, "brass skis hanging from pendulum struts"),
    ("gear_nimbus", "Nimbus Treads", 13, "M", "Epic", "GearNimbus", "widetracks", None, "wide fluffy cloud tracks with golden road wheels"),
]

def all_parts():
    out = base.all_parts()
    for slot, rows in (("Blade", NEW_BLADES), ("Engine", NEW_ENGINES), ("Gear", NEW_GEARS)):
        for (pid, name, band, role, rarity, model, arch, width, brief) in rows:
            b = BANDS[band - 1]
            out.append({"id": pid, "name": name, "slot": slot, "band": band, "stage": b[1], "theme": b[2], "palette": b[3],
                        "role": role, "rarity": rarity, "model": model, "archetype": arch, "visualWidth": width, "brief": brief, "new": True})
    return out

if __name__ == "__main__":
    from collections import Counter
    parts = all_parts()
    c = Counter(p["slot"] for p in parts)
    assert c == {"Blade": 45, "Engine": 45, "Gear": 45}, c
    assert len({p["id"] for p in parts}) == 135 and len({p["model"] for p in parts}) == 135
    json.dump(parts, open(os.path.join(HERE, "catalog_visual2.json"), "w"), indent=1)
    print("ok", c, Counter(p["band"] for p in parts if p.get("new")))
