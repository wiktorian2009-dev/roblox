const fs=require('fs');
const d=JSON.parse(fs.readFileSync('work/baseline.json','utf8'));
const order=['Starter','Desert','Cursed','Crystal','Retro','Jungle','AbsoluteZero','Portal'];
d.powerExp=.42;d.luckExp=.33;d.rollCooldown=2.4;
d.stageCosts=[0,20000,2000000,75000000,3000000000,75000000000,1000000000000,12000000000000];
// Explicit progression tiers replace costs based on visual hex distance.
const budgets=[75,5000,150000,7000000,300000000,16000000000,600000000000];
const distance=n=>Math.max(Math.abs(n.Q),Math.abs(n.R),Math.abs(n.Q+n.R));
for(const t of d.trees)for(const n of t.Nodes){let tier=Math.max(0,distance(n)-1);if(/Third|Equip1/.test(n.Id))tier=3;if(/Equip2|Ultra|Blizzard/.test(n.Id))tier=4;n.RequiredStage=order[tier];n.Cost=Math.round(budgets[tier]*(n.Center?.5:1+(Math.abs(n.Q*3+n.R)%4)*.3)*(/Third|Equip/.test(n.Id)?3:1));}
const extras={
 Snow:[['Packed Powder','SnowMult',.15,'Mul'],['Snow Sacks','SnowMult',.15,'Mul'],['Deep Cut','PowerMult',.15,'Mul'],['Wide Sweep','ReachMult',.05],['Frost Fortune','SnowMult',.15,'Mul'],['Ice Breaker','PowerMult',.15,'Mul'],['Swift Sweep','SpinMult',.05],['Crystal Cache','SnowMult',.15,'Mul'],['Crystal Edge','PowerMult',.15,'Mul'],['Retro Riches','SnowMult',.15,'Mul'],['Pixel Power','PowerMult',.15,'Mul'],['Jungle Haul','SnowMult',.15,'Mul'],['Long Sweep','ReachMult',.05],['Polar Power','PowerMult',.15,'Mul'],['Frozen Fortune','SnowMult',.15,'Mul'],['Arctic Spin','SpinMult',.05],['Snow Mastery','SnowMult',.15,'Mul']],
 Rolls:[['Lucky Flakes','LuckMult',.15,'Mul'],['Lucky Streak','LuckMult',.15,'Mul'],['Twin Dice','DoubleRollChance',.025],['Sand Charm','LuckMult',.15,'Mul'],['Quick Hands','RollAnimScale',-.025],['Cursed Charm','LuckMult',.15,'Mul'],['Fortune Finder','LuckMult',.15,'Mul'],['Gem Fortune','LuckMult',.15,'Mul'],['Double Gems','DoubleRollChance',.025],['Pixel Luck','LuckMult',.15,'Mul'],['Retro Fortune','LuckMult',.15,'Mul'],['Twin Pixels','DoubleRollChance',.025],['Jungle Charm','LuckMult',.15,'Mul'],['Fortune Trail','LuckMult',.15,'Mul'],['Frost Luck','LuckMult',.15,'Mul'],['Swift Dice','RollAnimScale',-.025],['Twin Frost','DoubleRollChance',.025],['Fortune Mastery','LuckMult',.15,'Mul']],
 Misc:[['Pet Treats','PetBoostMult',.1],['Warm Boots','WalkSpeed',1],['Egg Coupons','EggDiscount',.025],['Pet Training','PetBoostMult',.1],['Sandy Steps','WalkSpeed',1],['Egg Savings','EggDiscount',.025],['Pet Bond','PetBoostMult',.1],['Trail Boots','WalkSpeed',1],['Team Spirit','FriendBoost',.025],['Gem Treats','PetBoostMult',.1],['Crystal Steps','WalkSpeed',1],['Egg Vouchers','EggDiscount',.025],['Pixel Treats','PetBoostMult',.1],['Retro Steps','WalkSpeed',1],['Egg Club','EggDiscount',.025],['Jungle Treats','PetBoostMult',.1],['Explorer Boots','WalkSpeed',1],['Teamwork','FriendBoost',.025],['Frost Treats','PetBoostMult',.1],['Arctic Boots','WalkSpeed',1],['Pet Mastery','PetBoostMult',.1]]
};
const suffix={SnowMult:'snow',PowerMult:'shovel damage',LuckMult:'luck',ReachMult:'reach',SpinMult:'spin speed',RollAnimScale:'roll time',DoubleRollChance:'bonus roll chance',EggDiscount:'egg price',PetBoostMult:'pet snow bonuses',FriendBoost:'snow & luck per friend',WalkSpeed:'walk speed'};
const dirs=[[1,0],[-1,0],[0,1],[0,-1],[1,-1],[-1,1]];
for(const t of d.trees){
 const used=new Set(t.Nodes.map(n=>n.Q+','+n.R));
 for(let i=0;i<extras[t.Id].length;i++){
  const occupied=[...used].map(s=>s.split(',').map(Number));let candidates=new Map();
  for(const [q,r]of occupied)for(const [x,z]of dirs){const Q=q+x,R=r+z,key=Q+','+R;if(!used.has(key))candidates.set(key,{Q,R});}
  const pos=[...candidates.values()].sort((a,b)=>distance(a)-distance(b)||a.R-b.R||a.Q-b.Q)[0];used.add(pos.Q+','+pos.R);
  const [Name,stat,v,kind]=extras[t.Id][i],tier=Math.min(6,1+Math.floor(i*6/extras[t.Id].length));
  const Text=kind==='Mul'?`x${(1+v).toFixed(2)} ${suffix[stat]}`:stat==='WalkSpeed'?`+${v} walk speed`:`${v>0?'+':''}${+(v*100).toFixed(1)}% ${suffix[stat]}`;
  t.Nodes.push({Id:t.Id[0]+'_Expansion'+(i+1),Name,...pos,Effect:[stat,v,...(kind?[kind]:[])],Text,RequiredStage:order[tier],Cost:Math.round(budgets[tier]*(.8+(i%4)*.35))});
 }
}
d.base.PetBoostMult=1;
d.limits={...d.limits,RollAnimScale:[.6,1],ReachMult:[1,1.5],SpinMult:[1,1.6],WalkSpeed:[16,40],PetBoostMult:[1,2],FriendBoost:[0,.2]};
for(const egg of d.eggs){egg.RequiredStage={SnowyEgg:'Starter',DesertEgg:'Desert',CursedEgg:'Cursed',CrystalEgg:'Crystal'}[egg.Id];egg.Cost={SnowyEgg:450,DesertEgg:12000,CursedEgg:300000,CrystalEgg:8000000}[egg.Id];}
fs.writeFileSync('work/proposed.json',JSON.stringify(d,null,2));
console.log(d.trees.map(t=>({tree:t.Id,tiles:t.Nodes.length}))); 



