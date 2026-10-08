# sim.py - reproducible progression simulation (fixed seeds) using the production formulas in model.py / gamedata.py.
# Estimates only: simulated players, not measured human playthroughs.
import json, math, os, random, statistics, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gamedata as G
import model as M
import catalog as CAT

STAGE_IDS = [s[0] for s in G.STAGES]
class _SC(dict):
    def __getitem__(self, k): return G.stage_cost(k)
    def get(self, k, d=None): return G.stage_cost(k) if k in G.LIVE_COST else d
STAGE_COST = _SC()
UP_BY_ID = {u["Id"]: u for u in G.UPGRADES}
UP_POS = {(u["Tree"], u["Q"], u["R"]): u for u in G.UPGRADES}
INCOME_STATS = {"SnowMult", "PowerMult", "SpinMult", "SizeMult", "PetBoostMult", "PetSlots", "WalkSpeed"}

BEHAVIOURS = {
    # active: share of play time spent driving/clearing; boost: time-averaged Snow multiplier from events + personal boosts
    # (quests/daily/codes) + SnowMinutes rewards; combo: average dig-combo multiplier; payback: how patient purchases are;
    # trip: minutes between garage visits; rolls: max rolls per visit; luckBoost: time-averaged luck multiplier
    "efficient": dict(active=0.9, boost=1.42, combo=1.75, payback=0.35, trip=4.0, rolls=12, luckBoost=1.25, fuse=True, quests=True),
    "casual": dict(active=0.72, boost=1.22, combo=1.5, payback=0.6, trip=7.0, rolls=6, luckBoost=1.12, fuse=True, quests=True),
    "noRewards": dict(active=0.85, boost=1.12, combo=1.7, payback=0.4, trip=5.0, rolls=10, luckBoost=1.1, fuse=True, quests=False),
}

_UPC = {}
def upgrade_stats(owned):
    key = frozenset(owned)
    r = _UPC.get(key)
    if r is None:
        r = _upgrade_stats(owned)
        if len(_UPC) > 20000: _UPC.clear()
        _UPC[key] = r
    return r

def _upgrade_stats(owned):
    st = dict(G.UP_BASE); mults = {}
    for uid in owned:
        u = UP_BY_ID[uid]
        if u["Mul"]: mults[u["Stat"]] = mults.get(u["Stat"], 1) * (1 + u["Amt"])
        else: st[u["Stat"]] = st.get(u["Stat"], 0) + u["Amt"]
    for k, m in mults.items(): st[k] *= m
    for k, (lo, hi) in G.UP_LIMITS.items(): st[k] = min(hi, max(lo, st[k]))
    return st

def available_upgrades(owned):
    out = []
    for u in G.UPGRADES:
        if u["Id"] in owned: continue
        if u["Center"]: out.append(u); continue
        for dq, dr in G.HEX_DIRS:
            nb = UP_POS.get((u["Tree"], u["Q"] + dq, u["R"] + dr))
            if nb and nb["Id"] in owned: out.append(u); break
    return out

