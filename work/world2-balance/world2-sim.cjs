// world2-sim.cjs (Claude 2026-10-02): progression model, World 1 + World 2, from configs mirrored in game/src.
// A MODEL, not a playtest. Formulas follow SnowFieldService/PetConfig/UpgradeConfig/Balance; quest/daily effects are approximations.
const fs = require('fs');
function simulate(D, O) {
const W2 = O.w2 || null;                       // {stages:[{Id,Cost,TileHP,SPP}], eggs:[...], nodes:[...]}
let stages = D.stages.map(s => ({...s, ...(D.fields[s.Id] || {})}));
let eggs = D.eggs.slice(), trees = JSON.parse(JSON.stringify(D.trees));
if (W2) {
  stages = stages.filter(s => !W2.stages.some(w => w.Id === s.Id)).concat(W2.stages);
  eggs = eggs.filter(e => !W2.eggs.some(w => w.Id === e.Id)).concat(W2.eggs);
  const ids = new Set(W2.nodes.map(n => n.Id));
  for (const t of trees) t.Nodes = t.Nodes.filter(n => !ids.has(n.Id));
  for (const n of W2.nodes) trees.find(t => t.Id === n.Tree).Nodes.push(n);
}
const idx = {}; stages.forEach((s, i) => idx[s.Id] = i);
const nodes = []; for (const t of trees) for (const n of t.Nodes) nodes.push({...n, tree: t.Id, cost: n.Cost != null ? n.Cost : Math.floor(t.BaseCost * Math.pow(t.Growth, Math.max(Math.abs(n.Q), Math.abs(n.R), Math.abs(n.Q + n.R))) * (n.CostMult || 1) + .5)});
const pos = {}; for (const n of nodes) pos[n.tree + ':' + n.Q + ',' + n.R] = n;
const DIRS = [[1,0],[-1,0],[0,1],[0,-1],[1,-1],[-1,1]];
const items = D.items, PEXP = 0.63;
const engaged = (O.profile || 'engaged') === 'engaged', rewards = O.rewards !== false;
const ACTIVE = engaged ? 0.9 : 0.55, BUY_EVERY = engaged ? 5 : 25, PAYBACK = engaged ? 900 : 360, PET_SHARE = engaged ? .15 : .08;
function rng(seed) { return () => { seed |= 0; seed = seed + 0x6D2B79F5 | 0; let t = Math.imul(seed ^ seed >>> 15, 1 | seed); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; }; }
function run(seed) {
  const r = rng(seed);
  let snow = 0, earned = 0, stage = 0, rolls = 0, hatches = 0, petSpend = 0, treasures = 0, quests = 0;
  const owned = new Set(), counts = new Map(), pets = [], petNames = new Set(), times = {Starter: 0}, incomeAt = {};
  let st = {}, equip = [], income = 0, fieldStage = 0;
  const open = i => i <= stage || (stages[i] && stages[i].Cost === 0 && i - 1 <= stage);
  function stats() {
    const s = {...D.base}, mul = {};
    for (const n of nodes) if (owned.has(n.Id) && n.Effect) { const [k, v, ty] = n.Effect; if (ty === 'Mul') mul[k] = (mul[k] || 1) * (1 + v); else s[k] = (s[k] || 0) + v; }
    for (const k in mul) s[k] = (s[k] || 1) * mul[k];
    for (const k in D.limits) if (s[k] != null) s[k] = Math.min(D.limits[k][1], Math.max(D.limits[k][0], s[k]));
    return s;
  }
  function ach(t) {
    let sn = 0, lk = 0;
    if (earned >= 1e5) sn += .02; if (earned >= 1e9) sn += .03; if (earned >= 1e12) sn += .05;
    if (hatches >= 10) sn += .02; if (hatches >= 100) sn += .03; if (treasures >= 10) sn += .02; if (treasures >= 100) sn += .03;
    if (petNames.size >= 10) sn += .02; if (petNames.size >= 25) sn += .03;
    if (rolls >= 100) lk += .02; if (rolls >= 1000) lk += .03; if (rolls >= 5000) lk += .05;
    const found = new Set([...counts.keys()].map(k => k.split('|')[0])).size; if (found >= 10) lk += .02; if (found >= 20) lk += .03;
    if (times.Sakura != null) { sn += .05; lk += .05; }
    if (quests >= 10) lk += .02; if (quests >= 50) lk += .03;
    return [1 + sn, 1 + lk];
  }
  function boosts(t) {
    const cyc = Math.floor(t / 750), ph = t % 750, ev = ['S','L','S','L','S','L','A'][cyc % 7];
    let es = 1, el = 1;
    if (ev === 'S' && ph < 180) es = 2; if (ev === 'L' && ph < 180) el = 2; if (ev === 'A' && ph < 120) { es = 2; el = 2; }
    let ps = 1, pl = 1;
    if (rewards) { const q = t % 1980; if (q < 480) ps = 2; if (q >= 990 && q < 1470) pl = 2; }
    return [es * ps, el * pl];
  }
  function recalc() {
    st = stats();
    const vars = [];
    for (const [k, c] of counts) { if (c <= 0) continue; const [i, sh, gi] = k.split('|').map(Number); const it = items[i];
      const p = (it.Power || Math.max(1, Math.floor(Math.pow(it.Chance, PEXP)))) * (sh ? 3 : 1); vars.push({p, gi, val: p * (gi ? 1.6 : 1), c}); }
    vars.sort((a, b) => b.val - a.val); equip = [];
    for (const v of vars) for (let j = 0; j < v.c && equip.length < st.ShovelSlots; j++) equip.push(v);
  }
  function incomeFor(si, t) {
    const f = stages[si]; if (!f || !f.TileHP) return 0;
    const [as, al] = ach(t), [bs] = boosts(t);
    let layers = 0, rmax = 0;
    for (const a of equip) {
      const rr = 1.6 + (5.3 * st.ReachMult * st.SizeMult - 1.6) * (a.gi ? 2 : 1); rmax = Math.max(rmax, rr);
      const hits = 7 * st.SpinMult * (rr * rr - 1) / 18;
      const dmg = (a.p + (st.PowerBonus || 0)) * st.PowerMult;
      layers += hits * Math.min(3, dmg / f.TileHP);
    }
    const cap = 0.5 * rmax * st.WalkSpeed;
    const top = pets.slice().sort((a, b) => b - a).slice(0, st.PetSlots).reduce((a, b) => a + b, 0);
    const petMult = 1 + st.PetBoostMult * top;
    return Math.min(cap, layers) * f.SPP * st.SnowMult * as * bs * petMult * 1.06 * ACTIVE * (O.eff || 1);
  }
  function roll(t) {
    const [, al] = ach(t), [, bl] = boosts(t);
    let luck = st.LuckMult * al * bl;
    rolls++;
    if (st.GoldenEvery > 0 && rolls % Math.round(st.GoldenEvery) === 0) luck *= st.GoldenLuck || 3;
    if (st.RainbowEvery > 0 && rolls % Math.round(st.RainbowEvery) === 0) luck *= st.RainbowLuck || 10;
    let got = 0; for (let i = items.length - 1; i >= 0; i--) if (r() < Math.min(1, luck / items[i].Chance)) { got = i; break; }
    const k = got + '|' + (r() < .1 ? 1 : 0) + '|' + (r() < .2 ? 1 : 0); counts.set(k, (counts.get(k) || 0) + 1);
  }
  recalc(); counts.set('0|0|0', 1); recalc();
  let nextRoll = 0, nextBuy = 0; const end = (O.maxHours || 14) * 3600, last = stages.length - 1;
  const STEP = 2;
  for (let t = 0; t < end; t += STEP) {
    if (t >= nextRoll) { roll(t); if (r() < st.DoubleRollChance) roll(t); recalc(); nextRoll = t + 2.4 * st.RollAnimScale; }
    if (t % 30 === 0) { let best = 0, bi = 0; for (let i = 0; i < stages.length; i++) if (open(i)) { const v = incomeFor(i, t); if (v > best) { best = v; bi = i; } } fieldStage = bi; }
    income = incomeFor(fieldStage, t);
    snow += income * STEP; earned += income * STEP;
    treasures += income > 0 ? STEP * 0.004 : 0;
    if (rewards && t % 1980 === 0 && t > 0) quests += 3;
    while (stage < last && snow >= stages[stage + 1].Cost && stages[stage + 1].Cost > 0) { snow -= stages[++stage].Cost; times[stages[stage].Id] = t / 60; incomeAt[stages[stage].Id] = income; }
    while (stage < last && stages[stage + 1].Cost === 0) { stage++; times[stages[stage].Id] = t / 60; incomeAt[stages[stage].Id] = income; }
    if (stage === last && times.__done == null) { times.__done = t / 60; if (!O.continueAfter) break; }
    if (t >= nextBuy) {
      nextBuy = t + BUY_EVERY;
      const nextCost = stage < last ? stages[stage + 1].Cost : Infinity;
      for (let k = 0; k < 3; k++) {
        const av = nodes.filter(n => !owned.has(n.Id) && idx[n.RequiredStage] != null && open(idx[n.RequiredStage]) && n.cost <= snow &&
          (n.Center || DIRS.some(([a, b]) => { const nb = pos[n.tree + ':' + (n.Q + a) + ',' + (n.R + b)]; return nb && owned.has(nb.Id); })));
        const saving = nextCost <= income * 600;   // next stage within ~20 min of income: save for it, only small upgrades
        const ok = av.filter(n => saving ? n.cost <= 0.1 * nextCost : (n.cost <= 0.3 * nextCost || n.cost <= PAYBACK * income)).sort((a, b) => a.cost - b.cost);
        if (!ok.length) break; snow -= ok[0].cost; owned.add(ok[0].Id); recalc();
      }
      const egg = eggs.filter(e => idx[e.RequiredStage] != null && open(idx[e.RequiredStage])).sort((a, b) => b.Cost - a.Cost)[0];
      if (egg && snow >= egg.Cost * 3 && petSpend < earned * PET_SHARE && !(stage < last && nextCost <= income * 600 && snow < nextCost)) {
        snow -= egg.Cost; petSpend += egg.Cost; hatches++; let q = r() * 100;
        for (const p of egg.Pets) { q -= p.Chance; if (q <= 0) { pets.push(p.Boost); petNames.add(egg.Id + p.Boost); break; } }
        if (pets.length > 40) { pets.sort((a, b) => b - a); pets.length = 20; }
      }
    }
  }
  return {times, incomeAt, owned: owned.size, pets: pets.length, bestPets: pets.slice().sort((a, b) => b - a).slice(0, 5), power: equip.map(e => e.p)};
}
const seeds = O.seeds || [1, 2, 3];
const res = seeds.map(run);
const avg = {}; for (const s of stages) { const v = res.map(x => x.times[s.Id]).filter(x => x != null); if (v.length === res.length) avg[s.Id] = v.reduce((a, b) => a + b, 0) / v.length; }
const inc = {}; for (const s of stages) { const v = res.map(x => x.incomeAt[s.Id]).filter(x => x != null); if (v.length) inc[s.Id] = v.reduce((a, b) => a + b, 0) / v.length; }
return {avg, inc, sample: {owned: res[0].owned, pets: res[0].pets, bestPets: res[0].bestPets, power: res[0].power}};
}
module.exports = simulate;
if (require.main === module) {
  const D = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
  const O = JSON.parse(process.argv[3] || '{}');
  console.log(JSON.stringify(simulate(D, O)));
}
