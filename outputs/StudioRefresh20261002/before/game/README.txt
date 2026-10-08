Rojo project for "money" (94130990350526)

default.project.json  - used for live sync (rojo serve). Leaves anything
                        not on disk alone in Studio.
syncback.project.json - used once to copy scripts out of a saved place.

Covered: ReplicatedStorage, ServerScriptService, StarterGui,
StarterPlayerScripts. NOT covered yet: Workspace scripts and ServerStorage
(backups, admin, ShovelModelBuilder) - edit those in Studio.
