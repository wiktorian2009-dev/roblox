from pathlib import Path
import json, re, hashlib
root=Path(r"C:\Users\wikto\Desktop\Roblox Gra")
pack=root/"outputs/UpgradeIcons20261001"
config=root/"game/src/ReplicatedStorage/UpgradeConfig.luau"
before=(pack/"UpgradeConfig-before.luau").read_text(encoding="utf-8-sig").rstrip()
current=config.read_text(encoding="utf-8-sig")
if current.rstrip()!=before:
 raise SystemExit("Canonical config changed concurrently; preserving it for review")
mapping=json.loads((pack/"asset-map.json").read_text(encoding="utf-8-sig"))["icons"]
done=[]
lines=[]
for line in current.splitlines():
 match=re.search(r'\bId\s*=\s*"([^"]+)"',line)
 if match and match[1] in mapping:
  node=match[1]
  assert not re.search(r'\bIcon\s*=',line),node
  replacement=re.sub(r'(\}\s*,?)\s*$',lambda m:', Icon = "'+mapping[node]+'"'+m[1],line)
  assert replacement!=line,node
  done.append(node)
  line=replacement
 lines.append(line)
assert len(done)==51 and set(done)==set(mapping)
patched="\n".join(lines)+"\n"
(pack/"UpgradeConfig-disk-before.luau").write_text(current,encoding="utf-8")
config.write_text(patched,encoding="utf-8")
(pack/"UpgradeConfig-after.luau").write_text(patched,encoding="utf-8")
print(json.dumps({"iconsAdded":len(done),"iconCount":len(re.findall(r'\bId\s*=.*?\bIcon\s*=',patched)),"sha256":hashlib.sha256(patched.rstrip().encode()).hexdigest()}))

