#!/usr/bin/env node
'use strict';
/*
 * check_layout.js - SOURCE-DERIVED layout checker (plain Node, no dependencies).
 *
 * WHAT THIS IS: it reads layout_model.json (numbers copied by hand out of the Luau sources, each with file:line + quote),
 * evaluates the UDim2 / constraint / dynamic-anchor maths for several viewports, and reports rectangles that overlap,
 * leave the screen or are too small to touch.
 * WHAT THIS IS NOT: it does not render Roblox, was not run in Studio, cannot see static Studio frames (those are listed as
 * "unknown" and excluded), and a clean result does NOT prove that input works or that the game looks right.
 *
 * usage: node check_layout.js [--section before|after|both] [--md FILE] [--model FILE] [--tol PX]
 *                              [--inset-desktop PX] [--inset-phone PX] [--gui-inset NAME=true|false] [--strict] [--quiet]
 *                              [--dump SCENARIO@VIEWPORT]   (print every visible rect of one scenario, then exit)
 * exit status: 1 when the checked section(s) contain counted overlaps. Default section is "both"; the status then follows the
 * AFTER section only (BEFORE overlaps are the known defects being fixed) unless --strict is given.
 */
const fs = require('fs');
const path = require('path');

// ------------------------------------------------------------------ args
const argv = process.argv.slice(2);
const opt = { section: 'both', md: null, model: path.join(__dirname, 'layout_model.json'), tol: 4, insetDesktop: 36, insetPhone: 58, guiInset: {}, strict: false, quiet: false, dump: null };
for (let i = 0; i < argv.length; i++) {
  const a = argv[i];
  const next = () => argv[++i];
  if (a === '--section') opt.section = next();
  else if (a === '--md') opt.md = next();
  else if (a === '--model') opt.model = next();
  else if (a === '--tol') opt.tol = Number(next());
  else if (a === '--inset-desktop') opt.insetDesktop = Number(next());
  else if (a === '--inset-phone') opt.insetPhone = Number(next());
  else if (a === '--gui-inset') { const [k, v] = next().split('='); opt.guiInset[k] = v === 'true'; }
  else if (a === '--strict') opt.strict = true;
  else if (a === '--quiet') opt.quiet = true;
  else if (a === '--dump') opt.dump = next(); // SCENARIO@VIEWPORT, e.g. driving@844x390
  else if (a === '-h' || a === '--help') { console.log(fs.readFileSync(__filename, 'utf8').split('*/')[0]); process.exit(0); }
  else { console.error('unknown argument ' + a); process.exit(2); }
}
const model = JSON.parse(fs.readFileSync(opt.model, 'utf8'));
const sections = opt.section === 'both' ? ['before', 'after'] : [opt.section];

// ------------------------------------------------------------------ helpers
const fl = Math.floor;
const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));
const r1 = (v) => Math.round(v * 10) / 10;
const fmtRect = (r) => `${r1(r.x)},${r1(r.y)} ${r1(r.w)}x${r1(r.h)}`;

function condOk(conds, ctx) {
  if (!conds || conds === true) return true;
  return conds.every((c) => c === 'touch' ? ctx.touch : c === 'desktop' ? !ctx.touch : c === 'small' ? ctx.small : c === 'notSmall' ? !ctx.small : false);
}

function guiRect(name, ctx) {
  const g = model.guis[name];
  const ignore = Object.prototype.hasOwnProperty.call(opt.guiInset, name) ? opt.guiInset[name] : g.ignoreInset;
  return ignore ? { x: 0, y: 0, w: ctx.W, h: ctx.H, s: 1 } : { x: 0, y: ctx.inset, w: ctx.W, h: ctx.H - ctx.inset, s: 1 };
}

// Roblox default jump button, from UILayout.jumpLeftTop's fallback (left/top) - ASSUMED, size from memory
function jumpFor(W, H) {
  if (Math.min(W, H) <= 500) return { left: W - 115, top: H - 90, size: 70 };
  return { left: W - 190, top: H - 210, size: 120 };
}

// ------------------------------------------------------------------ element evaluation
function applyWhen(el, ctx) {
  const e = Object.assign({}, el);
  for (const w of el.when || []) {
    if (!condOk(w.cond, ctx)) continue;
    Object.assign(e, w.set || {});
    if (w.rule) e.rule = w.rule;
  }
  return e;
}

