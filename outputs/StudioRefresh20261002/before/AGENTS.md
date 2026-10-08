# Roblox game project

At the start of a new task, read PROJECT.md for accepted decisions and STATUS.md for the current handoff. Then inspect only the scripts, assets, and notes relevant to the request. Do not reread the entire chat history or every backup by default.

The actual game lives in Roblox Studio, place 94130990350526 (`money`). This folder contains project memory, source snapshots, builders, and backups; it is not a complete exported game or an automatic Studio sync. Inspect the connected place and current sources before editing. Refresh Studio IDs each session. Prefer Studio tools for game changes.

Follow the user's latest request over older project notes. Implement authorized changes directly, preserve unrelated work, and use concise nontechnical updates. Do not turn routine reversible work into repeated approval requests. Keep gameplay changes consistent with the approved design. Keep removed/replaced assets recoverable.

When running isolated progression tests, set ServerStorage.BalanceTestMode=true in Edit before Play. This isolates the main progression DataService only, not every third-party system. Stop Play and remove the attribute in Edit afterward. If disconnected, record cleanup as pending. Never claim persistence or publishing was tested when it was not.

Codex and Claude may edit the same live place. Re-read an affected source before applying a prepared patch; do not overwrite newer changes or run simultaneous writers against the same assets. A project file is a handoff, not an automatic cross-app synchronization system.

After meaningful work, update STATUS.md with what changed, evidence from checks, unresolved issues, and the next action. Update PROJECT.md only when a lasting decision changes. Keep both concise. Separate implemented, tested, and published state. Do not publish or reset real player data without the user's instruction.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are not a reason to skip graphify. Only skip graphify if the task is about stale or incorrect graph output, or the user explicitly says not to use it.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify extract game --code-only --out . --max-workers 2` to keep the graph current (AST-only, no API cost).

Graphify scope: scan only game/; outputs are in the project-root graphify-out/. Source paths in the graph are relative to game/. After extraction, run `graphify cluster-only . --no-label` to refresh the report and HTML. Model files (.rbxm), Studio-only objects, historical builders and uploaded chat context are outside this graph. Use the graph to locate relevant sources, then verify current source and Studio state; Lua parsing does not prove Roblox runtime relationships.


Egg exception: game/studio-snapshots/ holds read-only PetClient and EggFloat copies for indexing, outside Rojo mappings. Snapshot source paths point to copies, not editable live sources. Refresh them from Studio when relevant before rebuilding Graphify; disk refresh alone cannot capture Studio edits.

