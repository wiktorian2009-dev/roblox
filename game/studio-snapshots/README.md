# Studio-only source snapshots

Captured from **money (94130990350526), Edit, 2026-10-02**. These 23 scripts are read-only reference copies for Graphify and are outside default.project.json mappings.

Included: 13 StarterGui.RNGGui scripts/modules, ReplicatedFirst loading/biome lighting plus Profiles, Workspace portal/egg/palette scripts, and four active ServerStorage helpers (AdminConfig, AdminConsole.ConsoleClient, ShovelModelBuilder, older SnowFields helper).

Edit the actual Studio source, then refresh its snapshot. Editing one of these files does not install it into Studio. Paths, actual ClassName, Disabled, RunContext and SHA-256 are recorded in ../../outputs/StudioRefresh20261002/sync-report.json. PortalAnimator and EggFloat are **Scripts with RunContext=Client** despite the .server.luau filenames, which reflect their ClassName. Two duplicate generic Workspace.Script sources are archive-only.

live-instance-summary.json records current remote classes, SnowStages attributes, field names, Rewards presence, backups and World 2 facts. It is not a serialized place, GUI or mesh export.

Old flattened UpgradeTreeClient and misclassified EggFloat snapshots, plus the unmapped game/src/ReplicatedFirst/LoadingScreen copy, were archived before consolidating them here. Existing binary models were not changed.

Graphify refresh: 530 nodes / 1,027 edges / 42 communities. UpgradeTreeClient and PortalAnimator produced partial AST warnings near compound assignments; consult their live sources for full context. No Play, save, persistence or publishing test was performed by this source refresh.