function makeEngine(sectionName, ctx, scenario) {
  const els = model[sectionName].elements;
  const byId = {};
  for (const e of els) byId[e.id] = e;
  const memo = {};

  function isVisible(id) {
    const el = byId[id];
    if (!el) return false;
    if (el.cond && !condOk(el.cond, ctx)) return false;
    const v = el.visibleIn && el.visibleIn[scenario];
    if (v === undefined || v === false) return false;
    if (!condOk(v === true ? null : v, ctx)) return false;
    if (el.parent) return isVisible(el.parent);
    return true;
  }

  // plain UDim2 geometry; ov = optional overrides {max, uiScale, size, pos}
  function plain(e, ov) {
    ov = ov || {};
    const base = e.parent ? rectAny(e.parent) : guiRect(e.gui, ctx);
    const acc = base.s || 1;
    const size = ov.size || e.size, pos = ov.pos || e.pos;
    let sx = (e.relYY ? size[0] * base.h : size[0] * base.w) + size[1] * acc;
    let sy = size[2] * base.h + size[3] * acc;
    const mn = e.min, mx = ov.max || e.max;
    if (mn) { sx = Math.max(mn[0], sx); sy = Math.max(mn[1], sy); }
    if (mx) { sx = Math.min(mx[0], sx); sy = Math.min(mx[1], sy); }
    if (e.aspect) { if (sx / sy > e.aspect) sx = sy * e.aspect; else sy = sx / e.aspect; }
    const us = ov.uiScale || 1;
    sx *= us; sy *= us;
    const px = base.x + pos[0] * base.w + pos[1] * acc;
    const py = base.y + pos[2] * base.h + pos[3] * acc;
    return { x: px - e.anchor[0] * sx, y: py - e.anchor[1] * sy, w: sx, h: sy, s: acc * us };
  }

  const colW = () => Math.max(130, fl(0.17 * ctx.W));
  const colLeft = () => ctx.W - 8 - colW();

  const rules = {
    helpY(e) {
      const r = plain(e); const h = r.h; const gap = Math.max(6, fl(0.18 * h));
      r.y = Math.max(0, fl(Math.min(0.835 * ctx.H, ctx.H - (2 * h + gap + 16))));
      return r;
    },
    helpMenuAboveHelp(e) { const r = plain(e); r.y = rectAny('help_pill').y - 6 - r.h; return r; },
    travelDock() {
      const hp = rectAny('help_pill'); const gap = Math.max(6, fl(hp.h * 0.18));
      return { x: fl(hp.x), y: fl(hp.y + hp.h + gap), w: fl(hp.w), h: fl(hp.h), s: 1 };
    },
    offers(e) {
      const hp = rectAny('help_pill');
      const tv = isVisible('travel_button') ? rectAny('travel_button') : null;
      const left = fl(hp.x + hp.w + Math.max(10, hp.h * 0.35));
      const bottom = fl(Math.max(hp.y + hp.h, tv ? tv.y + tv.h : -Infinity));
      const r = plain(e);
      r.x = left; r.y = bottom - r.h - (e.rule.kind === 'column' && ctx.small ? 48 : 0);
      return r;
    },
    offerPopupSmall(e) {
      // PassClient.leftClear: the popup stays right of HELP and TRAVEL (both draw above it) and left of the touch action column
      const hp = rectAny('help_pill'), tv = rectAny('travel_button');
      const clear = Math.max(hp.x + hp.w, tv.x + tv.w);
      const left = Math.max(8, clear + 8);
      const w = Math.max(300, Math.min(0.8 * ctx.W, colLeft() - 8 - left));
      const cx = Math.min(left + w / 2, ctx.W - 8 - w / 2);
      const ww = fl(w), hh = Math.max(300, 0.9 * ctx.H);
      return { x: fl(cx) - ww / 2, y: 0.5 * ctx.H - hh / 2, w: ww, h: hh, s: 1 };
    },
    popupTop(e) {
      const ov = {};
      if (e.rule.maxWFormula === 'contractAnn') ov.max = [fl(clamp(2 * (colLeft() - 8 - ctx.W / 2), 320, 620)), 300];
      const r = plain(e, ov);
      let y = ctx.H * 0.11;
      if (isVisible('tut_card')) { const c = rectAny('tut_card'); if (c.y < ctx.H * 0.4) y = Math.max(y, c.y + c.h + 18); }
      if (e.rule.meAware && isVisible('fk_me')) { const m = rectAny('fk_me'); if (m.y < ctx.H * 0.5) y = Math.max(y, m.y + m.h + 8); }
      if (e.rule.meAware && isVisible('fk_bar')) { const b = rectAny('fk_bar'); if (b.y < ctx.H * 0.3) y = Math.max(y, b.y + b.h + 8); }
      r.y = y;
      return r;
    },
    touchColumn(e, id) {
      const j = jumpFor(ctx.W, ctx.H);
      const members = els.filter((x) => x.rule || (x.when || []).some((w) => w.rule && w.rule.type === 'touchColumn'))
        .map((x) => applyWhen(x, ctx)).filter((x) => x.rule && x.rule.type === 'touchColumn' && (x.id === id || isVisible(x.id)))
        .sort((a, b) => a.rule.order - b.rule.order);
      let bottom = j.top - 8; // column bottom: 8 px above the jump button's top
      const pos = {};
      for (let i = members.length - 1; i >= 0; i--) { pos[members[i].id] = bottom - 44; bottom -= 44 + 6; }
      return { x: ctx.W - 8 - colW(), y: pos[id], w: colW(), h: 44, s: 1 };
    },
    fkPillTouch(e) {
      const j = jumpFor(ctx.W, ctx.H); const colTop = j.top - 8 - 144;
      const r = plain(e); r.y = Math.max(0, fl(Math.min(0.19 * ctx.H, colTop - 8 - 56) + 0.5));
      return r;
    },
    fkMeTouch(e) {
      const bar = rectAny('fk_bar'); const r = plain(e);
      r.y = fl(bar.y + bar.h + 6 + 0.5);
      return r;
    },
    contractSlot(e) {
      const g = guiRect('ContractGui', ctx); const W = g.w, Hg = g.h;
      let right = 0.925 * W, top = 0.27 * Hg;
      if (ctx.touch) { right = Math.min(0.8 * W, colLeft() - 8); top = 0.16 * Hg; }
      if (isVisible('fk_pill')) { const p = rectAny('fk_pill'); top = Math.max(top, p.y + p.h + 8 - g.y); }
      if (isVisible('fk_bar')) { const b = rectAny('fk_bar'); if (b.y < ctx.H * 0.3) top = Math.max(top, b.y + b.h + 8 - g.y); }
      if (isVisible('fk_me')) { const m = rectAny('fk_me'); if (m.y < ctx.H * 0.5) top = Math.max(top, m.y + m.h + 8 - g.y); }
      const stripTop = Hg - 92;
      if (ctx.touch) top = Math.min(top, stripTop - 8 - 140);
      const x = fl(right + 0.5), y = fl(top + 0.5);
      let size = null;
      if (e.rule.as === 'tracker' && ctx.touch) {
        const h = fl(Math.max(140, Math.min(clamp(0.36 * Hg, 140, 230), stripTop - 8 - top)));
        size = [0.42, 0, 0, h];
      }
      const r = plain(e, size ? { size } : {});
      r.x = g.x + x - r.w; r.y = g.y + y; // anchor (1,0)
      return r;
    },
    inspectFit(e) {
      const normalH = Math.min(0.5 * ctx.H, 0.42 * ctx.W / 1.25);
      const big = ctx.small || normalH < 340;
      return plain(e, { size: big ? [0.64, 0, 0.92, 0] : [0.42, 0, 0.5, 0] });
    },
    uiScaleViewport(e) { return plain(e, { uiScale: clamp(Math.min(ctx.W / e.rule.div[0], ctx.H / e.rule.div[1]), e.rule.clamp[0], e.rule.clamp[1]) }); },
    toastShownTouch(e) {
      const cw = colW(); const s = clamp((ctx.W - (cw + 24) - 8) / 300, 0.5, 1);
      const w = 300 * s, h = 84 * s;
      return { x: ctx.W - (cw + 24) - w, y: 0.6 * ctx.H - h / 2, w, h, s };
    },
    treePill(e) { const r = plain(e); r.y = ctx.inset + 8; return r; },
    arenaLeave(e) {
      const g = guiRect('ArenaHud', ctx); const B = g.y + 0.6 * g.h;
      const w = Math.max(140, 0.17 * g.w);
      return { x: g.x + 0.012 * g.w, y: B - 46, w, h: 46, s: 1 };
    },
    arenaPaint(e) {
      const g = guiRect('ArenaHud', ctx); const B = g.y + 0.6 * g.h;
      const w = Math.max(96, 0.12 * g.w);
      return { x: g.x + 0.012 * g.w, y: B - 46 - 8 - 44, w, h: 44, s: 1 };
    },
    arenaBoost() {
      const g = guiRect('ArenaHud', ctx); const jl = jumpFor(g.w, g.h).left;
      return { x: g.x + jl - 12 - 88, y: g.y + g.h - 16 - 88, w: 88, h: 88, s: 1 };
    },
    arenaBrace() {
      const g = guiRect('ArenaHud', ctx); const jl = jumpFor(g.w, g.h).left;
      return { x: g.x + jl - 12 - 88 - 8 - 72, y: g.y + g.h - 16 - 72, w: 72, h: 72, s: 1 };
    },
    arenaStatus() {
      const g = guiRect('ArenaHud', ctx); const jl = jumpFor(g.w, g.h).left;
      const w = Math.max(0, Math.min(0.5 * g.w, jl - 196 - 0.012 * g.w)); const h = 0.045 * g.h;
      return { x: g.x + 0.012 * g.w, y: g.y + 0.965 * g.h - h, w, h, s: 1 };
    },
    jumpProbe() { const j = jumpFor(ctx.W, ctx.H); return { x: j.left, y: j.top, w: j.size, h: j.size, s: 1 }; },
    stripProbe() { return { x: ctx.W / 2 - 166, y: ctx.H - 92, w: 332, h: 92, s: 1 }; },
  };

  // rect of an element regardless of visibility (visibility only matters to the rules that ask isVisible)
  function rectAny(id) {
    if (memo[id]) return memo[id];
    const el = byId[id];
    const e = applyWhen(el, ctx);
    let ov = null;
    if (el.scenarioOverride && el.scenarioOverride[scenario]) {
      const o = el.scenarioOverride[scenario];
      ov = { pos: (ctx.touch && o.whenTouch && o.whenTouch.pos) || o.pos };
    }
    let r;
    if (e.rule && rules[e.rule.type]) r = rules[e.rule.type](e, id);
    else r = plain(e, ov || {});
    memo[id] = r;
    return r;
  }

  const ancestors = (id) => { const out = []; let p = byId[id].parent; while (p) { out.push(p); p = byId[p].parent; } return out; };
  return { els, byId, isVisible, rectAny, ancestors };
}

