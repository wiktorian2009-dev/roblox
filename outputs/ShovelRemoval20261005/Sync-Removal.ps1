$ErrorActionPreference = 'Stop'
$project = 'C:\Users\wikto\Desktop\Roblox Gra'
$work = 'C:\Users\wikto\Documents\Codex\2026-09-29\ca\outputs\ShovelRemoval20261005'
$archive = Join-Path $project 'outputs\ShovelRemoval20261005'
$gameRoot = [IO.Path]::GetFullPath((Join-Path $project 'game'))
$outRoot = [IO.Path]::GetFullPath((Join-Path $project 'outputs'))
$utf8 = New-Object System.Text.UTF8Encoding($false)
New-Item -ItemType Directory -Path $archive -Force | Out-Null
$sources = Get-Content -LiteralPath (Join-Path $work 'final-sources.json') -Raw | ConvertFrom-Json
$manifest = @()
foreach ($item in $sources) {
  $segments = $item.path.Split('.')
  $tree = if ($segments[0] -in @('ReplicatedStorage','ServerScriptService','StarterPlayer')) {'src'} else {'studio-snapshots'}
  $stem = Join-Path (Join-Path $gameRoot $tree) ($segments -join '\')
  $suffix = if ($item.class -eq 'ModuleScript') {'.luau'} elseif ($item.class -eq 'LocalScript') {'.client.luau'} else {'.server.luau'}
  $target = [IO.Path]::GetFullPath($stem + $suffix)
  if (-not $target.StartsWith($gameRoot + '\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Source target escaped game root' }
  if (Test-Path -LiteralPath $target) {
    $rel = $target.Substring($gameRoot.Length + 1)
    $before = Join-Path (Join-Path $archive 'disk-before') $rel
    New-Item -ItemType Directory -Path (Split-Path -Parent $before) -Force | Out-Null
    Copy-Item -LiteralPath $target -Destination $before
  }
  New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
  [IO.File]::WriteAllText($target,$item.source,$utf8)
  if ([IO.File]::ReadAllText($target) -cne $item.source) { throw "Mirror mismatch: $target" }
  $manifest += [pscustomobject]@{Path=$item.path;Class=$item.class;File=$target;SHA256=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash}
}
$obsolete = @(
'src\ServerScriptService\RNGHandler.server.luau',
'src\ServerScriptService\StarterShovelRules.luau',
'src\ServerScriptService\SnowIntroService.server.luau',
'src\StarterPlayer\StarterPlayerScripts\ShovelOrbit.client.luau',
'src\StarterPlayer\StarterPlayerScripts\TutorialClient.client.luau',
'src\StarterPlayer\StarterPlayerScripts\SnowIntro.client.luau',
'src\StarterPlayer\StarterPlayerScripts\RareAnnounceClient.client.luau',
'studio-snapshots\StarterGui\RNGGui\RollController.client.luau',
'studio-snapshots\StarterGui\RNGGui\RareDropCutscene.luau',
'studio-snapshots\StarterGui\RNGGui\DiceMeter.client.luau',
'studio-snapshots\ServerStorage\ShovelModelBuilder.luau',
'src\ReplicatedStorage\RNGConfig.luau',
'src\ReplicatedStorage\ItemIcon.luau',
'src\ReplicatedStorage\Balance.luau',
'src\ReplicatedStorage\SnowIntroArt.luau',
'src\ReplicatedStorage\SnowIntroController.luau',
'src\ReplicatedStorage\SnowIntroRig.luau',
'src\ReplicatedStorage\ShovelModels',
'src\ReplicatedStorage\RollRNG.model.json',
'src\ReplicatedStorage\GetInventory.model.json',
'src\ReplicatedStorage\EquipShovel.model.json',
'src\ReplicatedStorage\SnowIntroRequest.model.json'
)
$moved = @()
foreach ($rel in $obsolete) {
  $source = [IO.Path]::GetFullPath((Join-Path $gameRoot $rel))
  $destination = [IO.Path]::GetFullPath((Join-Path (Join-Path $archive 'disk-removed') $rel))
  if (-not $source.StartsWith($gameRoot + '\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Move source escaped game root' }
  if (-not $destination.StartsWith($outRoot + '\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Move destination escaped outputs root' }
  if (Test-Path -LiteralPath $source) {
    if (Test-Path -LiteralPath $destination) { throw "Already archived: $destination" }
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    Move-Item -LiteralPath $source -Destination $destination
    $moved += $rel
  }
}
Get-ChildItem -LiteralPath $work -File | Copy-Item -Destination $archive
foreach ($dir in @('before','after')) { if (Test-Path -LiteralPath (Join-Path $work $dir)) { Copy-Item -LiteralPath (Join-Path $work $dir) -Destination $archive -Recurse } }
[IO.File]::WriteAllText((Join-Path $archive 'source-mirror-manifest.json'),($manifest | ConvertTo-Json -Depth 6),$utf8)
[IO.File]::WriteAllText((Join-Path $archive 'disk-removed-manifest.json'),($moved | ConvertTo-Json),$utf8)
[pscustomobject]@{Mirrored=$manifest.Count;ArchivedDiskRoots=$moved.Count;Archive=$archive} | ConvertTo-Json

