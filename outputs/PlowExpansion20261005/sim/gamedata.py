# gamedata.py - live production values read from Studio place "money" (94130990350526) on 2026-10-05.
import math
# Upgrades: UpgradeConfig after its runtime price/boost transform (fresh clone require); stages: StageConfig;
# fields: Workspace.SnowFieldZones + ReplicatedStorage.SnowStages attributes; eggs: PetConfig; achievements: ActivityConfig.
TILE = 3

STAGES = [  # id, cost, world
    ("Starter", 0, 1), ("Desert", 2500, 1), ("Cursed", 250000, 1), ("Crystal", 8e6, 1), ("Retro", 2.5e8, 1),
    ("Jungle", 8e9, 1), ("AbsoluteZero", 2.5e11, 1), ("Portal", 1.5e14, 1), ("Sakura", 0, 2), ("Candy", 3e14, 2),
    ("Atlantis", 1e16, 2), ("Toybox", 6e16, 2), ("Clockwork", 3.6e17, 2), ("Cloud", 2.2e18, 2), ("Cosmic", 1.3e19, 2),
]
# stage attributes: TileHP, SnowPerPhase, RegrowSeconds
STAGE_FIELD = {
    "Starter": (2, 2, 8), "Desert": (50, 100, 8), "Cursed": (300, 1200, 6), "Crystal": (2000, 8000, 6),
    "Retro": (12600, 54000, 5), "Jungle": (80000, 320000, 7), "AbsoluteZero": (450000, 2250000, 5),
    "Sakura": (900000, 6000000, 5), "Candy": (2250000, 18000000, 5), "Atlantis": (4500000, 46800000, 5),
    "Toybox": (9000000, 121680000, 5), "Clockwork": (18000000, 316368000, 5), "Cloud": (36000000, 822556800, 5),
    "Cosmic": (72000000, 2138647680, 5),
}
# zone sizes (studs X, Z) per stage
ZONES = {
    "Starter": [(61.82, 127.46), (28, 46)], "Desert": [(61.82, 126.06), (53.94, 92.47)], "Cursed": [(53.82, 173.57), (47.26, 142.85)],
    "Crystal": [(53.94, 132.56), (49.12, 92.47)], "Retro": [(115.14, 73.24), (56.09, 19.10)], "Jungle": [(156.47, 48.79), (154.47, 44.79)],
    "AbsoluteZero": [(90.47, 254.12)], "Sakura": [(147.8, 33), (144.8, 33)], "Candy": [(107.2, 41.4), (105.6, 41.6)],
    "Atlantis": [(170.6, 42.4), (175.9, 45.7)], "Toybox": [(149.8, 45.0), (149.05, 43.4)], "Clockwork": [(84.6, 42.5), (87.9, 42.7)],
    "Cloud": [(108.7, 37.6), (118.5, 47.7)], "Cosmic": [(110, 24), (110, 24)],
}
def zone_tiles(z): return max(1, int(z[0] / TILE + 0.5)) * max(1, int(z[1] / TILE + 0.5))

# NEW explicit field toughness (0 = soft powder, 1 = hard ice) -> blade efficiency = Soft + (Hard - Soft) * toughness
TOUGH = {"Starter": 0.05, "Desert": 0.2, "Cursed": 0.55, "Crystal": 0.9, "Retro": 0.75, "Jungle": 0.3, "AbsoluteZero": 0.95,
         "Sakura": 0.15, "Candy": 0.5, "Atlantis": 0.4, "Toybox": 0.65, "Clockwork": 0.85, "Cloud": 0.1, "Cosmic": 0.7}

FIELD_STAGES = [s for s in STAGE_FIELD]  # 14 field stages = bands 1..14
BAND_OF = {s: i + 1 for i, s in enumerate(FIELD_STAGES)}