// ------------------------------------------------------------------ analysis
function inter(a, b) {
  const w = Math.min(a.x + a.w, b.x + b.w) - Math.max(a.x, b.x);
  const h = Math.min(a.y + a.h, b.y + b.h) - Math.max(a.y, b.y);
  return { w, h };
}

function allowed(a, b, eng) {
  if (eng.ancestors(a.id).includes(b.id) || eng.ancestors(b.id).includes(a.id)) return 'parent-child';
  for (const al of model.allowList) {
    if (al.pair && ((al.pair[0] === a.id && al.pair[1] === b.id) || (al.pair[0] === b.id && al.pair[1] === a.id))) return al.reason;
  }
  return null;
}

function analyse(sectionName) {
  const res = { overlaps: [], offscreen: [], touch: [], topbar: [], probes: [], unknown: [], matrix: {}, counted: 0, distinct: new Set(), knownIds: new Set() };
  const els = model[sectionName].elements;
  for (const e of els) if (e.kind === 'unknown') res.unknown.push(e); else if (e.kind === 'known') res.knownIds.add(e.id);
  for (const vp of model.viewports) {
    const inset = vp.touch ? opt.insetPhone : opt.insetDesktop;
    const ctx = { W: vp.w, H: vp.h, touch: vp.touch, inset, small: vp.w < 1000 || vp.h < 560 };
    for (const sc of Object.keys(model.scenarios)) {
      const eng = makeEngine(sectionName, ctx, sc);
      const vis = eng.els.filter((e) => eng.isVisible(e.id));
      const known = vis.filter((e) => e.kind === 'known');
      const rects = {};
      for (const e of vis) if (e.kind !== 'unknown') rects[e.id] = eng.rectAny(e.id);
      const key = sc + '|' + vp.name;
      res.matrix[key] = 0;
      // overlaps among known elements
      const found = [];
      for (let i = 0; i < known.length; i++) for (let j = i + 1; j < known.length; j++) {
        const a = known[i], b = known[j];
        if (allowed(a, b, eng)) continue;
        const it = inter(rects[a.id], rects[b.id]);
        if (it.w > opt.tol && it.h > opt.tol) found.push({ a, b, it });
      }
      // suppress child pairs whose ancestor already overlaps the same counterpart; remember them as extra detail
      const pairKey = (x, y) => [x, y].sort().join('~');
      const foundKeys = new Set(found.map((f) => pairKey(f.a.id, f.b.id)));
      for (const f of found) {
        const anc = (id) => eng.ancestors(id);
        const covered = anc(f.a.id).some((p) => foundKeys.has(pairKey(p, f.b.id))) || anc(f.b.id).some((p) => foundKeys.has(pairKey(f.a.id, p)));
        if (covered) continue;
        const kids = found.filter((g) => g !== f && ((anc(g.a.id).includes(f.a.id) && g.b.id === f.b.id) || (anc(g.b.id).includes(f.b.id) && g.a.id === f.a.id) ||
          (anc(g.a.id).includes(f.b.id) && g.b.id === f.a.id) || (anc(g.b.id).includes(f.a.id) && g.a.id === f.b.id)))
          .map((g) => (g.a.id === f.a.id || g.a.id === f.b.id ? g.b : g.a).name);
        const ga = model.guis[f.a.gui].displayOrder, gb = model.guis[f.b.gui].displayOrder;
        res.overlaps.push({ sc, vp: vp.name, a: f.a, b: f.b, ra: rects[f.a.id], rb: rects[f.b.id], w: f.it.w, h: f.it.h, doA: ga, doB: gb, kids,
          both: !!(f.a.interactive && f.b.interactive) });
        res.matrix[key]++; res.counted++;
        res.distinct.add(pairKey(f.a.id, f.b.id));
      }
      // probes (assumed rects): reported separately, never counted
      for (const p of vis.filter((e) => e.kind === 'assumed')) {
        for (const k of known) {
          if (allowed(p, k, eng)) continue;
          const it = inter(rects[p.id], rects[k.id]);
          if (it.w > opt.tol && it.h > opt.tol) res.probes.push({ sc, vp: vp.name, probe: p, el: k, w: it.w, h: it.h, rp: rects[p.id], re: rects[k.id] });
        }
      }
      for (const k of known) {
        const r = rects[k.id];
        // off-screen
        const L = -r.x, T = -r.y, R = r.x + r.w - vp.w, B = r.y + r.h - vp.h;
        if (L > 2 || T > 2 || R > 2 || B > 2) res.offscreen.push({ sc, vp: vp.name, el: k, r, sides: [L > 2 && `left ${r1(L)}`, T > 2 && `top ${r1(T)}`, R > 2 && `right ${r1(R)}`, B > 2 && `bottom ${r1(B)}`].filter(Boolean).join(', ') });
        // touch targets
        if (vp.touch && k.interactive) {
          const m = Math.min(r.w, r.h);
          if (m < 43.5) {
            const ok40 = k.denseOk && m >= 39.5;
            res.touch.push({ sc, vp: vp.name, el: k, r, level: ok40 ? 'dense-40-accepted' : 'BELOW', });
          }
        }
        // top bar zone (information only)
        const g = model.guis[k.gui];
        const ignore = Object.prototype.hasOwnProperty.call(opt.guiInset, k.gui) ? opt.guiInset[k.gui] : g.ignoreInset;
        if (ignore && r.y < inset - 2 && !k.parent) res.topbar.push({ sc, vp: vp.name, el: k, r, inset });
      }
    }
  }
  return res;
}


