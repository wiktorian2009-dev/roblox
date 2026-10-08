// world2-solve.cjs (Claude 2026-10-02): solves World 2 stage costs for target minutes per stage (engaged player, Rewards claimed),
// then reports engaged/casual x with/without Rewards. MODEL ESTIMATES, not playtests. Writes solved.json + solve-log.txt.
const fs = require('fs'), path = require('path');
const simulate = require('./world2-sim.cjs');
const D = JSON.parse(fs.readFileSync(path.join(__dirname, 'config-from-disk.json'), 'utf8'));
const log = s => fs.appendFileSync(path.join(__dirname, 'solve-log.txt'), new Date().toISOString() + ' ' + s + '\n');
const EFF = 1.3757;                 // calibration: engaged + Rewards reaches Portal ~3.5 h (documented World 1 design ~4 h)
const W2IDS = ['Sakura', 'Candy', 'Atlantis', 'Toybox', 'Clockwork', 'Cloud', 'Neon', 'Cosmic'];
const HP = [60000, 150000], SPP = [400000, 1200000];
for (let k = 2; k < 8; k++) { HP.push(Math.round(HP[k - 1] * 2.0)); SPP.push(Math.round(SPP[k - 1] * 2.6)); }   // snow per HP +30% per stage
const PORTAL = 150e12, LUCK = [4, 5, 6, 7, 8, 9, 10, 12], BOOST = [2.0, 2.7, 3.9, 6.3, 12.0], CH = [45, 30, 15, 8, 2];
const UPF = {snow: 3.0, power: 2.5, luck: 1.5, size: 2.0}, PETG = 1.45, EGGF = 0.1;
const GAPS = [22, 20, 22, 24, 26, 29, 32];
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
const sim = o => simulate(D, Object.assign({eff: EFF}, o));
const costs = [0, 1e40, 1e40, 1e40, 1e40, 1e40, 1e40, 1e40];
let target = sim({profile: 'engaged', rewards: true, seeds: [1, 2], maxHours: 8, w2: w2def(costs)}).avg.Portal;
log('Portal at ' + target.toFixed(1) + ' min');
let prev = PORTAL;
for (let k = 1; k < 8; k++) {
  target += GAPS[k - 1];
  let lo = k === 1 ? 1e13 : prev, hi = prev * 1e5;
  for (let it = 0; it < 17; it++) {
    const mid = Math.sqrt(lo * hi); const c = costs.slice(); c[k] = mid;
    const t = sim({profile: 'engaged', rewards: true, seeds: [1, 2], maxHours: (target + 45) / 60, w2: w2def(c)}).avg[W2IDS[k]];
    if (t == null || t > target) hi = mid; else lo = mid;
  }
  costs[k] = Number(Math.sqrt(lo * hi).toPrecision(2)); prev = costs[k];
  const real = sim({profile: 'engaged', rewards: true, seeds: [1, 2], maxHours: (target + 45) / 60, w2: w2def(costs)}).avg[W2IDS[k]];
  if (real != null) target = real;
  log(W2IDS[k] + ' cost ' + costs[k].toExponential(2) + ' reached ' + (real || -1).toFixed(1));
}
const report = {};
for (const [prof, rew] of [['engaged', true], ['engaged', false], ['casual', true], ['casual', false]]) {
  const a = sim({profile: prof, rewards: rew, seeds: [1, 2, 3, 4], maxHours: 18, w2: w2def(costs)}).avg;
  report[prof + (rew ? '+rewards' : '-rewards')] = {Portal_min: Math.round(a.Portal || -1),
    W2_gaps_min: W2IDS.slice(1).map((id, i) => a[id] != null && a[W2IDS[i]] != null ? Math.round(a[id] - a[W2IDS[i]]) : null),
    W2_total_h: a.Cosmic != null ? +((a.Cosmic - a.Portal) / 60).toFixed(2) : null};
  log(prof + ' ' + rew + ' ' + JSON.stringify(report[prof + (rew ? '+rewards' : '-rewards')]));
}
fs.writeFileSync(path.join(__dirname, 'solved.json'), JSON.stringify({EFF, costs: Object.fromEntries(W2IDS.map((id, k) => [id, costs[k]])),
  HP: Object.fromEntries(W2IDS.map((id, k) => [id, HP[k]])), SPP: Object.fromEntries(W2IDS.map((id, k) => [id, SPP[k]])),
  petGrowth: PETG, eggCostFactor: EGGF, luck: LUCK, upgradeCostFactors: UPF, gapsTarget: GAPS, report, done: new Date().toISOString()}, null, 1));
log('DONE');
