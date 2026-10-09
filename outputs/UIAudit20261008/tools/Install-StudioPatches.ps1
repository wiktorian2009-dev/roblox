<#
.SYNOPSIS
  Merge the 2026-10-08 UI-audit patches onto the CURRENT Studio scripts, then walk you through pasting them in.

.DESCRIPTION
  The 7 Studio-only scripts (StarterGui.RNGGui.*, ReplicatedFirst.LoadingScreen) are not mapped by game\default.project.json,
  so `rojo serve` cannot sync them. This script:
    1. runs `rojo syncback` on a SAVED COPY of your place, writing only into game\tmp\live (never game\src),
    2. three-way merges each patch onto that live version with `git merge-file`
       (live script + the 2026-10-02 snapshot it was patched from + the patched copy), so newer Studio edits are kept,
    3. writes the results to game\tmp\merged and, unless -NoPaste, copies them to the clipboard one at a time for pasting.
  It never talks to Studio, never edits game\src or game\studio-snapshots, and never publishes.
  Scripts with merge conflicts are NOT offered for pasting; they are written as <Name>.CONFLICT.luau with conflict markers.

.PARAMETER Place         Path to a saved copy of the place: in Studio, File > Save to File As ... money.rbxl
.PARAMETER SkipSyncback  Reuse game\tmp\live from an earlier run.
.PARAMETER NoPaste       Only produce game\tmp\merged; skip the clipboard walk-through.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File outputs\UIAudit20261008\tools\Install-StudioPatches.ps1 -Place "$env:USERPROFILE\Desktop\money.rbxl"

.NOTES
  Needs git and Rojo 7.5 or newer. NOT run in the cloud session that wrote it (no PowerShell/Rojo there); the merge step itself was
  tested with git on the real patches. Install order matters: RNGClient first.
#>
[CmdletBinding()]
param(
    [string]$Place = "",
    [switch]$SkipSyncback,
    [switch]$NoPaste
)
$ErrorActionPreference = "Stop"

$repo    = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
$game    = Join-Path $repo "game"
$live    = Join-Path $game "tmp\live"
$work    = Join-Path $game "tmp\work"
$merged  = Join-Path $game "tmp\merged"
$patches = Join-Path $repo "outputs\UIAudit20261008\studio-patches"
$snaps   = Join-Path $game "studio-snapshots"
$proj    = Join-Path $game "syncback-live.project.json"
$utf8    = New-Object System.Text.UTF8Encoding($false)

# install order: RNGClient first
$items = @(
    @{ Name = "RNGClient";         Sub = "StarterGui\RNGGui"; Studio = "StarterGui.RNGGui.RNGClient" },
    @{ Name = "UpgradeTreeClient"; Sub = "StarterGui\RNGGui"; Studio = "StarterGui.RNGGui.UpgradeTreeClient" },
    @{ Name = "PetClient";         Sub = "StarterGui\RNGGui"; Studio = "StarterGui.RNGGui.PetClient" },
    @{ Name = "ActivityClient";    Sub = "StarterGui\RNGGui"; Studio = "StarterGui.RNGGui.ActivityClient" },
    @{ Name = "WheelClient";       Sub = "StarterGui\RNGGui"; Studio = "StarterGui.RNGGui.WheelClient" },
    @{ Name = "TreasureReveal";    Sub = "StarterGui\RNGGui"; Studio = "StarterGui.RNGGui.TreasureReveal" },
    @{ Name = "LoadingScreen";     Sub = "ReplicatedFirst";   Studio = "ReplicatedFirst.LoadingScreen" }
)

function Read-Lf([string]$path) {
    return ([IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)).Replace("`r`n", "`n")
}
function Write-Lf([string]$path, [string]$text) {
    $dir = Split-Path $path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [IO.File]::WriteAllText($path, $text, $utf8)
}
function Find-Live([string]$sub, [string]$name) {
    $dir = Join-Path $live $sub
    foreach ($c in @("$name.client.luau", "$name.client.lua", "$name.luau", "$name.lua",
                     "$name\init.client.luau", "$name\init.client.lua", "$name\init.luau", "$name\init.lua")) {
        $p = Join-Path $dir $c
        if (Test-Path $p) { return $p }
    }
    return $null
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw "git was not found on PATH." }

