from pathlib import Path
import json,hashlib,zipfile
root=Path(r"C:\Users\wikto\Desktop\Roblox Gra")
out=root/"outputs"/"StudioRefresh20261002"
report=json.loads((out/"sync-report.json").read_text(encoding="utf-8"))
for row in report["sources"]:
    p=root/row["target"]
    assert hashlib.sha256(p.read_bytes()).hexdigest()==row["sha256"],str(p)
graph=json.loads((root/"graphify-out"/"graph.json").read_text(encoding="utf-8"))
nodes=graph["nodes"]; edges=graph.get("links",graph.get("edges"))
assert len(nodes)==530 and len(edges)==1027
ids={n["id"] for n in nodes}
missing=[e for e in edges if e["source"] not in ids or e["target"] not in ids]
assert not missing
indexedSources={n.get("source","") for n in nodes}
newSystems={}
for term in ("ActivityService","BoostService","ActivityClient","TreasureService","TreasureBook","BiomeLighting"):
    present=any(term in str(n) for n in nodes)
    newSystems[term]=present
    assert present,term
files=[root/x for x in ("PROJECT.md","STATUS.md","AGENTS.md","CLAUDE.md","PROJECT-INSTRUCTIONS.txt",
"game/default.project.json","game/syncback.project.json","game/README.txt","game/studio-snapshots/README.md",
"game/studio-snapshots/live-instance-summary.json","graphify-out/graph.json","graphify-out/GRAPH_REPORT.md","graphify-out/graph.html")]
files += [root/x["target"] for x in report["sources"]]
files += [root/x for x in json.loads((out/"metadata-changes.json").read_text())["changedPaths"]]
files += [out/x for x in ("README.md","sync-report.json","verified-facts.json","live-metadata.json","live-recheck.json","metadata-changes.json")]
archive=out/"StudioRefreshHandoff20261002.zip"
with zipfile.ZipFile(archive,"w",zipfile.ZIP_DEFLATED) as z:
    for p in files:
        z.write(p,p.relative_to(root).as_posix())
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    assert len(z.namelist())==len(files)
qa={"sourceHashesMatch":len(report["sources"]),"nodes":len(nodes),"edges":len(edges),"communities":42,
    "danglingEdges":len(missing),"indexedSystems":newSystems,"handoffFiles":len(files),
    "handoffBytes":archive.stat().st_size,"zipValid":True,
    "partialParsingWarnings":["UpgradeTreeClient.client.luau:L341","PortalAnimator.server.luau:L35"]}
(out/"verification.json").write_text(json.dumps(qa,indent=2),encoding="utf-8")
print(json.dumps(qa,indent=2))