class Player:
    def __init__(self, cat, beh, seed, rebirths=0, carry=None):
        self.cat, self.b, self.rng = cat, BEHAVIOURS[beh], random.Random(seed)
        self.t, self.snow, self.earned = 0.0, 0.0, 0.0
        self.stages = {"Starter"}
        self.owned = {"blade_basic": 1, "engine_starter": 1, "gear_wheels": 1}
        self.build = {"Blade": "blade_basic", "Engine": "engine_starter", "Gear": "gear_wheels"}
        self.ups, self.pets = set(), {}
        self.rebirths = rebirths
        self.offers = {1: None, 2: None, 3: None}; self.reserved = None
        self.rolls = self.hatches = self.treasures = self.quests = 0
        self.dry = 0
        self.log, self.arrive, self.events = [], {"Starter": 0.0}, []
        self.useful_waits, self.since_useful, self.useful_t = [], 0, []
        self.last_trip = -1e9
        if carry:
            self.owned, self.build, self.ups, self.pets = dict(carry.owned), dict(carry.build), set(carry.ups), dict(carry.pets)
            self.rolls, self.hatches, self.treasures, self.quests, self.earned = carry.rolls, carry.hatches, carry.treasures, carry.quests, carry.earned
        self.dirty = True

    # ---------- derived values ----------
    def band(self):
        best = 1
        for s in self.stages:
            if s in G.BAND_OF: best = max(best, G.BAND_OF[s])
        return best
    def ach(self):
        s = l = 0.0
        vals = {"Rolls": self.rolls, "SnowEarned": self.earned, "Hatches": self.hatches, "Treasures": self.treasures,
                "PartsOwned": len(self.owned), "PetsFound": len(set(n.replace("Golden ", "") for n in self.pets)), "Rebirths": self.rebirths,
                "World2": 1 if "Sakura" in self.stages else 0, "QuestsDone": self.quests}
        for stat, goal, sn, lu in G.ACHIEVEMENTS:
            if vals[stat] >= goal: s += sn; l += lu
        return s, l
    def mods(self, ups=None):
        u = upgrade_stats(self.ups if ups is None else ups)
        ws = u["WalkSpeed"]
        return u, {"PowerMult": u["PowerMult"], "SpinMult": u["SpinMult"], "SizeMult": u["SizeMult"], "ReachMult": u["ReachMult"],
                   "SpeedMult": 1 + min(1, max(0, ws / 16 - 1)) * 0.5}
    def pet_mult(self, u, pets=None):
        pets = self.pets if pets is None else pets
        slots, tot = float(int(u["PetSlots"])), 0.0
        for b, c in sorted(((self.pet_boost(n), c) for n, c in pets.items() if c > 0), reverse=True):
            take = min(c, slots); tot += b * take; slots -= take
            if slots <= 0: break
        return 1 + tot * u["PetBoostMult"]
    def pet_boost(self, name):
        if name.startswith("Golden "): return PET_BOOST[name[7:]] * G.GOLDEN_MULT
        return PET_BOOST[name]
    def luck(self, u):
        s, l = self.ach()
        return u["LuckMult"] * (1 + self.rebirths * G.REBIRTH["Luck"]) * self.b["luckBoost"] * (1 + l)
    def field_stage(self, build=None, mods=None):
        st = M.stats_for(self.cat, build or self.build, mods or self.mods()[1])
        best, bs = 0.0, "Starter"
        for s in self.stages:
            if s not in G.STAGE_FIELD: continue
            v = M.layer_rate(st, s) * G.STAGE_FIELD[s][1] * M.SPP_MULT.get(s, 1.0)
            if v > best: best, bs = v, s
        return best, bs, st
    def income(self, build=None, ups=None, pets=None):
        u, mo = self.mods(ups)
        base, stage, st = self.field_stage(build, mo)
        s, l = self.ach()
        snow_mult = u["SnowMult"] * (1 + self.rebirths * G.REBIRTH["Snow"]) * (1 + s) * self.b["boost"]
        return base * snow_mult * self.pet_mult(u, pets) * self.b["combo"] * 1.06 * self.b["active"], stage
    def rate(self):
        if self.dirty:
            self.cur, self.cur_stage = self.income(); self.dirty = False
        return self.cur

    # ---------- helpers ----------
    def next_stage(self):
        for s in STAGE_IDS:
            if s not in self.stages: return s
        return None
    def eta_next(self):
        ns = self.next_stage()
        if not ns: return 3600
        need = max(0, STAGE_COST[ns] - self.snow)
        return need / max(self.rate(), 1e-9)
    def spend_time(self, sec):
        # time passes while not clearing
        self.t += sec
    def earn(self, sec):
        r = self.rate()
        g = r * sec
        self.snow += g; self.earned += g
        self.t += sec
        # treasures: one per ~100 fully cleared tiles (layers / 3 / 100)
        stage = self.cur_stage
        if stage in G.STAGE_FIELD and r > 0:
            u, mo = self.mods()
            st = M.stats_for(self.cat, self.build, mo)
            layers = M.layer_rate(st, stage) * sec * self.b["active"]
            self.treasures += layers / 300.0
        if self.b["quests"]:
            self.quests += sec / 900.0  # ~4 quests per hour for engaged players

    def best_owned_score(self, slot, stage, mods):
        best = 0
        for pid in self.owned:
            if self.cat[pid]["slot"] != slot: continue
            b = dict(self.build); b[slot] = pid
            best = max(best, M.score(M.stats_for(self.cat, b, mods), stage))
        return best
    def gain_of(self, pid):
        """income multiplier if this part replaced the current one in its slot (best other slots kept)"""
        p = self.cat[pid]
        b = dict(self.build); b[p["slot"]] = pid
        new, _ = self.income(build=b)
        return new / max(self.rate(), 1e-9)
    def useful(self, pid):
        return pid not in self.owned and self.gain_of(pid) > 1.03

    # ---------- actions ----------
    def try_stage(self):
        ns = self.next_stage()
        if ns and self.snow >= STAGE_COST[ns]:
            self.snow -= STAGE_COST[ns]; self.stages.add(ns)
            if ns == "Portal": self.stages.add("Sakura"); self.arrive["Sakura"] = self.t
            self.arrive[ns] = self.t; self.dirty = True
            self.events.append((self.t, "stage", ns))
            self.spend_time(25)
            return True
        return False

    def try_upgrades(self):
        bought = 0
        eta = self.eta_next()
        limit = max(30, self.b["payback"] * eta)
        ns = self.next_stage(); nscost = STAGE_COST.get(ns, 1e30) if ns else 1e30
        for _ in range(6):
            cands = [u for u in available_upgrades(self.ups) if u["C"] <= self.snow]
            if not cands: break
            cur = self.rate(); best, bv = None, 1e18
            for u in cands:
                if u["Stat"] in INCOME_STATS:
                    ups = set(self.ups); ups.add(u["Id"])
                    new, _ = self.income(ups=ups)
                    gain = new - cur
                    pay = u["C"] / gain if gain > 0 else 1e18
                else:
                    pay = 1e18 if u["C"] > 0.02 * nscost else u["C"] / max(cur, 1e-9) * 3  # cheap utility tiles / path openers
                if u["C"] < 0.003 * nscost: pay = min(pay, 1.0)
                if pay < bv: best, bv = u, pay
            if best is None or bv > limit: break
            self.snow -= best["C"]; self.ups.add(best["Id"]); self.dirty = True; bought += 1
            self.events.append((self.t, "upgrade", best["Id"]))
        if bought: self.spend_time(3 * bought)
        return bought

    def try_eggs(self):
        u, _ = self.mods()
        stage_eggs = [e for e in G.EGGS if e[2] in self.stages]
        if not stage_eggs: return 0
        egg = max(stage_eggs, key=lambda e: G.egg_cost(e))
        cost = G.egg_cost(egg) * (1 - u["EggDiscount"])
        ns = self.next_stage(); nscost = STAGE_COST.get(ns, 1e30) if ns else 1e30
        n = 0
        eta = self.eta_next()
        while self.snow >= cost and n < 25:
            # expected gain of one hatch (expected boost improvement over the weakest equipped pet)
            cur = self.pet_mult(u)
            exp = 0.0
            for name, ch, bo in egg[3]:
                pets = dict(self.pets); pets[name] = pets.get(name, 0) + 1
                if self.b["fuse"] and u["UnlockFuser"] >= 1 and pets[name] >= 2:
                    pets["Golden " + name] = pets.get("Golden " + name, 0) + 1.0 / 3.0  # a third of a future Golden pet
                exp += ch / 100 * (self.pet_mult(u, pets) - cur)
            r = self.rate()
            gain = r * exp / cur
            if gain <= 0 or exp / cur < 0.001: break
            pay = cost / gain
            if pay > max(45, self.b["payback"] * eta * 1.2) and not (cost < 0.002 * nscost and exp / cur > 0.01): break
            self.snow -= cost; n += 1; self.hatches += 1
            x = self.rng.random() * 100
            for name, ch, bo in egg[3]:
                x -= ch
                if x <= 0: break
            self.pets[name] = self.pets.get(name, 0) + 1
            self.dirty = True
            self.fuse()
        if n: self.spend_time(4 + 1.5 * n)
        return n

    def fuse(self):
        u, _ = self.mods()
        if not self.b["fuse"] or u["UnlockFuser"] < 1: return
        for name in list(self.pets):
            if name.startswith("Golden "): continue
            while self.pets.get(name, 0) >= 4:  # keep one normal copy, fuse 3 spares
                self.pets[name] -= 3
                g = "Golden " + name
                self.pets[g] = self.pets.get(g, 0) + 1
                self.dirty = True

    def roll_offer(self, u):
        band = self.band()
        pool = M.offer_pool(self.cat, band, self.luck(u))
        protect = self.dry >= PROTECT_AFTER
        if protect:
            use = {k: v for k, v in pool.items() if self.useful(k) and self.cat[k]["band"] <= band + 1}
            if use: pool = use
        x = self.rng.random() * sum(pool.values())
        for pid, w in sorted(pool.items(), key=lambda kv: (M.RANK[self.cat[kv[0]]["rarity"]], self.cat[kv[0]]["band"], kv[0])):
            x -= w
            if x <= 0: break
        self.rolls += 1
        if self.useful(pid): self.dry = 0; self.useful_waits.append(self.since_useful); self.since_useful = 0; self.useful_t.append(self.t)
        else: self.dry += 1; self.since_useful += 1
        return pid

    def garage_trip(self, force=False):
        if not force and self.t - self.last_trip < self.b["trip"] * 60: return False
        self.last_trip = self.t
        u, _ = self.mods()
        self.spend_time(9)  # teleport + walk to pedestals
        cd = 2.0 * max(0.6, u["RollCooldownMult"]) + 1.3
        bought_any = False
        rolls = 0
        def value(pid):
            return self.gain_of(pid) if pid not in self.owned else 0
        # reserved first
        if self.reserved and self.reserved[0] not in self.owned and self.snow >= self.reserved[1] and value(self.reserved[0]) > 1.03:
            self.buy(self.reserved[0], self.reserved[1]); self.reserved = None; bought_any = True
        stuck = 0
        while rolls < self.b["rolls"]:
            rolled = False
            for k in (1, 2, 3):
                o = self.offers[k]
                if o is None or o[0] in self.owned or value(o[0]) <= 1.03:
                    pid = self.roll_offer(u)
                    self.offers[k] = (pid, self.cat[pid]["price"])
                    rolls += 1; self.spend_time(cd); rolled = True
            if not rolled:
                # every pedestal holds a useful but unaffordable offer: reroll the weakest one, or leave
                stuck += 1
                if stuck > 2: break
                k = min((1, 2, 3), key=lambda i: value(self.offers[i][0]) / max(self.offers[i][1], 1))
                pid = self.roll_offer(u); self.offers[k] = (pid, self.cat[pid]["price"]); rolls += 1; self.spend_time(cd)
            # buy the best affordable useful offer (largest gain per price)
            best, bv = None, 0
            for k in (1, 2, 3):
                pid, price = self.offers[k]
                g = value(pid)
                if g > 1.03 and price <= self.snow:
                    v = (g - 1) / max(price, 1)
                    if best is None or v > bv: best, bv = k, v
            if best:
                pid, price = self.offers[best]; self.buy(pid, price); self.offers[best] = None; bought_any = True
                continue
            # reserve an exciting unaffordable offer (big gain), replacing a weaker reservation
            for k in (1, 2, 3):
                pid, price = self.offers[k]
                g = value(pid)
                if g > 1.25 and price > self.snow:
                    rv = value(self.reserved[0]) if self.reserved else 0
                    if g > rv:
                        self.reserved = (pid, price); self.offers[k] = None; self.spend_time(2)
                        self.events.append((self.t, "reserve", pid))
            if rolls >= self.b["rolls"]: break
        self.spend_time(9 + (6 if bought_any else 0))
        return bought_any

    def buy(self, pid, price):
        self.snow -= price; self.owned[pid] = self.owned.get(pid, 0) + 1
        slot = self.cat[pid]["slot"]
        b = dict(self.build); b[slot] = pid
        new, _ = self.income(build=b)
        if new > self.rate(): self.build = b
        self.dirty = True
        self.events.append((self.t, "part", pid))
        # re-check every slot (new part might enable a better combo)
        self.spend_time(3)

    def step(self, dt=10):
        self.earn(dt)
        while self.try_stage(): pass
        self.try_upgrades()
        self.try_eggs()
        # garage: go when a likely-useful purchase is affordable, or on the regular cadence
        self.garage_trip()

