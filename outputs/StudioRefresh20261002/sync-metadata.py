from pathlib import Path
import json,shutil
root=Path(r"C:\Users\wikto\Desktop\Roblox Gra")
out=root/"outputs"/"StudioRefresh20261002"
meta=json.loads((out/"live-metadata.json").read_text(encoding="utf-8"))
changes=[]
def save(target,data):
    content=(json.dumps(data,indent=2)+"\n").encode()
    if target.exists() and target.read_bytes()==content:return
    if target.exists():
        recovery=out/"before"/target.relative_to(root)
        recovery.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(target,recovery)
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_bytes(content)
    changes.append(target.relative_to(root).as_posix())
# New Edit-time remotes already exist in Studio; match their class without changing live instances.
for x in meta["rsChildren"]:
    if x["className"] in ("RemoteEvent","RemoteFunction") and x["children"]==0:
        p=root/"game"/"src"/"ReplicatedStorage"/(x["name"]+".model.json")
        if p.exists():
            current=json.loads(p.read_text())
            assert current["className"]==x["className"],str(p)
        else:save(p,{"className":x["className"]})
# SnowStage economic attributes of all existing mapped templates are unchanged.
for x in meta["snowStages"]:
    p=root/"game"/"src"/"ReplicatedStorage"/"SnowStages"/x["name"]/"init.meta.json"
    if p.exists():
        current=json.loads(p.read_text())
        assert current.get("attributes",{})==x["attributes"],str(p)
# Preserve unmapped Sakura/any later Studio-only stage template during future live sync.
p=root/"game"/"src"/"ReplicatedStorage"/"SnowStages"/"init.meta.json"
current=json.loads(p.read_text())
current["ignoreUnknownInstances"]=True
save(p,current)
(out/"metadata-changes.json").write_text(json.dumps({"changedPaths":changes,
"existingStageAttributesMatch":True,"sakuraTemplate":"Studio-only; captured attributes in live-metadata.json",
"binaryModels":"Not exported or verified against the existing .rbxm files"},indent=2),encoding="utf-8")
print(json.dumps({"changedPaths":changes,"existingStageAttributesMatch":True},indent=2))

