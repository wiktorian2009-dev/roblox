// world2-eval.cjs (Claude 2026-10-03): evaluates DESIGNED World 2 price schedules (geometric) with the progression model.
// The solver approach was dropped: cheap stages made the model player skip upgrades, which kept income flat (self-fulfilling).
const fs = require('fs'), path = require('path');
const simulate = require('./world2-sim.cjs');
const D = JSON.parse(fs.readFileSync(path.join(__dirname, 'config-from-disk.json'), 'utf8'));
const log = s => fs.appendFileSync(path.join(__dirname, 'eval-log.txt'), new Date().toISOString() + ' ' + s + '\n');
const EFF = 1.3757, W2IDS = ['Sakura', 'Candy', 'Atlantis', 'Toybox', 'Clockwork', 'Cloud', 'Neon', 'Cosmic'];
const HP = [60000, 150000], SPP = [400000, 1200000];
for (let k = 2; k < 8; k++) { HP.push(Math.round(HP[k - 1] * 2.0)); SPP.push(Math.round(SPP[k - 1] * 2.6)); }
const PORTAL = 150e12, LUCK = [4, 5, 6, 7, 8, 9, 10, 12], BOOST = [2.0, 2.7, 3.9, 6.3, 12.0], CH = [45, 30, 15, 8, 2];
const UPF = {snow: 2.0, power: 1.6, luck: 1.0, size: 1.3}, PETG = 1.45, EGGF = 0.1;
function w2def(costs) {
  const st = [], eg = [], nd = [];
  W2IDS.forEach((id, k) => {
    const c = costs[k]; st.push({Id: id, Cost: c, TileHP: HP[k], SPP: SPP[k]});
    const own = k === 0 ? PORTAL : c;
    eg.push({Id: id + 'Egg', Cost: EGGF * own, RequiredStage: id, Pets: CH.map((ch, j) => ({Chance: ch, Boost: BOOST[j] * Math.pow(PETG, k)}))});
    nd.push({Id: 'W2S' + k, Tree: 'Snow', Q: 9 + k, R: -1, Effect: ['SnowMult', 0.5, 'Mul'], Cost: UPF.snow * own, RequiredStage: id},
            {Id: 'W2P' + k, Tree: 'Snow', Q: 5 + k, R: -6 - k, Effect: ['PowerMult', 0.5, 'Mul'], Cost: UPF.power * own, RequiredStage: id},
            {Id: 'W2L' + k, Tree: 'Rolls', Q: 13 + k, R: -6 - k, Effect: ['LuckMult', LUCK[k], 'Add'], Cost: UPF.luck * own, RequiredStage: id},
            {Id: 'W2Z' + k, Tree: 'Misc', Q: -k, R: 3 + k, Effect: ['SizeMult', 0.06, 'Add'], Cost: UPF.size * own, RequiredStage: id});
  });
  return {stages: st, eggs: eg, nodes: nd};
}
const sched = (c1, g) => [0].concat([0, 1, 2, 3, 4, 5, 6].map(i => Number((c1 * Math.pow(g, i)).toPrecision(2))));
const res = [];
for (const c1 of [3e14, 6e14, 1.2e15]) for (const g of [2.5, 3.2, 4]) {
  const costs = sched(c1, g);
  const a = simulate(D, {eff: EFF, profile: 'engaged', rewards: true, seeds: [1, 2], maxHours: 14, w2: w2def(costs)}).avg;
  const gaps = W2IDS.slice(1).map((id, i) => a[id] != null && a[W2IDS[i]] != null ? Math.round(a[id] - a[W2IDS[i]]) : null);
  const tot = a.Cosmic != null ? (a.Cosmic - a.Portal) / 60 : null;
  res.push({c1, g, gaps, tot, portal: a.Portal}); log(JSON.stringify(res[res.length - 1]));
}
const ok = res.filter(r => r.tot != null);
const pick = (ok.length ? ok : res).sort((x, y) => Math.abs((x.tot ?? 99) - 3.0) + Math.abs((x.gaps[0] ?? 99) - 22) / 30 - Math.abs((y.tot ?? 99) - 3.0) - Math.abs((y.gaps[0] ?? 99) - 22) / 30)[0];
const costs = sched(pick.c1, pick.g); const report = {};
for (const [prof, rew] of [['engaged', true], ['engaged', false], ['casual', true], ['casual', false]]) {
  const a = simulate(D, {eff: EFF, profile: prof, rewards: rew, seeds: [1, 2, 3, 4], maxHours: 20, w2: w2def(costs)}).avg;
  report[prof + (rew ? '+rewards' : '-rewards')] = {Portal_min: Math.round(a.Portal || -1),
    W2_gaps_min: W2IDS.slice(1).map((id, i) => a[id] != null && a[W2IDS[i]] != null ? Math.round(a[id] - a[W2IDS[i]]) : null),
    W2_total_h: a.Cosmic != null ? +((a.Cosmic - a.Portal) / 60).toFixed(2) : null};
  log(prof + ' ' + rew + ' ' + JSON.stringify(report[prof + (rew ? '+rewards' : '-rewards')]));
}
fs.writeFileSync(path.join(__dirname, 'chosen.json'), JSON.stringify({EFF, pick, costs: Object.fromEntries(W2IDS.map((id, k) => [id, costs[k]])),
  HP: Object.fromEntries(W2IDS.map((id, k) => [id, HP[k]])), SPP: Object.fromEntries(W2IDS.map((id, k) => [id, SPP[k]])), petGrowth: PETG, eggCostFactor: EGGF,
  luck: LUCK, upgradeCostFactors: UPF, grid: res, report, done: new Date().toISOString()}, null, 1));
log('DONE');
