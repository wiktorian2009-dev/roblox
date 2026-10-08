# Snow arrival intro

Built directly into the Roblox Studio place money. Changes are not published.

Press Play to watch the intro. It runs once per join, lasts seven seconds, and supports the Skip button and gamepad B. During Studio play, press I to replay it.

The sequence shows your avatar falling and flailing, landing in a snow burst, shaking off snow, discovering the sparkling shovel, running to it, gripping it with both hands, lifting it overhead, and twirling it. The camera finishes above and behind the character at the edge of the starter field. A temporary igloo, clouds, falling snow, blue sky, and glow effects frame the scene.

The intro supports Motor6D rigs and the newer AnimationConstraint avatar joints. It uses the player's appearance and local visual effects. A server guard holds and releases the character, with a timeout fallback. Snow collection pauses during the intro. Saved inventory, currency, upgrades, and rebirth progress are not changed; the cinematic shovel is a visual prop.

Validation: completed a full run in 7.01 seconds (422 rendered frames on the test machine); inspected the fall, landing, two-handed grip and hero pose; verified the actual Skip button restores movement and camera; verified death interrupts and removes the cinematic; verified repeat automatic starts are rejected. Original sky, HUD, and camera mode restore after completion or interruption. Tests used an isolated profile. Test mode is off and Studio is back in Edit mode.

Source snapshot: Snow-intro-source.json. Rollback: remove the five added instances listed in Snow-intro-backup.json and restore its four original script sources.