# ---- 1. syncback the live scripts (Studio -> files), into game\tmp\live only
if (-not $SkipSyncback) {
    if (-not (Get-Command rojo -ErrorAction SilentlyContinue)) { throw "rojo was not found on PATH." }
    if (-not $Place -or -not (Test-Path $Place)) {
        throw "Pass -Place <saved copy of the place>. In Studio: File > Save to File As ... money.rbxl (a COPY; do not use the file you are editing live)."
    }
    Write-Host ("Using " + ((& rojo --version) -join " ") + "  (syncback needs Rojo 7.5 or newer)")
    if (Test-Path $live) { Remove-Item $live -Recurse -Force }
    & rojo syncback $proj --input $Place --non-interactive
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "rojo syncback failed with --non-interactive (exit $LASTEXITCODE); retrying without it (answer its prompt if it asks)."
        & rojo syncback $proj --input $Place
    }
    if ($LASTEXITCODE -ne 0) { throw "rojo syncback failed (exit $LASTEXITCODE). Run 'rojo syncback --help' and check your Rojo version." }
}
elseif (-not (Test-Path $live)) {
    throw "-SkipSyncback was given but $live does not exist."
}

# ---- 2. three-way merge each patch onto the live version
if (Test-Path $work)   { Remove-Item $work -Recurse -Force }
if (Test-Path $merged) { Remove-Item $merged -Recurse -Force }
$results = @()
foreach ($it in $items) {
    $name      = $it.Name
    $liveFile  = Find-Live $it.Sub $name
    $baseFile  = Join-Path $snaps (Join-Path $it.Sub "$name.client.luau")
    $patchFile = Join-Path $patches (Join-Path $it.Sub "$name.client.luau")
    if (-not $liveFile) {
        $results += [pscustomobject]@{ Order = $results.Count + 1; Script = $name; Status = "MISSING in syncback output"; Conflicts = ""; Studio = $it.Studio; Out = "" }
        continue
    }
    $liveText  = Read-Lf $liveFile
    $baseText  = Read-Lf $baseFile
    # the patch copy starts with a one-line "INSTALL PENDING" header comment: drop it before merging
    $otherText = (Read-Lf $patchFile) -replace '^--\[\[ UIAUDIT 20261008 PATCH[^\n]*\]\]\n', ''
    $wLive  = Join-Path $work "$name.live.luau"
    $wBase  = Join-Path $work "$name.base.luau"
    $wOther = Join-Path $work "$name.other.luau"
    Write-Lf $wLive  $liveText
    Write-Lf $wBase  $baseText
    Write-Lf $wOther $otherText
    & git merge-file $wLive $wBase $wOther    # merges INTO $wLive; exit code = number of conflicts, 128+ = error
    $code = $LASTEXITCODE
    $text = Read-Lf $wLive
    if ($code -ge 128 -or $code -lt 0) {
        $results += [pscustomobject]@{ Order = $results.Count + 1; Script = $name; Status = "ERROR (git merge-file exit $code)"; Conflicts = ""; Studio = $it.Studio; Out = "" }
    }
    elseif ($code -gt 0) {
        $out = Join-Path $merged "$name.CONFLICT.luau"
        Write-Lf $out $text
        $results += [pscustomobject]@{ Order = $results.Count + 1; Script = $name; Status = "CONFLICT - resolve by hand"; Conflicts = $code; Studio = $it.Studio; Out = $out }
    }
    elseif ($text -eq $liveText) {
        $results += [pscustomobject]@{ Order = $results.Count + 1; Script = $name; Status = "NO CHANGE (already installed?)"; Conflicts = 0; Studio = $it.Studio; Out = "" }
    }
    else {
        $out = Join-Path $merged "$name.client.luau"
        Write-Lf $out $text
        $results += [pscustomobject]@{ Order = $results.Count + 1; Script = $name; Status = "CLEAN"; Conflicts = 0; Studio = $it.Studio; Out = $out }
    }
}

Write-Host ""
Write-Host ("{0,-3} {1,-18} {2,-32} {3,-9} {4}" -f "#", "Script", "Status", "Conflicts", "Studio script")
foreach ($r in $results) {
    Write-Host ("{0,-3} {1,-18} {2,-32} {3,-9} {4}" -f $r.Order, $r.Script, $r.Status, $r.Conflicts, $r.Studio)
}
Write-Host "Merged files: $merged"
Write-Host "Conflict files contain <<<<<<< markers: open them in VS Code, resolve, and paste by hand. Never paste a CONFLICT file as is."

# ---- 3. walk through pasting the clean ones into Studio (manual: this script cannot reach Studio)
if (-not $NoPaste) {
    foreach ($r in ($results | Where-Object { $_.Status -eq "CLEAN" })) {
        Set-Clipboard -Value ([IO.File]::ReadAllText($r.Out, [Text.Encoding]::UTF8))
        Write-Host ""
        Write-Host ("[{0}/{1}] Copied {2} to the clipboard." -f $r.Order, $items.Count, $r.Script) -ForegroundColor Green
        Write-Host ("  In Studio open  " + $r.Studio + "  (Explorer, double-click), press Ctrl+A then Ctrl+V.")
        Read-Host "  Press Enter for the next one (Ctrl+C stops)" | Out-Null
    }
    Write-Host ""
    Write-Host "Done. Nothing was published. Remove game\tmp when finished (it is git-ignored)."
}