// ------------------------------------------------------------------ --dump
if (opt.dump) {
  const [dsc, dvp] = opt.dump.split('@');
  const vp = model.viewports.find((v) => v.name === dvp);
  if (!vp || !model.scenarios[dsc]) { console.error('usage: --dump SCENARIO@VIEWPORT (scenarios: ' + Object.keys(model.scenarios).join(', ') + ')'); process.exit(2); }
  for (const s of sections) {
    const ctx = { W: vp.w, H: vp.h, touch: vp.touch, inset: vp.touch ? opt.insetPhone : opt.insetDesktop, small: vp.w < 1000 || vp.h < 560 };
    const eng = makeEngine(s, ctx, dsc);
    console.log(`${s.toUpperCase()} ${dsc} @ ${dvp} (inset ${ctx.inset}, touch ${ctx.touch}, small ${ctx.small})`);
    for (const e of eng.els.filter((x) => eng.isVisible(x.id) && x.kind !== 'unknown')) {
      const r = eng.rectAny(e.id);
      console.log(`  ${e.id.padEnd(22)} ${fmtRect(r).padEnd(34)} right ${r1(r.x + r.w)} bottom ${r1(r.y + r.h)}  [${e.kind}] ${e.name}`);
    }
  }
  process.exit(0);
}

