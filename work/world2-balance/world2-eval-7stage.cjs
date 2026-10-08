// world2-eval-7stage.cjs (Claude 2026-10-03): progression-model estimate for the CURRENT 7-stage World 2 (Neon dropped).
// Uses the same formula model as world2-sim.cjs (MODEL ESTIMATES, not playtests). Writes eval-7stage.json + eval-7stage-log.txt.
const fs = require('fs'), path = require('path');
const simulate = require('./world2-sim.cjs');
const D = JSON.parse(fs.readFileSync(path.join(__dirname, 'config-from-disk.json'), 'utf8'));
const log = s => fs.appendFileSync(path.join(__dirname, 'eval-7stage-log.txt'), new Date().toISOString() + ' ' + s + '\n');
const EFF = 1.3757;
const IDS = ['Sakura', 'Candy', 'Atlantis', 'Toybox', 'Clockwork', 'Cloud', 'Cosmic'];
const COST = [0, 3e14, 1e16, 6e16, 3.6e17, 2.2e18, 1.3e19];          // StageConfig (live)
const HP = [60000, 150000, 300000, 600000, 1200000, 2400000, 4800000];  // SnowStages TileHP (live)
const SPP = [400000, 1200000, 3120000, 8112000, 21091200, 54837120, 142576512];
const LUCK = [4, 5, 6, 7, 8, 9, 12], BOOST = [2.0, 2.7, 3.9, 6.3, 12.0], CH = [45, 30, 15, 8, 2];
const UPF = {snow: 2.0, power: 1.6, luck: 1.0, size: 1.3}, PETG = 1.45, EGGF = 0.1, PORTAL = 150e12;
function w2def() {
  const st = [], eg = [], nd = [];
  IDS.forEach((id, k) => {
    st.push({Id: id, Cost: COST[k], TileHP: HP[k], SPP: SPP[k]});
    const own = k === 0 ? PORTAL : COST[k];
    eg.push({Id: id + 'Egg', Cost: EGGF * own, RequiredStage: id, Pets: CH.map((ch, j) => ({Chance: ch, Boost: BOOST[j] * Math.pow(PETG, k)}))});
    nd.push({Id: 'W2S' + k, Tree: 'Snow', Q: 9 + k, R: -1, Effect: ['SnowMult', 0.5, 'Mul'], Cost: UPF.snow * own, RequiredStage: id},
            {Id: 'W2P' + k, Tree: 'Snow', Q: 5 + k, R: -6 - k, Effect: ['PowerMult', 0.5, 'Mul'], Cost: UPF.power * own, RequiredStage: id},
            {Id: 'W2L' + k, Tree: 'Rolls', Q: 13 + k, R: -6 - k, Effect: ['LuckMult', LUCK[k], 'Add'], Cost: UPF.luck * own, RequiredStage: id},
            {Id: 'W2Z' + k, Tree: 'Misc', Q: -k, R: 3 + k, Effect: ['SizeMult', 0.06, 'Add'], Cost: UPF.size * own, RequiredStage: id});
  });
  return {stages: st, eggs: eg, nodes: nd};
}
const report = {};
for (const [prof, rew] of [['engaged', true], ['engaged', false], ['casual', true], ['casual', false]]) {
  const key = prof + (rew ? '+rewards' : '-rewards');
  const r = simulate(D, {eff: EFF, profile: prof, rewards: rew, seeds: [1, 2, 3, 4], maxHours: 30, w2: w2def()});
  report[key] = {avg: r.avg, inc: r.inc};
  log(key + ' ' + JSON.stringify(Object.fromEntries(Object.entries(r.avg).map(([k, v]) => [k, Math.round(v)]))));
}
fs.writeFileSync(path.join(__dirname, 'eval-7stage.json'), JSON.stringify({EFF, IDS, COST, HP, SPP, report, done: new Date().toISOString()}, null, 1));
log('DONE');
