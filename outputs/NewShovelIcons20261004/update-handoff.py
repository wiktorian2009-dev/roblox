import pathlib,json
root=pathlib.Path(r"C:\Users\wikto\Desktop\Roblox Gra")
pack=root/"outputs"/"NewShovelIcons20261004"
entry=json.loads((pack/"handoff-entry.json").read_text(encoding="utf-8"))
status=root/"STATUS.md"
current=status.read_text(encoding="utf-8-sig")
assert current.startswith("# Current handoff"),"Unexpected handoff header"
heading="## New shovel icons — 2026-10-04, Codex"
assert heading not in current,"Entry already exists"
current=current.replace("# Current handoff","# Current handoff\n\n"+entry,1)
current=current.replace("RNGConfig (BaseSize 1.4 / Giant), RebirthRules + RebirthService","RebirthRules + RebirthService",1)
status.write_text(current,encoding="utf-8")
project=root/"PROJECT.md"
brief=project.read_text(encoding="utf-8-sig")
brief=brief.replace("Latest graph (2026-10-04 after UniversalVFX source mirroring)","Latest graph (2026-10-04 after new shovel icon/source mirroring)",1)
marker="Reusable VFX:"
note="Shovel icon artwork: 49 base shovels now include 14 new Blender shovels with generated transparent 512px PNG icons. RNGConfig ImageId is shared by ItemIcon across rolls/index/inventory and inherited by all Giant/Shiny variants. Artwork, prompts, comparison gallery and recovery: outputs/NewShovelIcons20261004/README.md.\n\n"
assert marker in brief
brief=brief.replace(marker,note+marker,1)
project.write_text(brief,encoding="utf-8")
print("Updated current handoff and icon/graph references; preserved other notes")

