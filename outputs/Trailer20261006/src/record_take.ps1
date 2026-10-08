# record_take.ps1 (2026-10-06, Claude): starts the OBS "Trailer" recording and watches it (DESIGN rev 2, sections 12.3 and 12.6).
# Everything is read-only except: creating outputs\Trailer, copying user.ini to outputs\Trailer\obs-user.ini.bak, launching OBS and
# appending to outputs\Trailer\watchdog.log. It never stops or kills OBS or Studio (no Stop-Process anywhere).
#   1. refuses if obs64 is already running (stop and ask wiktor);
#   2. launches obs64.exe --profile/--collection/--scene "Trailer" --startrecording --minimize-to-tray --disable-updater
#      --disable-shutdown-check (recording ends by the profile's Output Timer, or wiktor stops it from the tray);
#   3. READY <file> once a NEW Trailer_take_* file grows for 2 s (timeout 20 s);
#   4. every 2 s: STATUS free RAM / Studio + OBS working sets / file size; LOW_RAM under 1.5 GB free (Claude then stops Play through
#      the MCP or sets TrailerAbort - PowerShell cannot call Studio); MARKER lines when the newest Studio log shows [Trailer] markers
#      (best effort, read-only); exits when the file stopped growing for 5 s after growing, or after 10 min.
#   Watch only (OBS started some other way, e.g. obs-websocket StartRecord): -NoLaunch.
#   -RestoreUserIni (review fix; run after wiktor closed OBS, last teardown step): refuses while obs64 runs, backs up the current
#      user.ini, then writes back ONLY the four [Basic] keys Profile / ProfileDir / SceneCollection / SceneCollectionFile from the
#      FIRST backup (outputs\Trailer\obs-user.ini.bak; later stamped backups already point at Trailer). UTF-8 without BOM.
[CmdletBinding()]
param(
	[switch]$RestoreUserIni,
	[switch]$NoLaunch,
	[string]$OutDir = "C:\Users\wikto\Desktop\Roblox Gra\outputs\Trailer",
	[double]$LowRamGB = 1.5,
	[int]$MaxMinutes = 10,
	[int]$ReadyTimeout = 20,
	[switch]$NoStudioLog
)
$ErrorActionPreference = "Stop"
$obsExe = "C:\Program Files\obs-studio\bin\64bit\obs64.exe"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$logFile = Join-Path $OutDir "watchdog.log"
function Say([string]$s) {
	$line = "{0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"), $s
	Write-Output $line
	Add-Content -LiteralPath $logFile -Value $line -Encoding UTF8
}
function Get-Takes { @(Get-ChildItem -LiteralPath $OutDir -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "Trailer_take_*" }) }

