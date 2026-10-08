#!/usr/bin/env python3
"""Syntax + static check for Luau files, filtering Roblox-global noise.

Usage: luau_check.py [--json] FILE...
Env:   LUAU_BIN = directory holding luau-compile and luau-analyze (a release of luau-lang/luau).

What it does
  1. luau-compile --null  -> real parse/compile errors (anything not starting with "Compiled").
  2. luau-analyze         -> lint/type diagnostics, minus noise that only exists because the analyzer has no Roblox
                             type definitions (Unknown global for Roblox std globals, Unknown type Vector3 ...).
  A leftover "Unknown global 'x'" for a name that is NOT a Roblox global is reported: it is a likely typo/undefined variable.
It does NOT prove runtime behaviour in Roblox; it only catches syntax errors and a class of undefined-name mistakes.
"""
import json, os, re, subprocess, sys

ROBLOX_GLOBALS = set("""game workspace script plugin shared task Instance Enum Vector2 Vector3 Vector2int16 Vector3int16 CFrame Color3
ColorSequence ColorSequenceKeypoint NumberSequence NumberSequenceKeypoint NumberRange UDim UDim2 Rect Region3 Region3int16 Ray TweenInfo
BrickColor Random DateTime Font Faces Axes OverlapParams RaycastParams PhysicalProperties Path2DControlPoint SharedTable CatalogSearchParams
DockWidgetPluginGuiInfo wait spawn delay tick time warn elapsedTime UserSettings settings version printidentity Game Workspace
typeof utf8 bit32 buffer require""".split())

def run(cmd):
    p = subprocess.run(cmd, capture_output=True, text=True)
    return p.returncode, (p.stdout + p.stderr)

def main(argv):
    as_json = "--json" in argv
    files = [a for a in argv if not a.startswith("--")]
    binroot = os.environ.get("LUAU_BIN", "")
    comp, ana = os.path.join(binroot, "luau-compile"), os.path.join(binroot, "luau-analyze")
    if not (os.path.exists(comp) and os.path.exists(ana)):
        print("LUAU_BIN must point at a directory with luau-compile and luau-analyze", file=sys.stderr); return 2
    report, bad = [], 0
    for f in files:
        rc, out = run([comp, "--null", f])
        syntax = [l for l in out.splitlines() if l.strip() and not l.startswith("Compiled")]
        _, aout = run([ana, f])
        real, noise = [], 0
        for l in aout.splitlines():
            if not l.strip(): continue
            m = re.search(r"Unknown global '([^']+)'", l)
            if m:
                if m.group(1) in ROBLOX_GLOBALS: noise += 1; continue
            elif re.search(r"Unknown type '(Vector2|Vector3|CFrame|Color3|UDim2|Instance|Enum[A-Za-z.]*)'", l):
                noise += 1; continue
            real.append(l.replace("./", "", 1))
        if syntax: bad += 1
        report.append({"file": f, "syntax_errors": syntax, "analyzer": real, "noise_filtered": noise})
    if as_json:
        print(json.dumps(report, indent=1))
    else:
        for r in report:
            tag = "SYNTAX-ERROR" if r["syntax_errors"] else "ok"
            print(f"{tag:12} {r['file']}  analyzer={len(r['analyzer'])} (+{r['noise_filtered']} Roblox-global noise filtered)")
            for l in r["syntax_errors"]: print("    !!", l)
            for l in r["analyzer"][:int(os.environ.get('SHOW', '0'))]: print("    ", l)
        print(f"\n{len(files)} files, {bad} with syntax errors, {sum(len(r['analyzer']) for r in report)} analyzer diagnostics")
    return 1 if bad else 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
