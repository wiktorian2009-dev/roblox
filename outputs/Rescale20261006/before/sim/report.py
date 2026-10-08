# report.py - per-stage affordability table + cadence metrics for a catalog/economy (fixed seeds). Model estimates, not playtests.
# usage: python report.py <tag> [n]   (tag 'before' = live economy; other tags come from rebalance.py)
import json, math, os, statistics, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gamedata as G, model as M, sim, sim2, jobs as J

STAGES = [s[0] for s in G.STAGES if s[0] != "Portal"]   # Sakura stands for the Portal/World 2 arrival
class _Mid:   # deterministic stand-in for the clear-time jitter (mean of uniform(0.85, 1.25))
    def uniform(self, a, b): return (a + b) / 2
MEANINGFUL = 1.10   # a purchase that raises income by >= 10% counts as a meaningful improvement

def pct(v, q):
    v = sorted(v); return v[min(len(v) - 1, int(q * len(v)))] if v else None

def restore(cat, state, beh="efficient", seed=1, policy=None):
    p = sim2.Player2(cat, beh, seed, policy=policy)
    owned, build, ups, pets, stages, snow, reb = state
    p.owned, p.build, p.ups, p.pets, p.stages, p.snow, p.rebirths = dict(owned), dict(build), set(ups), dict(pets), set(stages), snow, reb
    p.dirty = True
    return p

def analyse(cat, state, policy):
    p = restore(cat, state, policy=policy)
    inc = p.rate()
    band = p.band()
    u, mo = p.mods()
    st = M.stats_for(cat, p.build, mo)
    stage = p.cur_stage
    # cheapest meaningful part the offer pool can show
    best_part = None
    for pid, d in cat.items():
        if d["role"] == "S" or pid in p.owned or d["band"] > band + 3: continue
        g = p.gain_of(pid)
        if g >= MEANINGFUL and (best_part is None or d["price"] < best_part[1]): best_part = (pid, d["price"], g)
    best_up = None
    for uu in sim.available_upgrades(p.ups):
        if uu["Stat"] not in sim.INCOME_STATS: continue
        ups = set(p.ups); ups.add(uu["Id"])
        g = p.income(ups=ups)[0] / max(inc, 1e-9)
        if g >= MEANINGFUL and (best_up is None or uu["C"] < best_up[1]): best_up = (uu["Id"], uu["C"], g)
    # chance that one roll shows a useful part affordable within 10 minutes of income
    pool = M.offer_pool(cat, band, p.luck(u))
    good = sum(w for pid, w in pool.items() if p.useful(pid) and cat[pid]["price"] <= inc * 600)
    useful = sum(w for pid, w in pool.items() if p.useful(pid))
    ns = p.next_stage()
    gate = sim.STAGE_COST.get(ns, 0) if ns else 0
    hp, spp, regrow = G.STAGE_FIELD[stage]
    hp *= M.HP_MULT.get(stage, 1.0)
    pw, cov, rc, _ = M.field_rates(st, stage)
    rate_layers = M.layer_rate(st, stage)
    bonus = policy.bonus(inc, st, "Road", sim2.JOB_TILE_SHARE)
    tc = J.clear_seconds(st, "Road", _Mid()) if policy.mode == "target" else 70.0   # expected Road clear time (same estimate the reward uses)
    job_mult = (inc * sim2.JOB_TILE_SHARE * tc + bonus) / (inc * (tc + policy.travel + policy.overhead))
    return {"income_per_min": inc * 60, "stage": stage, "band": band,
            "build": "/".join(cat[p.build[s]]["name"] for s in ("Blade", "Engine", "Gear", "Body") if s in p.build),
            "tileHP": hp, "tough": G.TOUGH[stage], "layers_s": rate_layers, "limit": "power" if pw < cov else "coverage",
            "cheapPart": best_part and {"id": best_part[0], "name": cat[best_part[0]]["name"], "price": best_part[1], "gain": round(best_part[2], 2), "minutes": round(best_part[1] / inc / 60, 1)},
            "cheapUpgrade": best_up and {"id": best_up[0], "price": best_up[1], "gain": round(best_up[2], 2), "minutes": round(best_up[1] / inc / 60, 1)},
            "rollsForAffordableUseful": round(1 / good, 1) if good > 0 else None, "rollsForUseful": round(1 / useful, 1) if useful > 0 else None,
            "nextGate": ns, "gateCost": gate, "gateMinutes": round(gate / inc / 60, 1) if gate else None,
            "jobBonus": bonus, "jobVsCollecting": round(job_mult, 2)}

def cadence(p, until_t):
    """meaningful improvements (single purchase >= +10% income) and the +15% income-trace metric used in the earlier report"""
    ts = [t for t, kind, x, g in p.improvements if g >= MEANINGFUL and t <= until_t]
    gaps = [(b - a) / 60 for a, b in zip([0.0] + ts, ts + [until_t])]
    tr, ev, last = p.trace, [], None
    for t, r in tr:
        if t > until_t: break
        if last is None or r >= last * 1.15: ev.append(t); last = r
        else: last = max(last * 0.999, min(last, r))
    tgaps = [(b - a) / 60 for a, b in zip(ev, ev[1:])]
    return gaps, tgaps, ts