if ($RestoreUserIni) {
	$keys = @("Profile", "ProfileDir", "SceneCollection", "SceneCollectionFile")
	if (Get-Process -Name obs64 -ErrorAction SilentlyContinue) { Say "REFUSED: OBS is running - restore user.ini after wiktor closes OBS (never Stop-Process OBS)"; exit 2 }
	$userIni = Join-Path $env:APPDATA "obs-studio\user.ini"
	$first = Join-Path $OutDir "obs-user.ini.bak"
	if (-not (Test-Path -LiteralPath $first)) { Say "REFUSED: $first not found (no first backup to restore from)"; exit 2 }
	if (-not (Test-Path -LiteralPath $userIni)) { Say "REFUSED: $userIni not found"; exit 2 }
	$utf8 = New-Object Text.UTF8Encoding($false)
	function Read-Basic([string[]]$lines) {
		$sec = ""; $h = @{}
		foreach ($l in $lines) {
			if ($l -match '^\s*\[(.+)\]\s*$') { $sec = $Matches[1]; continue }
			if ($sec -eq "Basic" -and $l -match '^([^=]+)=(.*)$') { $h[$Matches[1].Trim()] = $Matches[2] }
		}
		return $h
	}
	$want = Read-Basic ([IO.File]::ReadAllLines($first, [Text.Encoding]::UTF8))
	if ($want["Profile"] -eq "Trailer" -or $want["SceneCollection"] -eq "Trailer") {
		Say "REFUSED: the first backup already points at Trailer - pick wiktor's profile and scene collection in OBS's menus instead"; exit 2
	}
	$lines = [IO.File]::ReadAllLines($userIni, [Text.Encoding]::UTF8)
	$stampBak = Join-Path $OutDir ("obs-user.ini.before-restore.{0}.bak" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
	Copy-Item -LiteralPath $userIni -Destination $stampBak
	$out = New-Object System.Collections.Generic.List[string]
	$sec = ""; $done = @{}; $sawBasic = $false
	$flush = {
		if ($sec -eq "Basic") { foreach ($k in $keys) { if (-not $done[$k] -and $want.ContainsKey($k)) { $out.Add("$k=" + $want[$k]); $done[$k] = $true } } }
	}
	foreach ($l in $lines) {
		if ($l -match '^\s*\[(.+)\]\s*$') { & $flush; $sec = $Matches[1]; if ($sec -eq "Basic") { $sawBasic = $true }; $out.Add($l); continue }
		if ($sec -eq "Basic" -and $l -match '^([^=]+)=' -and $keys -contains $Matches[1].Trim()) {
			$k = $Matches[1].Trim()
			if ($want.ContainsKey($k)) { $out.Add("$k=" + $want[$k]); $done[$k] = $true } else { $out.Add($l) }
			continue
		}
		$out.Add($l)
	}
	& $flush
	if (-not $sawBasic) { $out.Add("[Basic]"); $sec = "Basic"; & $flush }
	[IO.File]::WriteAllLines($userIni, $out, $utf8)
	Say ("user.ini [Basic] restored from {0}: {1} (previous user.ini saved as {2})" -f $first, (($keys | Where-Object { $want.ContainsKey($_) } | ForEach-Object { "$_=" + $want[$_] }) -join "; "), $stampBak)
	exit 0
}

$before = @{}
Get-Takes | ForEach-Object { $before[$_.FullName] = $true }

if (-not $NoLaunch) {
	if (Get-Process -Name obs64 -ErrorAction SilentlyContinue) {
		Say "REFUSED: OBS is already running - stop here and ask wiktor (never Stop-Process OBS)."
		exit 2
	}
	if (-not (Test-Path $obsExe)) { Say "REFUSED: $obsExe not found"; exit 2 }
	$obs = Join-Path $env:APPDATA "obs-studio"
	foreach ($need in @("basic\profiles\Trailer\basic.ini", "basic\scenes\Trailer.json")) {
		if (-not (Test-Path (Join-Path $obs $need))) { Say "REFUSED: $need missing - run obs_trailer_setup.ps1 first"; exit 2 }
	}
	$userIni = Join-Path $obs "user.ini"
	if (Test-Path $userIni) {
		$bak = Join-Path $OutDir "obs-user.ini.bak"
		if (Test-Path $bak) { $bak = Join-Path $OutDir ("obs-user.ini.{0}.bak" -f (Get-Date -Format "yyyyMMdd-HHmmss")) }
		Copy-Item -LiteralPath $userIni -Destination $bak
		Say "user.ini backed up to $bak (launching with --profile makes Trailer OBS's last-used profile)"
	}
	Start-Process -FilePath $obsExe -WorkingDirectory (Split-Path $obsExe) -ArgumentList '--profile "Trailer" --collection "Trailer" --scene "Trailer" --startrecording --minimize-to-tray --disable-updater --disable-shutdown-check'
	Say "OBS launched with the Trailer profile (--startrecording)"
}

# READY: a new take file that grows for 2 s
$file = $null
$t0 = Get-Date
while (((Get-Date) - $t0).TotalSeconds -lt $ReadyTimeout) {
	$new = Get-Takes | Where-Object { -not $before[$_.FullName] } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
	if ($new) {
		$s1 = $new.Length
		Start-Sleep -Seconds 2
		$new.Refresh()
		if ($new.Length -gt $s1) { $file = $new; break }
	} else {
		Start-Sleep -Milliseconds 500
	}
}
if (-not $file) { Say "NOT_READY: no new growing Trailer_take_* file in $OutDir after $ReadyTimeout s"; exit 3 }
Say "READY $($file.FullName)"

# newest Studio log (read-only, shared read so Studio keeps writing)
$studioLog = $null
$studioPos = 0L
if (-not $NoStudioLog) {
	$dir = Join-Path $env:LOCALAPPDATA "Roblox\logs"
	$studioLog = Get-ChildItem -LiteralPath $dir -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*Studio*" -and $_.LastWriteTime -gt (Get-Date).AddMinutes(-60) } |
		Sort-Object LastWriteTime -Descending | Select-Object -First 1
	if ($studioLog) { $studioPos = $studioLog.Length; Say "watching Studio log $($studioLog.Name) for [Trailer] markers (best effort)" }
	else { Say "no recent Studio log found - markers come from Studio Output only" }
}
function Read-StudioMarkers {
	if (-not $script:studioLog) { return }
	try {
		$fs = [IO.File]::Open($script:studioLog.FullName, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
		try {
			if ($fs.Length -le $script:studioPos) { return }
			[void]$fs.Seek($script:studioPos, [IO.SeekOrigin]::Begin)
			$sr = New-Object IO.StreamReader($fs)
			$text = $sr.ReadToEnd()
			$script:studioPos = $fs.Length
			foreach ($m in [regex]::Matches($text, "\[Trailer\] (TRAILER_[A-Z_]+|SLATE_[A-Z]+|ABORT|BUG|restore report)[^\r\n]*")) { Say ("MARKER " + $m.Value) }
		} finally { $fs.Dispose() }
	} catch { }
}

$grew = $false
$lastSize = $file.Length
$lastGrow = Get-Date
$start = Get-Date
$minFree = [double]::MaxValue
while (((Get-Date) - $start).TotalMinutes -lt $MaxMinutes) {
	Start-Sleep -Seconds 2
	$file.Refresh()
	$freeGB = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)
	$minFree = [math]::Min($minFree, $freeGB)
	$studioGB = ((Get-Process -Name RobloxStudioBeta -ErrorAction SilentlyContinue | Measure-Object WorkingSet64 -Sum).Sum) / 1GB
	$obsGB = ((Get-Process -Name obs64 -ErrorAction SilentlyContinue | Measure-Object WorkingSet64 -Sum).Sum) / 1GB
	if ($file.Length -gt $lastSize) { $grew = $true; $lastGrow = Get-Date; $lastSize = $file.Length }
	Say ("STATUS free={0:N2}GB studio={1:N2}GB obs={2:N2}GB file={3:N1}MB" -f $freeGB, $studioGB, $obsGB, ($file.Length / 1MB))
	if ($freeGB -lt $LowRamGB) { Say ("LOW_RAM free={0:N2}GB < {1}GB - Claude: stop Play (MCP start_stop_play) or set TrailerAbort=true on the Server" -f $freeGB, $LowRamGB) }
	Read-StudioMarkers
	if ($grew -and ((Get-Date) - $lastGrow).TotalSeconds -ge 5) { Say "STOPPED: the recording stopped growing"; break }
}
if (((Get-Date) - $start).TotalMinutes -ge $MaxMinutes) { Say "TIMEOUT: watched $MaxMinutes min (OBS keeps recording until its Output Timer or the tray stop)" }
Say ("DONE file={0} size={1:N1}MB minFree={2:N2}GB (round 2 rule: under 3 GB free -> split take)" -f $file.FullName, ($file.Length / 1MB), $minFree)
if (-not $NoLaunch) { Say "REMINDER: after wiktor closes OBS for the last time, run: record_take.ps1 -RestoreUserIni (puts wiktor's OBS profile back)" }