// ------------------------------------------------------------------ report
const dedupe = (rows, keyFn) => { const m = new Map(); for (const r of rows) { const k = keyFn(r); if (!m.has(k)) m.set(k, { r, n: 0, vps: new Set() }); const o = m.get(k); o.n++; o.vps.add(r.vp); } return [...m.values()]; };
const vpNames = model.viewports.map((v) => v.name);

function report(sectionName, res) {
  const L = [];
  const lbl = model[sectionName].label;
  L.push(`## ${sectionName.toUpperCase()} - ${lbl}`);
  L.push('');
  L.push(`Counted overlaps (scenario x viewport x pair, tolerance > ${opt.tol} px on both axes): **${res.counted}** in **${res.distinct.size}** distinct element pairs.`);
  const dOff = new Set(res.offscreen.map((o) => o.el.id + '|' + o.vp)).size;
  const below = res.touch.filter((t) => t.level === 'BELOW'), dense = res.touch.filter((t) => t.level !== 'BELOW');
  const dBelow = new Set(below.map((t) => t.el.id + '|' + t.vp)).size, dDense = new Set(dense.map((t) => t.el.id + '|' + t.vp)).size;
  L.push(`Partly off-screen: **${dOff}** element/viewport combinations (${res.offscreen.length} scenario rows). Touch targets below the minimum: **${dBelow}** element/viewport combinations (${below.length} scenario rows), plus ${dDense} accepted at the dense 40 px allowance.`);
  L.push(`Known elements checked: ${res.knownIds.size}; unknown (excluded): ${res.unknown.length}; assumed probes (never counted): ${model[sectionName].elements.filter((e) => e.kind === 'assumed').length}.`);
  L.push('');
  L.push('### Overlap count per scenario and viewport');
  L.push('');
  L.push('| scenario | ' + vpNames.join(' | ') + ' | total |');
  L.push('|---|' + vpNames.map(() => '---:').join('|') + '|---:|');
  for (const sc of Object.keys(model.scenarios)) {
    let tot = 0; const cells = vpNames.map((v) => { const n = res.matrix[sc + '|' + v]; tot += n; return n ? String(n) : '.'; });
    L.push(`| ${sc} | ${cells.join(' | ')} | ${tot || '.'} |`);
  }
  L.push('');
  L.push('### Overlaps (counted)');
  L.push('');
  if (!res.overlaps.length) L.push('none');
  else {
    L.push('| scenario | viewport | element A (gui, DO) | element B (gui, DO) | overlap px | A rect (x,y w x h) | B rect | notes |');
    L.push('|---|---|---|---|---|---|---|---|');
    for (const o of res.overlaps) {
      const note = [o.both ? 'both interactive' : '', o.doA === o.doB ? 'same DisplayOrder' : (o.doA > o.doB ? `A draws above B` : `B draws above A`), o.kids.length ? `children also hit: ${[...new Set(o.kids)].join(', ')}` : ''].filter(Boolean).join('; ');
      L.push(`| ${o.sc} | ${o.vp} | ${o.a.name} (${o.a.gui}, ${o.doA}) | ${o.b.name} (${o.b.gui}, ${o.doB}) | ${r1(o.w)}x${r1(o.h)} | ${fmtRect(o.ra)} | ${fmtRect(o.rb)} | ${note} |`);
    }
  }
  L.push('');
  L.push('### Distinct overlapping pairs (which viewports, how many scenarios)');
  L.push('');
  const dp = dedupe(res.overlaps, (o) => [o.a.id, o.b.id].sort().join('~'));
  if (!dp.length) L.push('none');
  else {
    L.push('| pair | scenarios x viewports | viewports |');
    L.push('|---|---:|---|');
    for (const d of dp) L.push(`| ${d.r.a.name} / ${d.r.b.name} | ${d.n} | ${vpNames.filter((v) => d.vps.has(v)).join(', ')} |`);
  }
  L.push('');
  L.push('### Partly off-screen (known elements)');
  L.push('');
  if (!res.offscreen.length) L.push('none');
  else {
    L.push('| scenario | viewport | element | rect | outside by |');
    L.push('|---|---|---|---|---|');
    for (const o of res.offscreen) L.push(`| ${o.sc} | ${o.vp} | ${o.el.name} | ${fmtRect(o.r)} | ${o.sides} |`);
  }
  L.push('');
  L.push('### Touch targets smaller than 44x44 (touch viewports only)');
  L.push('');
  const tt = dedupe(res.touch, (t) => t.el.id + '|' + t.vp + '|' + t.level);
  if (!tt.length) L.push('none');
  else {
    L.push('| element | viewport | size w x h | level | scenarios |');
    L.push('|---|---|---|---|---:|');
    for (const d of tt) L.push(`| ${d.r.el.name} | ${d.r.vp} | ${r1(d.r.r.w)}x${r1(d.r.r.h)} | ${d.r.level} | ${d.n} |`);
  }
  L.push('');
  L.push('### Top-level elements that start inside the Roblox top-bar zone (information only, not counted; the top-bar buttons are core UI at the screen edges, the centre is usually free)');
  L.push('');
  const tbm = new Map();
  for (const t of res.topbar) { const k = t.el.id; if (!tbm.has(k)) tbm.set(k, { el: t.el, vps: new Map() }); tbm.get(k).vps.set(t.vp, `${r1(t.r.y)} (inset ${t.inset})`); }
  if (!tbm.size) L.push('none');
  else {
    L.push('| element | viewport: top y |');
    L.push('|---|---|');
    for (const d of tbm.values()) L.push(`| ${d.el.name} | ${[...d.vps].map(([v, y]) => v + ': ' + y).join('; ')} |`);
  }
  L.push('');
  L.push('### Probe overlaps against ASSUMED rects (jump button default, UPGRADES strip fallback band) - NOT counted');
  L.push('');
  const pr = dedupe(res.probes, (p) => p.probe.id + '|' + p.el.id + '|' + p.vp);
  if (!pr.length) L.push('none');
  else {
    L.push('| probe | element | viewport | overlap px | probe rect | element rect | scenarios |');
    L.push('|---|---|---|---|---|---|---:|');
    for (const d of pr) L.push(`| ${d.r.probe.name} | ${d.r.el.name} | ${d.r.vp} | ${r1(d.r.w)}x${r1(d.r.h)} | ${fmtRect(d.r.rp)} | ${fmtRect(d.r.re)} | ${d.n} |`);
  }
  L.push('');
  L.push('### Unknown elements (static Studio frames or non-static rects) - listed, EXCLUDED from every result above');
  L.push('');
  L.push('| element | why unknown |');
  L.push('|---|---|');
  for (const u of res.unknown) L.push(`| ${u.name} | ${u.unknownReason} |`);
  L.push('');
  return L.join('\n');
}

