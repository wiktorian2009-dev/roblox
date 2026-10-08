import json,pathlib,re,hashlib,shutil,zipfile
root=pathlib.Path(r"C:\Users\wikto\Desktop\Roblox Gra")
pack=root/"outputs"/"NewShovelIcons20261004"
data=json.loads((pack/"final-source.json").read_text(encoding="utf-8-sig"))
target=root/"game"/"src"/"ReplicatedStorage"/"RNGConfig.luau"
if target.exists() and not (pack/"before-local-RNGConfig.luau").exists():
    shutil.copy2(target,pack/"before-local-RNGConfig.luau")
content=data["source"].encode("utf-8")
target.write_bytes(content)
(pack/"final-RNGConfig.luau").write_bytes(content)
report={"path":"ReplicatedStorage.RNGConfig","file":str(target),"sha256":hashlib.sha256(content).hexdigest(),
    "exactSource":target.read_bytes()==content,"iconBindingsChanged":14,"syntaxOk":data["syntaxOk"]}
(pack/"source-hash.json").write_text(json.dumps(report,indent=2),encoding="utf-8")
with zipfile.ZipFile(pack/"NewShovelIcons-PNGs.zip","w",zipfile.ZIP_DEFLATED) as z:
    for file in sorted((pack/"icons").glob("*.png")): z.write(file,"icons/"+file.name)
    for name in ["prompts.json","assets.json","uploaded-assets.json","icon-changes.json","installation-status.json","preview.html"]: z.write(pack/name,name)
    for file in sorted((pack/"references").glob("*.png")): z.write(file,"references/"+file.name)
    if (pack/"README.md").exists(): z.write(pack/"README.md","README.md")
print(json.dumps(report))

