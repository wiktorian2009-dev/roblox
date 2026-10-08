# catalog_spec.py - canonical 90-part snowplow catalog (identity + visuals). Stats are added by sim/catalog_stats.py.
# Bands = progression themes in stage order. Each slot has 30 parts: band 1 and band 7 have 3, every other band 2.
# Role per band: A = practical (cheap, frequent), B = premium (stronger, pricier, rarer), C = legendary showcase.
import json, os

BANDS = [  # band, stage id, theme name, palette (main, second, accent, dark)
    (1, "Starter", "Snowy Starter", ["F4F8FF", "9FD8FF", "E2483D", "4A5568"]),
    (2, "Desert", "Desert", ["E8C27A", "2EC4B6", "F2B33D", "8A4B2A"]),
    (3, "Cursed", "Cursed", ["3B2A55", "8E4DE0", "EDE3C8", "7CFFB2"]),
    (4, "Crystal", "Crystal Caves", ["57D8FF", "E07BFF", "F4FBFF", "3D4766"]),
    (5, "Retro", "Retro World", ["FF4FB6", "3FF0FF", "FFE14F", "1E1E2E"]),
    (6, "Jungle", "Jungle", ["3FBF4F", "8A5A33", "FF9A2E", "2E5E2A"]),
    (7, "AbsoluteZero", "Absolute Zero", ["D8F3FF", "2E6BD8", "C9D6E6", "B79CFF"]),
    (8, "Sakura", "Sakura Garden", ["FFA7C8", "FFF6FA", "D6363C", "5A3A2E"]),
    (9, "Candy", "Candy Kingdom", ["FF6FA8", "7FE8C3", "FFE36E", "6B3E2E"]),
    (10, "Atlantis", "Sunken Atlantis", ["1FB7A6", "155E8C", "FF7A5C", "FFF4E6"]),
    (11, "Toybox", "Giant Toybox", ["E8443A", "3A7BE8", "FFD23A", "4CC35A"]),
    (12, "Clockwork", "Clockwork City", ["D9A441", "C46A3A", "3FBFB4", "3B3F4A"]),
    (13, "Cloud", "Cloud Kingdom", ["F7F9FF", "8FD0FF", "FFE08A", "FFF06E"]),
    (14, "Cosmic", "Cosmic Sanctuary", ["3C2E8F", "9B6BFF", "FFF6C8", "6FE7FF"]),
]