// ------------------------------------------------------------------ main
const out = [];
out.push('# Source-derived layout check');
out.push('');
out.push('Regenerate: `cd outputs/UIAudit20261008/layout && node check_layout.js --section ' + opt.section + (opt.md ? ' --md ' + path.basename(opt.md) : '') + '` (exit status 1 = counted overlaps in the AFTER section). Single scenario: `--dump driving@844x390`.');
out.push('');
out.push('**What this is:** pixel rectangles computed from numbers read out of the Luau sources (see `layout_model.json`, every element cites file:line). **What it is not:** a render of Roblox. It was not run in Studio, it cannot see static Studio frames (listed as unknown and excluded) and a clean result does not prove that input works.');
out.push('');
out.push(`Assumptions: GuiInset ${opt.insetDesktop} px on desktop viewports, ${opt.insetPhone} px on phone viewports; phones are TouchEnabled without keyboard; ArenaHud treated as inset-respecting (CoreUISafeInsets); MiniPlowGui treated as IgnoreGuiInset=true (copied from the unknown RNGGui); device notch insets 0; Roblox default jump button rect is an assumption (probe only). Overlap tolerance ${opt.tol} px on both axes.`);
out.push('');
const totals = {};
for (const s of sections) { const res = analyse(s); totals[s] = res; out.push(report(s, res)); }
out.push('## Limitations');
out.push('');
const lim = [
  'Source-derived only: nothing here was run in Studio, no screenshot was taken, no input was tested.',
  'Static Studio frames (UPGRADES / MINIS / AFK strip, REWARDS + Starter Pack square, LeftMenu / GARAGE, SnowCounter, SettingsCorner, Travel panel, ActivityHUD) are not in the repo. They are listed as unknown and excluded, so overlaps with them are NOT detected. MINIS and AFK sit on the UPGRADES strip, so they are unknown too.',
  'The top-bar inset (36 px desktop / 58 px phone) and phone safe-area insets (assumed 0) are assumptions; Roblox reports different values per device and app version. Re-run with --inset-desktop / --inset-phone to see the sensitivity.',
  'ArenaHud sets both IgnoreGuiInset=true and ScreenInsets=CoreUISafeInsets; which wins at runtime is not verified. MiniPlowGui / AfkDriftGui copy the unknown RNGGui.IgnoreGuiInset (assumed true). Use --gui-inset NAME=true|false to test the other reading.',
  'The Roblox default jump button rect (size 70 / 120 px) comes from memory; only its left/top fallback is in the repo (UILayout.jumpLeftTop). It is a probe and never counted. The real TouchGui JumpButton is read live by the fixed code and may differ.',
  'Dynamic anchoring is modelled for HELP, TRAVEL, the offer column / toggle, the PopupStack column (HELP REQUEST popup only), the touch action column, the contract slot, the Frost King pill / Me card, and the arena touch controls. Popups stacked together, the tutorial spotlight / pointer layer, toasts, billboards and per-frame text are not modelled.',
  'The contract slot ignores the ActivityHUD boost pills (their rect is unknown) and uses the fallback strip top (H-92) instead of the live UPGRADES top.',
  'UIScale pop-in tweens are assumed finished (scale 1). Text size / clipping is not evaluated, only rectangles.',
  'Visibility per scenario is my reading of the cited visibility rules (visibleIn in the model); a scenario that the code cannot actually reach is not flagged.',
  'AFTER studio-snapshot scripts (TreasureReveal, UpgradeTreeClient) are the PENDING patch copies; their installation in Studio has not happened.',
  'The tutorial scenarios assume the HELP pill stays tappable mid-lesson (its handler has no lesson guard; showStep only closes the menu at the next step) and that PlowTutorialDone is already true (a replay). BEFORE TRAVEL is assumed to find the PlowTutorial HelpPill with its 60 s scan.',
  'Sensitivity (measured with this tool): phone inset 36 instead of 58 -> BEFORE 95 / AFTER 38 overlaps; ArenaHud ignoring the inset -> 88 / 34; tolerance 0 px instead of 4 -> 166 / 70 (extra hits are edge-touching or sub-4 px). 390x844 portrait is not a designed layout, its hits are reported but weigh less.',
];
lim.forEach((l, i) => out.push(`${i + 1}. ${l}`));
out.push('');
const b = totals.before, a = totals.after;
const summary = [];
const dc = (arr, f) => new Set(arr.filter(f || (() => true)).map((t) => t.el.id + '|' + t.vp)).size;
for (const [nm, r] of [['BEFORE', b], ['AFTER', a]]) {
  if (r) summary.push(`${nm}: ${r.counted} overlaps (scenario x viewport x pair; ${r.distinct.size} distinct element pairs), ${dc(r.offscreen)} off-screen element/viewport combinations, ${dc(r.touch, (t) => t.level === 'BELOW')} touch-target (<44, <40 for dense controls) element/viewport combinations`);
}
out.push('## Summary');
out.push('');
summary.forEach((s) => out.push('- ' + s));
out.push('');
const text = out.join('\n');
if (opt.md) fs.writeFileSync(opt.md, text + '\n');
if (!opt.quiet) console.log(text);
else summary.forEach((s) => console.log(s));
let fail = false;
if (a && a.counted > 0) fail = true;
if (opt.strict && b && b.counted > 0) fail = true;
if (!a && b && b.counted > 0) fail = true;
process.exit(fail ? 1 : 0);