PET_BOOST = {}
for e in G.EGGS:
    for name, ch, bo in e[3]: PET_BOOST[name] = bo
PROTECT_AFTER = 6

def run(cat, beh, seed, until="Portal", max_hours=12, rebirths=0, carry=None):
    p = Player(cat, beh, seed, rebirths, carry)
    while until not in p.stages and p.t < max_hours * 3600:
        p.step()
    return p

def summarize(players, stages):
    out = {}
    for s in stages:
        ts = sorted(p.arrive[s] / 60 for p in players if s in p.arrive)
        if len(ts) < len(players) * 0.5: out[s] = None; continue
        q = lambda f: ts[min(len(ts) - 1, int(f * len(ts)))]
        out[s] = {"p10": round(q(0.1), 1), "median": round(q(0.5), 1), "p90": round(q(0.9), 1), "n": len(ts)}
    return out

if __name__ == "__main__":
    cat = CAT.build()
    beh = sys.argv[1] if len(sys.argv) > 1 else "efficient"
    n = int(sys.argv[2]) if len(sys.argv) > 2 else 20
    until = sys.argv[3] if len(sys.argv) > 3 else "Portal"
    ps = [run(cat, beh, 1000 + i, until=until, max_hours=14) for i in range(n)]
    res = summarize(ps, STAGE_IDS)
    for s in STAGE_IDS: print(s, res.get(s))
    p = ps[0]
    print("parts bought", [e[2] for e in p.events if e[1] == "part"])



