const fs = require('fs');
const base = JSON.parse(fs.readFileSync('work/baseline.json','utf8'));
const variant=process.argv[2]||'baseline';
const d=variant==='baseline'?base:JSON.parse(fs.readFileSync('work/proposed.json','utf8'));
const order=['Starter','Desert','Cursed','Crystal','Retro','Jungle','AbsoluteZero','Portal'];
const stageCosts=d.stageCosts||[0,250,5000,150000,5e6,15e7,5e9,25e10];
const dirs=[[1,0],[-1,0],[0,1],[0,-1],[1,-1],[-1,1]];
const nodes=d.trees.flatMap(t=>t.Nodes.map(n=>({...n,tree:t.Id})));
const items=d.items;
function rng(seed){return()=>{seed|=0;seed=seed+0x6D2B79F5|0;let t=Math.imul(seed^seed>>>15,1|seed);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296}}
function run(seed,mode='fast',active=1){
 const r=rng(seed);let snow=0,stage=0,nextRoll=0,nextBuy=0,petSpend=0,earned=0;
 const counts=items.map(()=>0),pets=[],owned=new Set(),times=Array(8).fill(null);times[0]=0;
 let stats={...d.base},equip=[],power=0,luck=1, rate=0;
 function recalc(){
  stats={...d.base};const mults={};
  for(const n of nodes)if(owned.has(n.Id)){const [k,v,type]=n.Effect;if(type==='Mul')mults[k]=(mults[k]||1)*(1+v);else stats[k]=(stats[k]||0)+v;}
  for(const k in mults)stats[k]*=mults[k];
  for(const k in d.limits)stats[k]=Math.max(d.limits[k][0],Math.min(d.limits[k][1],stats[k]));
  equip=[];for(let i=items.length-1;i>=0&&equip.length<stats.ShovelSlots;i--)for(let j=0;j<counts[i]&&equip.length<stats.ShovelSlots;j++)equip.push(i);
  power=equip.reduce((s,i)=>s+Math.max(1,Math.floor(items[i].Chance**(d.powerExp||.42))),0)*stats.PowerMult;
  luck=Math.max(1,equip.reduce((s,i)=>s+items[i].Chance**(d.luckExp||.4),0))*stats.LuckMult;
  const f=d.stages[order[Math.min(stage,6)]];
  // Average fresh-tile contacts while moving; constrain by clearable layers and movement throughput.
  const hitsPerArm=8*stats.SpinMult*stats.ReachMult**2;
  const phases=Math.min(38*stats.ReachMult*(stats.WalkSpeed/16), hitsPerArm*power/f.TileHP);
  const petMult=1+(stats.PetBoostMult||1)*pets.sort((a,b)=>b-a).slice(0,stats.PetSlots).reduce((a,b)=>a+b,0);
  rate=phases*f.SnowPerPhase*stats.SnowMult*petMult*active;
 }
 function roll(){for(let i=items.length-1;i>=0;i--)if(r()<Math.min(1,luck/items[i].Chance))return i;return 0;}
 recalc();
 for(let t=0;t<8*3600;t++){
  if(t>=nextRoll){counts[roll()]++;if(r()<stats.DoubleRollChance)counts[roll()]++;recalc();nextRoll=t+(mode==='normal'?3.8*stats.RollAnimScale+.35:Math.max(1.05+.7*stats.RollAnimScale,(d.rollCooldown||.9)*stats.RollAnimScale+.1));}
  snow+=rate;earned+=rate;
  if(stage<7&&snow>=stageCosts[stage+1]){snow-=stageCosts[++stage];times[stage]=t/60;recalc();if(stage===7)break;}
  if(t>=nextBuy){
   nextBuy=t+5;
   const available=nodes.filter(n=>!owned.has(n.Id)&&order.indexOf(n.RequiredStage||'Starter')<=stage&&(n.Center||nodes.some(nb=>nb.tree===n.tree&&owned.has(nb.Id)&&dirs.some(([q,z])=>nb.Q===n.Q+q&&nb.R===n.R+z))));
   const affordable=available.filter(n=>n.Cost<=snow&&n.Cost<stageCosts[Math.min(stage+1,7)]*.28).sort((a,b)=>a.Cost-b.Cost);
   if(affordable[0]){snow-=affordable[0].Cost;owned.add(affordable[0].Id);recalc();}
   // Hatch occasionally while preserving most income for upgrades and stages.
   const egg=d.eggs.filter(e=>order.indexOf(e.RequiredStage||({SnowyEgg:'Starter',DesertEgg:'Desert',CursedEgg:'Cursed',CrystalEgg:'Crystal'})[e.Id])<=stage).sort((a,b)=>b.Cost-a.Cost)[0];
   if(egg&&snow>=egg.Cost*4&&petSpend<earned*.12&&pets.length<60){snow-=egg.Cost;petSpend+=egg.Cost;let q=r()*100;for(const p of egg.Pets){q-=p.Chance;if(q<=0){pets.push(p.Boost);break;}}recalc();}
  }
 }
 return {times,upgrades:owned.size,best:Math.max(...equip),luck,rate};
}
const results={};for(const [mode,activity]of[['fast',1],['normal',.7],['fast',1.4]]){
const runs=Array.from({length:80},(_,i)=>run(i+441,mode,activity));
const key=mode+'_'+activity;results[key]={stages:order.map((s,j)=>{let a=runs.map(r=>r.times[j]??480).sort((a,b)=>a-b);return {stage:s,p10:Math.round(a[8]),median:Math.round(a[40]),p90:Math.round(a[71])}}),finished:runs.filter(r=>r.times[7]!==null).length,upgrades:Math.round(runs.reduce((s,r)=>s+r.upgrades,0)/runs.length),best:runs[Math.floor(runs.length/2)].best};}
console.log(JSON.stringify(results,null,2));
fs.writeFileSync('work/simulation-'+variant+'.json',JSON.stringify(results,null,2));