def run_set(cat, beh, n, policy, seed0=3000, until="Portal", mode=0, accept=None, rebirths=0, carry=None, hours=14, smart=False):
    return [sim2.run(cat, beh, seed0 + i, until=until, policy=policy, mode=mode, accept=accept, rebirths=rebirths,
                     carry=carry[i] if carry else None, hours=hours, smart=smart) for i in range(n)]

def stage_table(cat, players, policy):
    rows = {}
    for s in STAGES:
        arr = [p for p in players if s in p.snap and "arrive" in p.snap[s]]
        if len(arr) < len(players) / 2: continue
        arr.sort(key=lambda p: p.snap[s]["arrive"]["t"])
        mid = arr[len(arr) // 2]
        a = analyse(cat, mid.snap[s]["arrive"]["state"], policy)
        lv = mid.snap[s].get("leave")
        d = analyse(cat, lv["state"], policy) if lv else None
        ta = [p.snap[s]["arrive"]["t"] / 60 for p in arr]
        tl = [p.snap[s]["leave"]["t"] / 60 for p in arr if "leave" in p.snap[s]]
        # longest gap without a meaningful purchase while in this stage (median player of the set, and worst)
        g_in = []
        for p in arr:
            t0 = p.snap[s]["arrive"]["t"]; t1 = p.snap[s].get("leave", {}).get("t", p.t)
            ts = [t for t, k, x, g in p.improvements if g >= MEANINGFUL and t0 <= t <= t1]
            g_in.append(max([(b - a_) / 60 for a_, b in zip([t0] + ts, ts + [t1])] or [0]))
        rows[s] = {"arriveMin": {"median": round(statistics.median(ta), 1), "p90": round(pct(ta, .9), 1)},
                   "leaveMin": {"median": round(statistics.median(tl), 1), "p90": round(pct(tl, .9), 1)} if tl else None,
                   "entry": a, "developed": d,
                   "longestGapInStage": {"median": round(statistics.median(g_in), 1), "p90": round(pct(g_in, .9), 1)}}
    return rows

def summary(players, until="Portal"):
    out = {}
    w1 = [p.arrive[until] / 60 for p in players if until in p.arrive]
    out["world1_minutes"] = {"p10": round(pct(w1, .1)), "median": round(statistics.median(w1)), "p90": round(pct(w1, .9))} if w1 else None
    if any("Cosmic" in p.arrive for p in players):
        w2 = [(p.arrive["Cosmic"] - p.arrive["Portal"]) / 60 for p in players if "Cosmic" in p.arrive]
        out["world2_minutes"] = {"p10": round(pct(w2, .1)), "median": round(statistics.median(w2)), "p90": round(pct(w2, .9))}
    gaps, tg, firsts = [], [], []
    longest = []
    for p in players:
        end = p.arrive.get(until, p.t)
        g, t, ts = cadence(p, end)
        gaps += g; tg += t; longest.append(max(g) if g else 0)
        firsts.append(min([tt for tt, k, x, gg in p.improvements if k == "part"] or [1e9]) / 60)
    out["minutesBetweenMeaningful"] = {"median": round(statistics.median(gaps), 1), "p90": round(pct(gaps, .9), 1), "max": round(max(gaps), 1)}
    out["longestGapPerPlayer"] = {"median": round(statistics.median(longest), 1), "p90": round(pct(longest, .9), 1), "max": round(max(longest), 1)}
    out["trace15"] = {"median": round(statistics.median(tg), 1), "p90": round(pct(tg, .9), 1), "max": round(max(tg), 1)} if tg else None
    out["firstPartMinute"] = {"median": round(statistics.median(firsts), 1), "p90": round(pct(firsts, .9), 1)}
    parts = [sum(1 for e in p.events if e[1] == "part" and e[0] <= p.arrive.get(until, 1e9)) for p in players]
    out["partsBoughtW1"] = {"median": statistics.median(parts)}
    # availability: longest stretch (minutes, World 1) with no obtainable, affordable-within-10-min meaningful improvement
    av = []
    for p in players:
        end = p.arrive.get(until, p.t)
        gs = [(b - a) / 60 for a, b in getattr(p, "av_gaps", []) if a < end]
        av.append(max(gs) if gs else 0.0)
    out["longestUnavailable"] = {"median": round(statistics.median(av), 1), "p90": round(pct(av, .9), 1), "max": round(max(av), 1)}
    out["jobs"] = {"median": statistics.median(p.jobs_done for p in players),
                   "shareOfSnow": round(statistics.median(p.job_snow / max(p.earned, 1) for p in players), 3),
                   "shareOfTime": round(statistics.median(p.job_time / max(p.t, 1) for p in players), 3),
                   "payVsCollecting": round(statistics.median([r for p in players for r in p.job_ratios] or [0]), 2)}
    waits = [w for p in players for w in p.useful_waits]
    out["rollsBetweenUsefulOffers"] = {"median": statistics.median(waits), "p90": pct(waits, .9), "max": max(waits)} if waits else None
    return out