EGGS = [  # id, cost, stage, [(name, chance%, boost)]
    ("SnowyEgg", 450, "Starter", [("Snow Bunny", 45, .05), ("Penguin", 30, .08), ("Arctic Fox", 15, .12), ("Polar Bear", 8, .2), ("Yeti", 2, .4)]),
    ("DesertEgg", 1500, "Desert", [("Fennec Fox", 45, .1), ("Camel", 30, .15), ("Sand Lizard", 15, .22), ("Scarab", 8, .35), ("Sphinx Cat", 2, .7)]),
    ("CursedEgg", 38000, "Cursed", [("Shadow Bat", 45, .18), ("Ghost", 30, .25), ("Imp", 15, .38), ("Shadow Wolf", 8, .6), ("Void Demon", 2, 1.2)]),
    ("CrystalEgg", 5.8e6, "Crystal", [("Gem Slime", 45, .3), ("Crystal Bunny", 30, .42), ("Prism Bird", 15, .95), ("Crystal Golem", 8, .6), ("Diamond Dragon", 2, 1.8)]),
    ("RetroEgg", 4e8, "Retro", [("Pixel Cat", 45, .5), ("Arcade Bot", 30, .7), ("Neon Frog", 15, 1.0), ("Synth Fox", 8, 1.6), ("Glitch Dragon", 2, 3.0)]),
    ("JungleEgg", 1.4e10, "Jungle", [("Tree Frog", 45, .8), ("Monkey", 30, 1.1), ("Toucan", 15, 1.6), ("Jaguar", 8, 2.6), ("Tiki Guardian", 2, 5.0)]),
    ("AbsoluteZeroEgg", 3e11, "AbsoluteZero", [("Frost Sprite", 45, 1.3), ("Ice Seal", 30, 1.8), ("Snow Owl", 15, 2.6), ("Glacier Mammoth", 8, 4.2), ("Absolute Phoenix", 2, 8.0)]),
    ("BlossomEgg", 1.5e13, "Sakura", [("Koi", 45, 2.0), ("Blossom Bunny", 30, 2.7), ("Red Panda", 15, 3.9), ("Crane", 8, 6.3), ("Blossom Dragon", 2, 12.0)]),
    ("CandyEgg", 3e13, "Candy", [("Gummy Bear", 45, 2.9), ("Marshmallow Bunny", 30, 3.9), ("Cupcake Cat", 15, 5.7), ("Candy Fox", 8, 9.1), ("Sugar Dragon", 2, 17.4)]),
    ("PearlEgg", 1e15, "Atlantis", [("Crab", 45, 4.2), ("Seahorse", 30, 5.7), ("Turtle", 15, 8.2), ("Manta Ray", 8, 13.2), ("Ancient Sea Serpent", 2, 25.2)]),
    ("ToyCapsuleEgg", 6e15, "Toybox", [("Teddy Bear", 45, 6.1), ("Toy Duck", 30, 8.2), ("Wind-up Mouse", 15, 11.9), ("Toy Robot", 8, 19.2), ("Plush Dinosaur", 2, 36.6)]),
    ("GearEgg", 3.6e16, "Clockwork", [("Brass Beetle", 45, 8.9), ("Clockwork Bird", 30, 11.9), ("Steam Pup", 15, 17.3), ("Gear Fox", 8, 27.8), ("Clockwork Dragon", 2, 53.1)]),
    ("CloudEgg", 2.2e17, "Cloud", [("Cloud Lamb", 45, 12.9), ("Cloud Kitten", 30, 17.3), ("Thunder Owl", 15, 25.1), ("Rainbow Pegasus", 8, 40.3), ("Sky Whale", 2, 77.0)]),
    ("StarEgg", 1.3e18, "Cosmic", [("Comet Pup", 45, 18.7), ("Moon Bunny", 30, 25.1), ("Astro Cat", 15, 36.4), ("Nebula Fox", 8, 58.4), ("Galaxy Dragon", 2, 111.7)]),
]
GOLDEN_MULT = 2
PET_SLOTS = 3

