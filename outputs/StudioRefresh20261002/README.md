# Studio refresh — 2026-10-02

Source: current Edit place money (94130990350526), checked against the user-provided [Claude handoff](https://claude.ai/share/b10727c7-f0a2-43bc-93d3-522724d58540).

## Result

68 current source files mirror live Edit: 45 in game/src and 23 read-only Studio references. 27 new files, 14 changed, 27 already matching. Two duplicate generic Workspace.Script sources are archive-only. SHA-256, actual ClassName/RunContext and original Studio paths are recorded in sync-report.json; source snapshots in live-sources.json.

Added existing TreasureRemote/TreasureFound declarations. Seven mapped SnowStages economic attribute sets matched; ignoreUnknownInstances on SnowStages preserves the unmapped Sakura template. [Rojo metadata reference](https://rojo.space/docs/v7/sync-details/).

Graphify rebuilt to 530 nodes / 1,027 edges / 42 communities. Partial AST warnings for UpgradeTreeClient and PortalAnimator at compound assignments are documented in STATUS.md. A scoped Activities query successfully locates the new config/service/client.

Updated PROJECT.md, STATUS.md, AGENTS.md, CLAUDE.md, PROJECT-INSTRUCTIONS.txt and source READMEs. Before copies are recoverable under before/. No gameplay patch, Play test, save, publishing or player-data reset by this refresh.

## Claude handoff

For Claude on the laptop or without access to the shared Windows folder, replace the uploaded PROJECT.md, STATUS.md, graph.json and GRAPH_REPORT.md with the current files. The ZIP contains these plus current source copies, mappings, manifests and this README; uploaded copies will not refresh automatically. Some Claude file pickers require extracting the ZIP and uploading individual Markdown/JSON files.

Only read sources relevant to the next task; the package does not mean every source must be read on every turn.

## Limits

This is NOT a complete place backup or rebuildable game export. Existing .rbxm models were not re-exported or verified; GUI hierarchy, map/lighting instances and the Sakura template are in Studio. Live source equality is as of the recorded capture. The local Rojo endpoint timed out, so server/plugin connection and directory are unverified. Before connecting Rojo, verify the canonical folder and review proposed changes; never use the historical ca/game copy.

Claude's shared chat reports Activities and portal Play checks, but the final balance price adjustment was after those tests. Model timings are estimates. Open issues and recovery references are in the current STATUS.md.

