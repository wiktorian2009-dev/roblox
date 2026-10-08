# Shared Roblox game folder

Use this same local folder in both Codex and Claude:

`C:\Users\wikto\Desktop\Roblox Gra`

## Codex

Open/add this folder as a local project for future chats. This chat still starts in the old Documents folder; it can access the shared folder explicitly. A sidebar project has not been registered by this task.

## Claude

Your screenshot shows Roblox Gra attached as a local folder. Ask Claude to read PROJECT.md and STATUS.md from that folder to verify access. Use the current local files rather than earlier uploaded copies. PROJECT-INSTRUCTIONS.txt contains the updated text for your project instructions.

## Handoff

Start a task with: "Read PROJECT.md and STATUS.md from the shared Roblox Gra folder, then continue with my request."

AGENTS.md contains shared rules; CLAUDE.md points to them. After meaningful work, update the shared STATUS.md. Update PROJECT.md for lasting decisions. Both assistants must reread affected sources before editing. Keep one assistant editing a given Studio system at a time.

The folder shares files, not conversation history. Roblox Studio remains the actual game; these files are not automatic game synchronization. Historical builders and snapshots are in work/ and outputs/. Do not blindly rerun them.

## Pending Studio cleanup

Studio disconnected during the last playtest. Stop Play if needed and remove ServerStorage.BalanceTestMode in Edit. Cleanup, saving and publishing remain unverified; see STATUS.md.