# Upgrades (Id, Tree, Q, R, Cost, Effect, Amount, Mul?, Center?)
UPG = """R_Gold3 Rolls -6 4 2300000000 LuckMult 0.35 0 0
S_Gain3 Snow 3 0 70000 SnowMult 0.35 1 0
R_Luck21 Rolls 11 -5 140000000000 LuckMult 6.5 0 0
S_Deep Snow 4 0 5400000 SnowMult 0.35 1 0
M_Equip2 Misc 1 2 47000000 PetSlots 1 0 0
S_Size9 Snow -5 5 77000000 SizeMult 0.08 0 0
W2_RainbowLuck Rolls 18 -11 2.2e18 LuckMult 9 0 0
W2_LuckyLollipop Rolls 14 -7 3e14 LuckMult 5 0 0
M_Expansion13 Misc -1 -2 23000000 PetBoostMult 0.1 0 0
S_Avalanche Snow 6 -1 52000000000 SnowMult 1.5 1 0
R_Dice3 Rolls -3 1 34000 RollCooldownMult -0.1 0 0
M_Expansion5 Misc -1 -1 1000000 UnlockCraft 1 0 0
W2_CoralCrusher Snow 7 -8 1.6e16 PowerMult 0.5 1 0
S_Heavy Snow 0 -2 6300 PowerMult 0.35 1 0
S_Blizzard Snow 5 -1 98000000 SnowMult 1.5 1 0
R_Rain3 Rolls -3 5 41000000000 LuckMult 1.5 0 0
W2_CloudBurst Snow 14 -1 4.4e18 SnowMult 0.5 1 0
R_Gold2 Rolls -5 3 1400000000 LuckMult 0.25 0 0
M_Expansion2 Misc -1 0 60000 UnlockFuser 1 0 0
R_Dice5 Rolls -3 2 380000 SnowMult 0.2 1 0
W2_LuckyClockwork Rolls 17 -10 3.6e17 LuckMult 8 0 0
R_Luck10 Rolls 5 -2 14000000 LuckMult 0.35 0 0
M_Expansion1 Misc 1 -1 350 PetBoostMult 0.1 0 0
W2_StarBurst Snow 15 -1 2.6e19 SnowMult 0.5 1 0
W2_PetalStrike Snow 5 -6 2.4e14 PowerMult 0.5 1 0
S_Size10 Snow -5 6 1800000000 SizeMult 0.08 0 0
S_Fresh Snow 0 1 130 SnowMult 0.15 1 0
S_Glacier Snow 7 -1 740000000000 SnowMult 2 1 0
S_Size5 Snow -3 3 110000 SizeMult 0.08 0 0
R_Hyper Rolls -4 1 20000000000 RollCooldownMult -0.1 0 0
M_Expansion21 Misc -2 3 7500000000 PetBoostMult 0.1 0 0
M_Center Misc 0 0 15 WalkSpeed 1 0 1
R_Gold6 Rolls -9 7 1500000000000 LuckMult 0.65 0 0
W2_SkyReach Misc -5 8 2.86e18 SizeMult 0.06 0 0
W2_CandyCrush Snow 6 -7 4.8e14 PowerMult 0.5 1 0
M_Walk2 Misc 2 0 1200 WalkSpeed 2 0 0
S_Turbo Snow 0 3 180000 SpinMult 0.15 0 0
S_Sharp Snow 0 -1 210 PowerMult 0.35 1 0
R_Dice4 Rolls -2 1 2400 SnowMult 0.15 1 0
S_Gain1 Snow 1 0 170 SnowMult 0.15 1 0
M_Egg4 Misc -3 2 480000 EggDiscount 0.1 0 0
W2_TideSurge Snow 11 -1 2e16 SnowMult 0.5 1 0
M_Expansion14 Misc 3 -2 29000000 WalkSpeed 1 0 0
R_Rain2 Rolls -3 4 32000000000 LuckMult 1.5 0 0
R_Rain6 Rolls -3 8 940000000000 LuckMult 3.5 0 0
S_Gain2 Snow 2 0 4900 SnowMult 0.2 1 0
R_Luck8 Rolls 4 -2 3300000 LuckMult 0.35 0 0
R_Luck14 Rolls 7 -3 200000000 LuckMult 0.65 0 0
S_Third Snow -1 3 780000 SnowMult 0.2 1 0
W2_GearGrinder Snow 9 -10 5.76e17 PowerMult 0.5 1 0
R_Luck5 Rolls 2 0 3900 LuckMult 0.15 0 0
R_Luck17 Rolls 8 -3 3600000000 LuckMult 1.5 0 0
W2_TickTockSnow Snow 13 -1 7.2e17 SnowMult 0.5 1 0
W2_KoiCompanions Misc 0 3 1.95e14 SizeMult 0.06 0 0
W2_BlockBuster Snow 8 -9 9.6e16 PowerMult 0.5 1 0
R_Luck4 Rolls 2 -1 3000 LuckMult 0.15 0 0
S_Quick Snow 0 2 8000 SpinMult 0.15 0 0
R_Luck1 Rolls 0 0 24 LuckMult 0.15 0 1
S_Size7 Snow -4 4 8700000 SizeMult 0.08 0 0
M_Expansion10 Misc 0 -3 2100000 PetBoostMult 0.1 0 0
R_Rain4 Rolls -3 6 360000000000 LuckMult 2 0 0
M_Expansion4 Misc 2 -2 1500 PetBoostMult 0.1 0 0
W2_SugarRush Snow 10 -1 6e14 SnowMult 0.5 1 0
R_Luck16 Rolls 8 -4 2900000000 LuckMult 1.5 0 0
M_Friend1 Misc 0 -1 31 FriendBoost 0.05 0 0
M_Expansion9 Misc -1 2 1000000 FriendBoost 0.025 0 0
M_Squad Misc 1 -3 300000 FriendBoost 0.05 0 0
S_Size1 Snow -1 1 270 SizeMult 0.08 0 0
M_Equip1 Misc 0 2 1600000 PetSlots 1 0 0
W2_BlossomBreeze Snow 9 -1 3e14 SnowMult 0.5 1 0
W2_MeteorStrike Snow 11 -12 2.08e19 PowerMult 0.5 1 0
M_Expansion16 Misc -3 0 860000000 PetBoostMult 0.1 0 0
W2_KoiFortune Rolls 13 -6 1.5e14 LuckMult 4 0 0
M_Expansion18 Misc -3 1 530000000 FriendBoost 0.025 0 0
R_Gold1 Rolls -4 2 1100000000 LuckMult 0.2 0 0
S_Size6 Snow -3 4 6900000 SizeMult 0.08 0 0
R_Luck20 Rolls 10 -5 110000000000 LuckMult 4 0 0
S_Storm Snow 4 -1 11000000 SnowMult 0.65 1 0
R_Rain5 Rolls -3 7 580000000000 LuckMult 2.5 0 0
S_Center Snow 0 0 19 SnowMult 0.15 1 1
R_Luck12 Rolls 6 -3 120000000 LuckMult 0.65 0 0
R_Luck9 Rolls 4 -1 4200000 LuckMult 0.35 0 0
R_Triple Rolls -1 1 330000000 SnowMult 0.15 1 0
S_Size2 Snow -1 2 13000 SizeMult 0.08 0 0
S_Rush Snow 1 1 10000 SnowMult 0.35 1 0
S_Size8 Snow -4 5 60000000 SizeMult 0.08 0 0
W2_CosmicLuck Rolls 19 -12 1.3e19 LuckMult 12 0 0
W2_SpringReach Misc -4 7 4.68e17 SizeMult 0.06 0 0
S_Glacial Snow 4 -6 460000000000 PowerMult 2.5 1 0
R_Luck13 Rolls 6 -2 160000000 LuckMult 0.65 0 0
W2_SweetFriends Misc -1 4 3.9e14 SizeMult 0.06 0 0
M_PortalBoots Misc 4 -1 220000000000 WalkSpeed 2 0 0
R_Gold4 Rolls -7 5 66000000000 LuckMult 0.4 0 0
W2_GalaxyReach Misc -6 9 1.69e19 SizeMult 0.06 0 0
W2_GiantToys Misc -3 6 7.8e16 SizeMult 0.06 0 0
W2_TidalReach Misc -2 5 1.3e16 SizeMult 0.06 0 0
R_Dice1 Rolls -1 0 64 RollCooldownMult -0.1 0 0
R_Luck6 Rolls 3 -1 43000 LuckMult 0.35 0 0
M_Feast Misc -1 3 170000000000 PetBoostMult 0.2 0 0
M_Expansion20 Misc -3 3 16000000000 WalkSpeed 1 0 0
M_Expansion19 Misc 2 1 12000000000 PetBoostMult 0.1 0 0
M_Expansion17 Misc 3 0 420000000 WalkSpeed 1 0 0
W2_ThunderStrike Snow 10 -11 3.52e18 PowerMult 0.5 1 0
M_Expansion8 Misc 1 1 1300000 WalkSpeed 1 0 0
M_Expansion15 Misc -2 -1 670000000 EggDiscount 0.025 0 0
R_Luck11 Rolls 5 -3 18000000 LuckMult 0.65 0 0
M_Egg2 Misc -2 1 560 EggDiscount 0.05 0 0
R_Luck15 Rolls 7 -4 260000000 LuckMult 0.65 0 0
M_Expansion12 Misc 3 -3 37000000 EggDiscount 0.025 0 0
M_Expansion11 Misc 2 -3 2600000 WalkSpeed 1 0 0
M_Expansion7 Misc -2 0 27000 PetBoostMult 0.1 0 0
M_Expansion3 Misc 1 -2 710 EggDiscount 0.025 0 0
M_Expansion6 Misc 2 -1 21000 EggDiscount 0.025 0 0
S_Crush Snow 1 -3 610000 PowerMult 1.5 1 0
M_Pet1 Misc 0 1 3000 SnowMult 0.15 1 0
S_Size4 Snow -2 3 89000 SizeMult 0.08 0 0
S_Meteor Snow 3 -5 280000000000 PowerMult 2 1 0
M_Egg3 Misc -2 2 440 EggDiscount 0.1 0 0
S_Swing Snow -1 -2 140000 PowerMult 0.65 1 0
M_Egg1 Misc -1 1 39 EggDiscount 0.05 0 0
M_Friend2 Misc 0 -2 910 FriendBoost 0.05 0 0
S_Size3 Snow -2 2 16000 SizeMult 0.08 0 0
R_Luck3 Rolls 1 -1 100 LuckMult 0.15 0 0
W2_ToyChest Snow 12 -1 1.2e17 SnowMult 0.5 1 0
R_Gold5 Rolls -8 6 84000000000 LuckMult 0.5 0 0
R_Luck19 Rolls 9 -5 5900000000 LuckMult 1.5 0 0
R_Luck7 Rolls 3 -2 55000 LuckMult 0.35 0 0
M_Walk1 Misc 1 0 50 WalkSpeed 2 0 0
W2_LuckyToyDice Rolls 16 -9 6e16 LuckMult 7 0 0
W2_PearlLuck Rolls 15 -8 1e16 LuckMult 6 0 0
M_Sprint Misc 3 -1 230000 WalkSpeed 3 0 0
R_Luck22 Rolls 12 -6 1900000000000 LuckMult 10 0 0
R_Rain1 Rolls -3 3 9600000000 LuckMult 1 0 0
R_Dice2 Rolls -2 0 1900 RollCooldownMult -0.1 0 0
R_Luck2 Rolls 1 0 81 LuckMult 0.15 0 0
S_FrostCore Snow 8 -1 1200000000000 SnowMult 2.5 1 0
R_Luck18 Rolls 9 -4 4600000000 LuckMult 1.5 0 0
S_Titan Snow 2 -4 25000000000 PowerMult 1.5 1 0"""
UPGRADES = []
for line in UPG.splitlines():
    f = line.split()
    UPGRADES.append({"Id": f[0], "Tree": f[1], "Q": int(f[2]), "R": int(f[3]), "Cost": float(f[4]), "Stat": f[5], "Amt": float(f[6]),
                     "Mul": f[7] == "1", "Center": f[8] == "1"})
