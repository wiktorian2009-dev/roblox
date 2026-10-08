# jobs.py - NPC clearing-contract model (ContractConfig / ContractService), used by sim2.py.
# One Help Yard per stage, one job at a time. Schedule: first offer 90-150 s after joining, then 240-420 s after the previous
# offer ENDS; an offer is visible 150 s. Accepting -> travel to the yard -> clear the scene's zones -> completion bonus.
# Contract tiles pay normal Snow per layer, scaled down when the tiles are softer than the stage (never more per blade-second).
import math, random
import model as M, gamedata as G

# total zone area (studs^2) and a demand factor (turning / ice) per contract type, from ContractConfig.Types
TYPES = {
    "Road": (1638, 1.15), "Cottages": (234 * 3 + 18 * 3, 1.0), "Market": (18 * 18 + 66 * 9 + 12 * 12 + 2 * 12 * 12 + 4 * 12 * 9, 1.15),
    "Parking": (12 * 42 + 4 * 6 * 9 + 30 * 12, 1.1), "BusStop": (39 * 12 + 24 * 12 + 9 * 15, 1.0), "Crates": (3 * 15 * 15, 1.0),
    "Pump": (18 * 18 + 48 * 12 + 2 * 15 * 15 + 18 * 12, 1.35), "Workshop": (18 * 15 + 54 * 18 + 2 * 12 * 15, 1.25),
}
DEMANDING = {"Pump", "Workshop", "Market"}

def clear_seconds(st, ctype, rnd):
    """seconds to finish the scene: coverage at plowing speed with turns, 1.4 passes for the 92% tolerance + the tile-power share"""
    area, demand = TYPES[ctype]
    w = st["BladeWidth"] + 2 * M.SLACK
    v = max(3.0, st["MaxSpeed"] * M.PLOWING_SPEED * M.handling(st) * 0.75)   # small yards: lots of short lanes and turns
    t = area / (w * v) * 1.4 * demand
    return max(35.0, min(240.0, t * rnd.uniform(0.85, 1.25)))

class Policy:
    """reward policy. mode 'live': BonusSeconds x rate. mode 'target': mult x rate x expected duration - expected tile Snow."""
    def __init__(self, mode="live", bonus_seconds=30, mult=2.0, mult_demanding=2.5, travel=35.0, overhead=20.0):
        self.mode, self.bonus_seconds, self.mult, self.mult_d = mode, bonus_seconds, mult, mult_demanding
        self.travel, self.overhead = travel, overhead
    def bonus(self, rate, st, ctype, tile_share):
        if self.mode == "live": return rate * self.bonus_seconds
        area, demand = TYPES[ctype]
        w = st["BladeWidth"] + 2 * M.SLACK
        v = max(3.0, st["MaxSpeed"] * M.PLOWING_SPEED * M.handling(st) * 0.75)
        tc = max(35.0, min(240.0, area / (w * v) * 1.4 * demand))
        mult = self.mult_d if ctype in DEMANDING else self.mult
        return max(25.0, rate * (mult * (tc + self.travel + self.overhead) - tile_share * tc))

class JobClock:
    def __init__(self, rnd):
        self.rnd = rnd
        self.next_offer = rnd.uniform(90, 150)
    def due(self, t): return t >= self.next_offer
    def ended(self, t): self.next_offer = t + self.rnd.uniform(240, 420)
