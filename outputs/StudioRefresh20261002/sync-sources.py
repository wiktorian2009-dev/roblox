from pathlib import Path
import json, hashlib, shutil, sys, datetime, urllib.request
root=Path(r"C:\Users\wikto\Desktop\Roblox Gra")
out=root/"outputs"/"StudioRefresh20261002"
bundle=json.loads((out/"live-sources.json").read_text(encoding="utf-8"))
mapped={"ReplicatedStorage","ServerScriptService","StarterPlayer"}
def canonical(row, occurrence):
    segments=row["segments"].copy()
    suffix={"ModuleScript":".luau","LocalScript":".client.luau","Script":".server.luau"}[row["className"]]
    if occurrence>1:
        segments[-1]+=f"__duplicate{occurrence}"
    if segments[0] in mapped:
        base=root/"game"/"src"
    else:
        base=root/"game"/"studio-snapshots"
    # Two generic one-line Workspace scripts are recorded only in the archive.
    if row["path"]=="Workspace.Script": return None
    segments[-1]+=suffix
    return base.joinpath(*segments)
def digest(data): return hashlib.sha256(data).hexdigest()
plan=[]
counts={}
for row in bundle["sources"]:
    counts[row["path"]]=counts.get(row["path"],0)+1
    target=canonical(row,counts[row["path"]])
    if target is None: continue
    data=row["source"].encode("utf-8")
    before=target.read_bytes() if target.exists() else None
    item={"studioPath":row["path"],"className":row["className"],"target":target.relative_to(root).as_posix(),
          "sha256":digest(data),"bytes":len(data),"state":"new" if before is None else ("same" if before==data else "changed"),
          "disabled":row.get("disabled"),"runContext":row.get("runContext")}
    if before is not None:item["previousSha256"]=digest(before)
    plan.append(item)
# Keep one consistent location for Studio-only scripts; archive superseded copies.
obsolete=[
    root/"game"/"studio-snapshots"/"StarterGui.RNGGui.UpgradeTreeClient.client.luau",
    root/"game"/"studio-snapshots"/"Workspace"/"FrostfallVillage"/"EggDisplay"/"EggFloat.client.luau",
    root/"game"/"src"/"ReplicatedFirst"/"LoadingScreen.client.luau",
]
report={"capturedAt":bundle["capturedAt"],"placeId":bundle["placeId"],"datamodel":bundle["datamodel"],
        "sources":plan,"archiveOnlyScripts":[x["path"] for x in bundle["sources"] if x["path"]=="Workspace.Script"],
        "supersededCopies":[x.relative_to(root).as_posix() for x in obsolete if x.exists()],
        "counts":{state:sum(x["state"]==state for x in plan) for state in ("same","new","changed")},
        "notes":["Source mirror, not a complete place/model export.","Studio-only snapshots are outside default.project.json mappings."]}
(out/"sync-plan.json").write_text(json.dumps(report,indent=2),encoding="utf-8")
try:
    with urllib.request.urlopen("http://127.0.0.1:34872/api/rojo",timeout=2) as res:
        rojo=json.loads(res.read().decode())
except Exception as exc: rojo={"available":False,"detail":str(exc)}
(out/"rojo-status.json").write_text(json.dumps(rojo,indent=2),encoding="utf-8")
if "--apply" in sys.argv:
    original={}
    for row in bundle["sources"]:
        if row["path"]=="Workspace.Script":continue
        original[row["path"]]=row
    for item in plan:
        target=root/item["target"]
        # Detect local edits since the reviewable plan was created.
        row=original[item["studioPath"]]
        data=row["source"].encode("utf-8")
        if target.exists() and digest(target.read_bytes())!=item.get("previousSha256",item["sha256"]):
            raise RuntimeError("Local file changed during sync: "+str(target))
        if item["state"]!="same":
            if target.exists():
                recovery=out/"before"/item["target"]
                recovery.parent.mkdir(parents=True,exist_ok=True)
                shutil.copy2(target,recovery)
            target.parent.mkdir(parents=True,exist_ok=True)
            target.write_bytes(data)
        if digest(target.read_bytes())!=item["sha256"]:raise RuntimeError("Hash mismatch: "+str(target))
    for target in obsolete:
        if target.exists():
            recovery=out/"before"/target.relative_to(root)
            recovery.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(target,recovery)
            # Explicit files within game; no recursive deletion.
            if not target.resolve().is_relative_to((root/"game").resolve()):raise RuntimeError("Unsafe target")
            target.unlink()
    report["appliedAt"]=datetime.datetime.now(datetime.timezone.utc).isoformat()
    report["allSourceHashesMatch"]=True
    (out/"sync-report.json").write_text(json.dumps(report,indent=2),encoding="utf-8")
print(json.dumps({"mode":"apply" if "--apply" in sys.argv else "plan","counts":report["counts"],
                 "superseded":report["supersededCopies"],"rojo":rojo,
                 "changedPaths":[x["target"] for x in plan if x["state"]!="same"]},indent=2))

