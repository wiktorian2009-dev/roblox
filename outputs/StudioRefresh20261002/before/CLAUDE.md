# Roblox game handoff

Read AGENTS.md for the shared working instructions, then PROJECT.md and STATUS.md at the start of a new task. Use those same files for the handoff back to Codex. Inspect live Roblox Studio state before editing; these local files are not a synced copy of the whole game.

Keep updates to these documents concise. Do not load every historical source backup or reread the entire conversation unless a specific issue requires it. If folder access is unavailable, use the latest uploaded PROJECT.md and STATUS.md and return a replacement STATUS.md after changes.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify extract game --code-only --out . --max-workers 2` to keep the graph current (AST-only, no API cost).

Graphify scope: scan only game/; outputs are in the project-root graphify-out/. Source paths in the graph are relative to game/. After extraction, run `graphify cluster-only . --no-label` to refresh the report and HTML. Model files (.rbxm), Studio-only objects, historical builders and uploaded chat context are outside this graph. Use the graph to locate relevant sources, then verify current source and Studio state; Lua parsing does not prove Roblox runtime relationships.


Egg exception: game/studio-snapshots/ holds read-only PetClient and EggFloat copies for indexing, outside Rojo mappings. Snapshot source paths point to copies, not editable live sources. Refresh them from Studio when relevant before rebuilding Graphify; disk refresh alone cannot capture Studio edits.