UP_BASE = {"SizeMult": 1, "SpinMult": 1, "WalkSpeed": 16, "PetSlots": 3, "PowerBonus": 0, "EggDiscount": 0, "LuckMult": 1, "FriendBoost": 0,
           "RollCooldownMult": 1, "ReachMult": 1, "SnowMult": 1, "PowerMult": 1, "PetBoostMult": 1, "UnlockFuser": 0, "UnlockCraft": 0}
UP_LIMITS = {"EggDiscount": (0, 0.5), "RollCooldownMult": (0.6, 1), "ReachMult": (1, 1.5), "SpinMult": (1, 1.6), "WalkSpeed": (16, 40),
             "PetBoostMult": (1, 2), "FriendBoost": (0, 0.2)}
HEX_DIRS = [(1, 0), (-1, 0), (0, 1), (0, -1), (1, -1), (-1, 1)]

REBIRTH = {"Max": 50, "Snow": 0.5, "Luck": 0.25,
           "Milestones": [62000, 18e6, 1.3e9, 45e9, 880e9, 50e12]}
def rebirth_cost(count):
    level = count + 1; m = REBIRTH["Milestones"]
    tier = m[min(level, len(m)) - 1]; rep = max(1, level - len(m) + 1)
    return tier * rep * rep

ACHIEVEMENTS = [  # stat, goal, snow, luck
    ("Rolls", 100, 0, .02), ("Rolls", 1000, 0, .03), ("Rolls", 5000, 0, .05), ("SnowEarned", 1e5, .02, 0), ("SnowEarned", 1e9, .03, 0),
    ("SnowEarned", 1e12, .05, 0), ("Hatches", 10, .02, 0), ("Hatches", 100, .03, 0), ("Treasures", 10, .02, 0), ("Treasures", 100, .03, 0),
    ("PartsOwned", 3, 0, .02), ("PartsOwned", 6, 0, .03), ("PetsFound", 10, .02, 0), ("PetsFound", 25, .03, 0), ("Rebirths", 1, .02, 0),
    ("Rebirths", 5, .03, 0), ("World2", 1, .05, .05), ("QuestsDone", 10, 0, .02), ("QuestsDone", 50, 0, .03),
]