# (id, name, band, role, rarity, model, archetype, visual width (blades only), short visual brief)
BLADES = [
    ("blade_basic", "Basic Blade", 1, "S", "Starter", "BladeBasic", "straight", 7.5, "plain red-and-steel straight utility blade, bolted ribs"),
    ("blade_wide", "Wide Clearing Blade", 1, "A", "Common", "BladeWide", "sweeper", 12.5, "very wide low curved sweeper with yellow hazard stripes and end skids"),
    ("blade_frost_scoop", "Frosty Scoop", 1, "C", "Uncommon", "BladeFrostScoop", "scoop", 9.0, "deep curved scoop, icy blue with white snow-cap rim and side wings"),
    ("blade_ice", "Reinforced Icebreaker", 2, "B", "Rare", "BladeIce", "icebreaker", 9.0, "thick armoured plate with riveted rails and a hardened lower edge"),
    ("blade_dune", "Dune Sweeper", 2, "A", "Common", "BladeDune", "sweeper", 11.5, "broad sand-coloured sweeper with turquoise trim, rolled top lip, sun emblem"),
    ("blade_grave", "Grave Digger", 3, "A", "Uncommon", "BladeGrave", "toothed", 9.5, "bone-white toothed blade with tombstone-shaped teeth on a violet frame"),
    ("blade_hex", "Hex Breaker", 3, "B", "Rare", "BladeHex", "vshape", 10.0, "V-shaped dark violet wedge with glowing green rune lines and spiky tips"),
    ("blade_quartz", "Quartz Edge", 4, "A", "Uncommon", "BladeQuartz", "segmented", 10.5, "segmented blade made of faceted cyan crystal panels on a slate frame"),
    ("blade_prism", "Prism Cleaver", 4, "B", "Rare", "BladePrism", "crystal", 9.0, "sharp crystal V-cleaver with magenta core gems and prism fins"),
    ("blade_pixel", "Pixel Pusher", 5, "A", "Uncommon", "BladePixel", "pixel", 11.5, "stair-stepped blocky voxel blade in hot pink and cyan pixels"),
    ("blade_arcade", "Arcade Plow", 5, "B", "Epic", "BladeArcade", "segmented", 10.0, "arcade-cabinet styled segmented blade with yellow joystick knobs and neon strips"),
    ("blade_vine", "Vine Sweeper", 6, "A", "Uncommon", "BladeVine", "sweeper", 12.5, "wide curved wooden sweeper wrapped in green vines and leaves"),
    ("blade_tusk", "Tusk Breaker", 6, "B", "Epic", "BladeTusk", "toothed", 9.0, "carved tiki wood blade with big ivory tusk teeth and orange paint"),
    ("blade_glacier", "Glacier Plow", 7, "A", "Uncommon", "BladeGlacier", "scoop", 11.0, "pale ice scoop with frosted ridges and silver rim"),
    ("blade_zero", "Absolute Edge", 7, "B", "Epic", "BladeZero", "icebreaker", 9.0, "deep-blue reinforced icebreaker with silver ribs and a frost-white cutting edge"),
    ("blade_singularity", "Zero Point Blade", 7, "C", "Legendary", "BladeSingularity", "vshape", 11.0, "elegant swept V-blade of lilac ice with a glowing cold core ring"),
    ("blade_petal", "Petal Sweeper", 8, "A", "Rare", "BladePetal", "sweeper", 13.0, "wide pink lacquer sweeper shaped like overlapping blossom petals"),
    ("blade_katana", "Katana Blade", 8, "B", "Epic", "BladeKatana", "straight", 9.5, "sleek straight blade with a curved katana edge, red lacquer and gold guard"),
    ("blade_lollipop", "Lollipop Scoop", 9, "A", "Rare", "BladeLollipop", "scoop", 11.0, "round-edged candy scoop with lollipop swirl discs on each end"),
    ("blade_canecrusher", "Candy Cane Crusher", 9, "B", "Epic", "BladeCaneCrusher", "toothed", 10.0, "toothed blade made of striped candy-cane hooks on a chocolate bar frame"),
    ("blade_coral", "Coral Scoop", 10, "A", "Rare", "BladeCoral", "scoop", 11.5, "teal shell-shaped scoop with coral branches and pearl studs"),
    ("blade_trident", "Trident Breaker", 10, "B", "Legendary", "BladeTrident", "vshape", 9.5, "gold trident-pronged V-breaker with sea-glass panels"),
    ("blade_brick", "Building Block Blade", 11, "A", "Rare", "BladeBrick", "segmented", 12.0, "segmented blade of stacked toy bricks with studs in primary colours"),
    ("blade_bulldozer", "Toy Bulldozer", 11, "B", "Legendary", "BladeBulldozer", "straight", 10.5, "chunky yellow toy-bulldozer blade with big bolts and a red trim"),
    ("blade_cog", "Cog Sweeper", 12, "A", "Rare", "BladeCog", "sweeper", 12.5, "brass sweeper with half-cog end plates and riveted copper bands"),
    ("blade_gearbreaker", "Gearbreaker", 12, "B", "Legendary", "BladeGearbreaker", "mechanical", 10.0, "mechanical blade with a row of interlocking teal-and-brass gears as teeth"),
    ("blade_cumulus", "Cumulus Sweeper", 13, "A", "Rare", "BladeCumulus", "sweeper", 13.5, "puffy cloud-shaped wide sweeper, white with gold trim"),
    ("blade_thunder", "Thunder Wedge", 13, "B", "Legendary", "BladeThunder", "vshape", 10.0, "V-wedge with lightning-bolt fins and glowing yellow seams"),
    ("blade_comet", "Comet Scoop", 14, "A", "Epic", "BladeComet", "scoop", 12.0, "indigo scoop with a comet-tail sweep and star studs"),
    ("blade_galaxy", "Galaxy Breaker", 14, "B", "Legendary", "BladeGalaxy", "cosmic", 11.0, "cosmic breaker with a swirling galaxy disc, orbit ring and violet crystal teeth"),
]
ENGINES = [
    ("engine_starter", "Starter Engine", 1, "S", "Starter", "EngineStarter", "compact", None, "small red compact motor with one exhaust pipe"),
    ("engine_snowball", "Snowball Motor", 1, "A", "Common", "EngineSnowball", "compact", None, "round snowball-shaped motor with a blue cap and stubby pipe"),
    ("engine_balanced", "Balanced Engine", 1, "C", "Uncommon", "EngineBalanced", "twin", None, "twin-cylinder engine with two chrome exhausts and a blue tank"),
    ("engine_sandrunner", "Sand Runner", 2, "A", "Common", "EngineSandRunner", "turbine", None, "sand-coloured air-cooled engine with turquoise intake fan"),
    ("engine_power", "Powerful Engine", 2, "B", "Rare", "EnginePower", "industrial", None, "reinforced industrial block with tall twin stacks and hazard plates"),
    ("engine_lantern", "Lantern Motor", 3, "A", "Uncommon", "EngineLantern", "compact", None, "pumpkin-lantern motor with glowing green eyes and crooked chimney"),
    ("engine_phantom", "Phantom V-Twin", 3, "B", "Rare", "EnginePhantom", "twin", None, "dark violet V-twin with bone exhaust horns and ghostly green glow"),
    ("engine_geode", "Geode Core", 4, "A", "Uncommon", "EngineGeode", "crystal", None, "cracked geode housing with a cyan crystal core poking out"),
    ("engine_reactor", "Crystal Reactor", 4, "B", "Rare", "EngineReactor", "crystal", None, "cylindrical reactor with magenta crystal rods in a slate cage"),
    ("engine_8bit", "8-Bit Engine", 5, "A", "Uncommon", "Engine8Bit", "pixel", None, "blocky voxel engine with stepped pixel pipes in pink and cyan"),
    ("engine_arcade", "Arcade Turbo", 5, "B", "Epic", "EngineArcade", "turbine", None, "retro turbo with a big spinning fan face and neon trim"),
    ("engine_tiki", "Tiki Thumper", 6, "A", "Uncommon", "EngineTiki", "industrial", None, "carved tiki-face engine block with bamboo exhausts"),
    ("engine_jturbine", "Jungle Turbine", 6, "B", "Epic", "EngineJungleTurbine", "turbine", None, "leafy turbine with an orange intake and vine-wrapped casing"),
    ("engine_cryo", "Cryo Compressor", 7, "A", "Uncommon", "EngineCryo", "industrial", None, "frosted compressor with ice-blue coils and silver tanks"),
    ("engine_polar", "Polar Turbine", 7, "B", "Epic", "EnginePolar", "turbine", None, "sleek white-and-blue jet turbine with frost vents"),
    ("engine_zerocore", "Absolute Zero Core", 7, "C", "Legendary", "EngineZeroCore", "core", None, "floating lilac cold-core sphere held by silver arcs"),
    ("engine_lanterntwin", "Lantern Twin", 8, "A", "Rare", "EngineLanternTwin", "twin", None, "twin cylinders shaped like paper lanterns on a dark wood base"),
    ("engine_blossom", "Blossom Turbine", 8, "B", "Epic", "EngineBlossom", "turbine", None, "turbine with a pink blossom-petal fan and gold hub"),
    ("engine_gumdrop", "Gumdrop Motor", 9, "A", "Rare", "EngineGumdrop", "compact", None, "squishy gumdrop domes on a wafer block with a candy-stripe pipe"),
    ("engine_sugarv8", "Sugar Rush V8", 9, "B", "Epic", "EngineSugarV8", "twin", None, "V8 with eight lollipop exhaust stacks and a pink blower"),
    ("engine_bubble", "Bubble Pump", 10, "A", "Rare", "EngineBubble", "compact", None, "brass diving-helmet pump with glass porthole and bubble pipe"),
    ("engine_leviathan", "Leviathan Turbine", 10, "B", "Legendary", "EngineLeviathan", "turbine", None, "teal turbine with fin-shaped vanes and a coral-red intake"),
    ("engine_windup", "Wind-up Motor", 11, "A", "Rare", "EngineWindup", "clockwork", None, "toy motor with a giant wind-up key on top, primary colours"),
    ("engine_jackbox", "Jack-in-the-Box Engine", 11, "B", "Legendary", "EngineJackbox", "industrial", None, "toy box engine with a spring piston and star decals"),
    ("engine_pocketwatch", "Pocketwatch Engine", 12, "A", "Rare", "EnginePocketwatch", "clockwork", None, "upright brass pocketwatch housing with visible ticking gears"),
    ("engine_grandclock", "Grand Clockwork Core", 12, "B", "Legendary", "EngineGrandClock", "clockwork", None, "tall clock-tower engine with layered teal and brass gears"),
    ("engine_breeze", "Breeze Turbine", 13, "A", "Epic", "EngineBreeze", "turbine", None, "white cloud-puff housing with a sky-blue fan"),
    ("engine_storm", "Storm Engine", 13, "B", "Legendary", "EngineStorm", "core", None, "dark storm-cloud engine with a glowing lightning core"),
    ("engine_stardrive", "Star Drive", 14, "A", "Epic", "EngineStarDrive", "core", None, "indigo star-shaped drive with a glowing cyan nozzle"),
    ("engine_nebula", "Nebula Reactor", 14, "B", "Legendary", "EngineNebula", "core", None, "violet reactor sphere with orbiting rings and a star core"),
]
GEARS = [
    ("gear_wheels", "Snow Wheels", 1, "S", "Starter", "GearWheels", "smalltires", None, "four small black snow tires with red hubs"),
    ("gear_chunky", "Chunky Snow Tires", 1, "A", "Common", "GearChunky", "bigtires", None, "four big chunky knobby tires with white hubs"),
    ("gear_tracks", "Tracked Treads", 1, "C", "Uncommon", "GearTracks", "tracks", None, "two steel caterpillar tracks with road wheels"),
    ("gear_balloon", "Dune Balloon Tires", 2, "A", "Common", "GearBalloon", "flotation", None, "fat sand balloon tires with turquoise rims"),
    ("gear_sandcrawler", "Sandcrawler Tracks", 2, "B", "Rare", "GearSandcrawler", "widetracks", None, "wide flotation tracks with gold sprockets"),
    ("gear_bonewheels", "Spiked Bone Wheels", 3, "A", "Uncommon", "GearBoneWheels", "studded", None, "violet wheels with bone spikes around the tread"),
    ("gear_haunted", "Haunted Treads", 3, "B", "Rare", "GearHaunted", "tracks", None, "dark tracks with ghost-green glowing road wheels"),
    ("gear_crystalstud", "Crystal Studded Tires", 4, "A", "Uncommon", "GearCrystalStud", "studded", None, "slate tires studded with cyan crystal spikes"),
    ("gear_geodetracks", "Geode Tracks", 4, "B", "Rare", "GearGeodeTracks", "compacttracks", None, "short compact track pods with magenta crystal guards"),
    ("gear_pixelwheels", "Pixel Wheels", 5, "A", "Uncommon", "GearPixelWheels", "pixel", None, "octagonal blocky voxel wheels in pink and cyan"),
    ("gear_hoverpods", "Arcade Hover Pods", 5, "B", "Epic", "GearHoverPods", "hover", None, "four disc hover pods with neon underglow rings"),
    ("gear_mudder", "Mudder Tires", 6, "A", "Uncommon", "GearMudder", "bigtires", None, "huge chunky mud tires with wooden hubs"),
    ("gear_vinecrawler", "Vine Crawler Tracks", 6, "B", "Epic", "GearVineCrawler", "widetracks", None, "wide tracks wrapped with vines and leaf guards"),
    ("gear_skis", "Frost Runners", 7, "A", "Uncommon", "GearSkis", "skis", None, "four ice ski runners on silver struts"),
    ("gear_glaciertracks", "Glacier Tracks", 7, "B", "Epic", "GearGlacierTracks", "widetracks", None, "broad ice-blue flotation tracks with frosted guards"),
    ("gear_zerog", "Zero-G Hover Rig", 7, "C", "Legendary", "GearZeroG", "hover", None, "lilac anti-gravity hover rings with silver frames"),
    ("gear_bamboo", "Bamboo Wheels", 8, "A", "Rare", "GearBamboo", "smalltires", None, "bamboo-spoked wheels with pink rims"),
    ("gear_petalglide", "Petal Glide Runners", 8, "B", "Epic", "GearPetalGlide", "skis", None, "curved lacquer runners shaped like petals with gold tips"),
    ("gear_donut", "Donut Tires", 9, "A", "Rare", "GearDonut", "bigtires", None, "frosted donut tires with sprinkles"),
    ("gear_gummytreads", "Gummy Treads", 9, "B", "Epic", "GearGummyTreads", "tracks", None, "translucent-looking gummy-bear coloured tracks"),
    ("gear_shell", "Shell Wheels", 10, "A", "Rare", "GearShell", "studded", None, "spiral seashell wheels with pearl studs"),
    ("gear_paddle", "Paddle Tracks", 10, "B", "Legendary", "GearPaddle", "widetracks", None, "teal tracks with paddle-wheel fins"),
    ("gear_toybrick", "Toy Brick Wheels", 11, "A", "Rare", "GearToyBrick", "smalltires", None, "chunky toy wheels with brick hubs and studs"),
    ("gear_toytank", "Toy Tank Tracks", 11, "B", "Legendary", "GearToyTank", "compacttracks", None, "bright toy-tank tracks with big round road wheels"),
    ("gear_cogwheels", "Cog Wheels", 12, "A", "Rare", "GearCogWheels", "studded", None, "brass cog-tooth wheels with copper hubs"),
    ("gear_brasstracks", "Brass Tracks", 12, "B", "Legendary", "GearBrassTracks", "compacttracks", None, "compact brass track units with teal gear guards"),
    ("gear_cloudpuff", "Cloud Puff Wheels", 13, "A", "Epic", "GearCloudPuff", "flotation", None, "soft cloud-puff tires with gold hubs"),
    ("gear_stormpods", "Storm Hover Pods", 13, "B", "Legendary", "GearStormPods", "hover", None, "storm-cloud hover pods with lightning rings"),
    ("gear_orbit", "Orbit Rings", 14, "A", "Epic", "GearOrbit", "rings", None, "ring wheels like planetary orbits with star spokes"),
    ("gear_meteor", "Meteor Treads", 14, "B", "Legendary", "GearMeteor", "widetracks", None, "dark indigo tracks with glowing meteor-rock road wheels"),
]

def all_parts():
    out = []
    for slot, rows in (("Blade", BLADES), ("Engine", ENGINES), ("Gear", GEARS)):
        for (pid, name, band, role, rarity, model, arch, width, brief) in rows:
            b = BANDS[band - 1]
            out.append({"id": pid, "name": name, "slot": slot, "band": band, "stage": b[1], "theme": b[2], "palette": b[3],
                        "role": role, "rarity": rarity, "model": model, "archetype": arch, "visualWidth": width, "brief": brief})
    return out

if __name__ == "__main__":
    parts = all_parts()
    from collections import Counter
    c = Counter(p["slot"] for p in parts)
    assert c == {"Blade": 30, "Engine": 30, "Gear": 30}, c
    assert len({p["id"] for p in parts}) == 90 and len({p["model"] for p in parts}) == 90
    for keep in ["blade_basic", "blade_wide", "blade_ice", "engine_starter", "engine_balanced", "engine_power", "gear_wheels", "gear_tracks"]:
        assert any(p["id"] == keep for p in parts), keep
    json.dump(parts, open(os.path.join(os.path.dirname(__file__), "catalog_visual.json"), "w"), indent=1)
    print("ok", c, Counter(p["rarity"] for p in parts))
