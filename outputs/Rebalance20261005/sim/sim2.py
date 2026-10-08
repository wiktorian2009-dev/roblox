# sim2.py - sim.Player plus: NPC clearing jobs (jobs.py), exact live prices (optional), per-stage snapshots and an
# improvement log (every part / upgrade / egg purchase with its measured income gain). Estimates only, not human playtests.
import copy, json, math, os, random, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gamedata as G, model as M, sim, jobs as J

# job behaviour: share of offers accepted
ACCEPT = {"efficient": 0.9, "casual": 0.6, "noRewards": 0.0, "jobs": 1.0, "collect": 0.0}
JOB_TILE_SHARE = 0.8   # contract tiles pay normal Snow per layer, softer tiles scaled down -> a little below the normal rate

class Player2(sim.Player):
    def __init__(self, cat, beh, seed, rebirths=0, carry=None, policy=None, accept=None, beh_name=None):
        base = beh if beh in sim.BEHAVIOURS else "efficient"
        super().__init__(cat, base, seed, rebirths, carry)
        self.beh_name = beh_name or beh
        self.policy = policy or J.Policy("live")
        self.accept = ACCEPT.get(self.beh_name, 0.9) if accept is None else accept
        self.jrnd = random.Random(seed * 7 + 3)
        self.clock = J.JobClock(self.jrnd)
        self.jobs_done = 0; self.job_snow = 0.0; self.job_time = 0.0; self.job_ratios = []
        self.offer_log = []
        self.snap = {}   # stage -> {"arrive": {...}, "leave": {...}}
        self.improvements = []   # (t, kind, id, gain)
        self.snapshot_state("Starter", "arrive")
        if carry is None:   # the tutorial walks every new player to the garage right after the first upgrade (~1.5 min)
            self.last_trip = 90 - self.b["trip"] * 60
            self.clock.next_offer += 180   # ContractConfig.Offer.FirstDelay counts from the end of the tutorial

    def snapshot_state(self, stage, which):
        rec = {"t": self.t, "income": self.rate(), "build": dict(self.build), "owned": len(self.owned), "ups": len(self.ups),
               "pets": sum(self.pets.values()), "snow": self.snow, "stage": self.cur_stage if not self.dirty else None,
               "state": (dict(self.owned), dict(self.build), set(self.ups), dict(self.pets), set(self.stages), self.snow, self.rebirths)}
        self.snap.setdefault(stage, {})[which] = rec

    # ---------- jobs ----------
    def do_jobs(self):
        if self.accept <= 0 or not self.clock.due(self.t): return
        if self.jrnd.random() > self.accept:
            self.clock.ended(self.t + 150); return
        u, mo = self.mods()
        st = M.stats_for(self.cat, self.build, mo)
        ctype = self.jrnd.choice(list(J.TYPES))
        rate = self.rate()
        tc = J.clear_seconds(st, ctype, self.jrnd)
        bonus = self.policy.bonus(rate, st, ctype, JOB_TILE_SHARE)
        dur = self.policy.travel + self.policy.overhead + tc
        gained = rate * JOB_TILE_SHARE * tc + bonus
        self.snow += gained; self.earned += gained; self.t += dur
        self.jobs_done += 1; self.job_snow += gained; self.job_time += dur
        self.job_ratios.append(gained / max(rate * dur, 1e-9))
        self.clock.ended(self.t)
        self.events.append((self.t, "job", ctype))

    # ---------- logging hooks ----------
    def try_stage(self):
        ns = self.next_stage()
        if ns and self.snow >= sim.STAGE_COST[ns]:
            cur = max((s for s in self.stages if s in G.BAND_OF), key=lambda s: G.BAND_OF[s])
            self.snapshot_state(cur if cur != "Sakura" else "Sakura", "leave")
        before = self.rate() if ns and self.snow >= sim.STAGE_COST[ns] else None
        ok = super().try_stage()
        if ok:
            self.improvements.append((self.t, "stage", ns, self.rate() / max(before or 1e-9, 1e-9)))
            ns2 = [e for e in self.events if e[1] == "stage"][-1][2]
            self.snapshot_state(ns2 if ns2 != "Portal" else "Sakura", "arrive")
        return ok

    # 2026-10-06: pedestal offers expire 30 s after the roll (live C.Shop.OfferSeconds) - trips are minutes apart, so every offer left on
    # a pedestal is gone by the next visit (the reservation stays)
    EXPIRE = False
    def garage_trip(self, force=False):
        if self.EXPIRE and (force or self.t - self.last_trip >= self.b["trip"] * 60):
            self.offers = {1: None, 2: None, 3: None}
        return super().garage_trip(force)

    def buy(self, pid, price):
        before = self.rate()
        super().buy(pid, price)
        self.improvements.append((self.t, "part", pid, self.rate() / max(before, 1e-9)))

    def try_upgrades(self):
        before = self.rate(); n0 = len(self.ups)
        r = super().try_upgrades()
        if len(self.ups) > n0: self.improvements.append((self.t, "upgrade", len(self.ups) - n0, self.rate() / max(before, 1e-9)))
        return r

    def try_eggs(self):
        before = self.rate()
        n = super().try_eggs()
        if n: self.improvements.append((self.t, "egg", n, self.rate() / max(before, 1e-9)))
        return n

    # ---------- value-based buyer (smart=True): best log-gain per Snow across upgrades and egg hatches; saves for a clearly
    # better item that is affordable within SAVE_MIN minutes instead of spending on weak ones (eggs no longer starve upgrades)
    SAVE_MIN = 8.0
    PAYBACK_MIN = 40.0
    def options(self):
        u, mo = self.mods()
        cur = self.rate()
        out = []
        for uu in sim.available_upgrades(self.ups):
            if uu["Stat"] in sim.INCOME_STATS:
                ups = set(self.ups); ups.add(uu["Id"])
                g = self.income(ups=ups)[0] / max(cur, 1e-9)
                if g > 1.001: out.append(("upgrade", uu, uu["C"], g))
            else:
                ns = self.next_stage(); nscost = sim.STAGE_COST.get(ns, 1e30) if ns else 1e30
                if uu["C"] < 0.003 * nscost: out.append(("upgrade", uu, uu["C"], 1.02))   # cheap path openers / utility
        stage_eggs = [e for e in G.EGGS if e[2] in self.stages]
        if stage_eggs:
            egg = max(stage_eggs, key=lambda e: G.egg_cost(e))
            cost = G.egg_cost(egg) * (1 - u["EggDiscount"])
            pm = self.pet_mult(u); exp = 0.0
            for name, ch, bo in egg[3]:
                pets = dict(self.pets); pets[name] = pets.get(name, 0) + 1
                if self.b["fuse"] and u["UnlockFuser"] >= 1 and pets[name] >= 2:
                    pets["Golden " + name] = pets.get("Golden " + name, 0) + 1.0 / 3.0
                exp += ch / 100 * (self.pet_mult(u, pets) - pm)
            if exp > 0: out.append(("egg", egg, cost, 1 + exp / pm))
        return out

    def smart_buy(self):
        bought = 0
        for _ in range(8):
            opts = self.options()
            if not opts: break
            inc = max(self.rate(), 1e-9)
            # only items that pay for themselves within PAYBACK_MIN minutes of the extra income (no endless weak egg spam)
            opts = [o for o in opts if o[3] > 1.0 and o[2] / (inc * (o[3] - 1)) <= 60 * self.PAYBACK_MIN]
            reach = [o for o in opts if o[2] <= self.snow + inc * 60 * self.SAVE_MIN]
            if not reach: break
            val = lambda o: math.log(o[3]) / max(o[2], 1e-9)
            best = max(reach, key=val)
            if best[2] > self.snow:
                aff = [o for o in reach if o[2] <= self.snow and val(o) >= 0.5 * val(best)]
                if not aff: break
                best = max(aff, key=val)
            before = self.rate()
            kind, obj, cost, g = best
            self.snow -= cost
            if kind == "upgrade":
                self.ups.add(obj["Id"]); self.events.append((self.t, "upgrade", obj["Id"])); self.spend_time(3)
            else:
                self.hatches += 1
                x = self.rng.random() * 100
                for name, ch, bo in obj[3]:
                    x -= ch
                    if x <= 0: break
                self.pets[name] = self.pets.get(name, 0) + 1
                self.fuse(); self.spend_time(4); self.events.append((self.t, "egg", obj[0]))
            self.dirty = True; bought += 1
            self.improvements.append((self.t, kind, obj["Id"] if kind == "upgrade" else obj[0], self.rate() / max(before, 1e-9)))
        return bought

    # ---------- availability: is there an obtainable, reasonably affordable meaningful improvement right now? ----------
    AVAIL_MIN = 10.0      # affordable within this many minutes of current income (plus Snow in hand)
    AVAIL_GAIN = 1.10     # meaningful = +10% income
    AVAIL_ROLLS = 12      # a part counts as obtainable if one garage visit (12 rolls) shows it with >= 50% chance
    def available_now(self):
        inc = max(self.rate(), 1e-9); budget = self.snow + inc * 60 * self.AVAIL_MIN
        ns = self.next_stage()
        # parts and upgrades only (eggs are random hatches, the gate is the goal itself)
        for kind, obj, cost, g in self.options():
            if kind == "upgrade" and g >= self.AVAIL_GAIN and cost <= budget: return kind
        u, _ = self.mods(); band = self.band()
        pool = M.offer_pool(self.cat, band, self.luck(u))
        p_ok = 0.0
        for pid, w in pool.items():
            d = self.cat[pid]
            if pid in self.owned or d["price"] > budget or abs(d["band"] - band) > 2: continue
            if self.gain_of(pid) >= self.AVAIL_GAIN: p_ok += w
        if 1 - (1 - p_ok) ** self.AVAIL_ROLLS >= 0.5: return "part"
        return None
    def track_availability(self):
        if self.t < getattr(self, "_next_av", 0): return
        self._next_av = self.t + 60
        a = self.available_now()
        if not hasattr(self, "av_gaps"): self.av_gaps, self._av_since = [], self.t
        if a:
            if self.t - self._av_since > 0: self.av_gaps.append((self._av_since, self.t))
            self._av_since = self.t + 60

    # ---------- offers: rebalance pity (protection draws useful parts the player can afford within ~10 min first) ----------
    PITY_AFFORD = False
    def roll_offer(self, u):
        if not self.PITY_AFFORD: return super().roll_offer(u)
        band = self.band()
        pool = M.offer_pool(self.cat, band, self.luck(u))
        if self.dry >= sim.PROTECT_AFTER:
            use = {k: v for k, v in pool.items() if self.useful(k) and self.cat[k]["band"] <= band + 1}
            budget = self.snow + max(self.rate(), 1e-9) * 600
            cheap = {k: v for k, v in use.items() if self.cat[k]["price"] <= budget}
            if cheap: pool = cheap
            elif use: pool = use
        x = self.rng.random() * sum(pool.values())
        for pid, w in sorted(pool.items(), key=lambda kv: (M.RANK[self.cat[kv[0]]["rarity"]], self.cat[kv[0]]["band"], kv[0])):
            x -= w
            if x <= 0: break
        self.rolls += 1
        self.offer_log.append((self.t, pid, self.useful(pid), self.cat[pid]["price"] <= self.snow + max(self.rate(), 1e-9) * 600, pid in self.owned))
        if self.useful(pid): self.dry = 0; self.useful_waits.append(self.since_useful); self.since_useful = 0; self.useful_t.append(self.t)
        else: self.dry += 1; self.since_useful += 1
        return pid

    smart = False
    def step(self, dt=10):
        self.track_availability()
        self.earn(dt)
        while self.try_stage(): pass
        if self.smart:
            self.smart_buy()
        else:
            self.try_upgrades()
            self.try_eggs()
        self.garage_trip()
        self.do_jobs()

def run(cat, beh, seed, until="Portal", hours=14, rebirths=0, carry=None, policy=None, mode=0, accept=None, smart=False, pity=None):
    from evaluate import Biased
    p = Player2(cat, beh, seed, rebirths, carry, policy, accept, beh_name=beh)
    p.smart = smart
    if pity is not None: p.PITY_AFFORD = pity
    if mode: p.rng = Biased(seed, mode)
    trace, nxt = [], 0
    while until not in p.stages and p.t < hours * 3600:
        p.step()
        if p.t >= nxt:
            nxt += 60; trace.append((p.t, p.rate()))
    p.trace = trace
    return p