# ---- balance levers (set by tune.py) ----
COST_MULT = {}   # stage id -> multiplier on the live stage cost
W2_UP_STAGE = {"W2_BlossomBreeze": "Portal", "W2_PetalStrike": "Portal", "W2_KoiFortune": "Portal", "W2_KoiCompanions": "Portal",
    "W2_SugarRush": "Candy", "W2_CandyCrush": "Candy", "W2_LuckyLollipop": "Candy", "W2_SweetFriends": "Candy",
    "W2_TideSurge": "Atlantis", "W2_CoralCrusher": "Atlantis", "W2_PearlLuck": "Atlantis", "W2_TidalReach": "Atlantis",
    "W2_ToyChest": "Toybox", "W2_BlockBuster": "Toybox", "W2_LuckyToyDice": "Toybox", "W2_GiantToys": "Toybox",
    "W2_TickTockSnow": "Clockwork", "W2_GearGrinder": "Clockwork", "W2_LuckyClockwork": "Clockwork", "W2_SpringReach": "Clockwork",
    "W2_CloudBurst": "Cloud", "W2_ThunderStrike": "Cloud", "W2_RainbowLuck": "Cloud", "W2_SkyReach": "Cloud",
    "W2_StarBurst": "Cosmic", "W2_MeteorStrike": "Cosmic", "W2_CosmicLuck": "Cosmic", "W2_GalaxyReach": "Cosmic"}
FIXED_UP = {"M_Pet1", "M_Expansion2", "M_Expansion5"}   # machine unlock tiles: fixed prices, not on the curve
LIVE_COST = {s[0]: s[1] for s in STAGES}
def stage_cost(sid):
    return LIVE_COST[sid] * COST_MULT.get(sid, 1.0)
def price_end(costs):
    az = costs["AbsoluteZero"]; after = costs["Portal"]
    return 0.25 * min(after if after > 0 else az * 31, az * 31)
PE_LIVE = price_end(LIVE_COST)
def upgrade_cost(u):
    c = u["Cost"]
    if u["Id"] in W2_UP_STAGE:
        s = W2_UP_STAGE[u["Id"]]; return c * COST_MULT.get(s, 1.0)
    if u["Id"] in FIXED_UP: return c
    pe = price_end({s: stage_cost(s) for s in LIVE_COST})
    if abs(pe / PE_LIVE - 1) < 1e-9: return c
    f = math.log(max(c, 15) / 15) / math.log(PE_LIVE / 15)
    return 15 * (pe / 15) ** f
def egg_cost(e):
    s = e[2]
    if s == "Sakura": s = "Portal"
    return e[1] * COST_MULT.get(s, 1.0)
def refresh_costs():
    for u in UPGRADES: u["C"] = upgrade_cost(u)
refresh_costs()
