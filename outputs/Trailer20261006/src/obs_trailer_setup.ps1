# obs_trailer_setup.ps1 (2026-10-06, Claude): creates the NEW OBS profile + scene collection "Trailer" (DESIGN rev 2, section 12.2).
# Writes ONLY: %APPDATA%\obs-studio\basic\profiles\Trailer\basic.ini, ...\Trailer\recordEncoder.json,
#              %APPDATA%\obs-studio\basic\scenes\Trailer.json, and creates the output folder outputs\Trailer.
# Never touches wiktor's existing profile / collection ("Bez tytulu"), user.ini or global.ini. Refuses while OBS is running.
# Refuses to overwrite an existing Trailer profile / collection unless -Force (then the old files are copied to *.bak-<stamp> first).
#
#   Full-screen path (ffmpeg present or allowed):  .\obs_trailer_setup.ps1
#   No-ffmpeg path (crop in OBS from the rehearsal slate box, section 12.4):
#       .\obs_trailer_setup.ps1 -NoFfmpeg -CropLeft <L> -CropTop <T> -CropRight <R> -CropBottom <B>   (pixels of the 2560x1440 desktop)
#   30 fps (round 2 rule, section 12.5): add -Fps 30.   Preview only: -DryRun.
[CmdletBinding()]
param(
	[ValidateSet(60, 30)][int]$Fps = 60,
	[switch]$NoFfmpeg,
	[int]$CropLeft = 0, [int]$CropTop = 0, [int]$CropRight = 0, [int]$CropBottom = 0,
	[string]$OutDir = "C:\Users\wikto\Desktop\Roblox Gra\outputs\Trailer",
	[int]$TimerMinutes = 9,
	[switch]$Force,
	[switch]$DryRun
)
$ErrorActionPreference = "Stop"
$utf8 = New-Object System.Text.UTF8Encoding($false)

if (Get-Process -Name obs64 -ErrorAction SilentlyContinue) {
	Write-Output "REFUSED: OBS is running. Ask wiktor to close OBS (never Stop-Process it), then run this again."
	exit 2
}
$obs = Join-Path $env:APPDATA "obs-studio"
if (-not (Test-Path $obs)) { Write-Output "REFUSED: $obs not found (is OBS installed for this user?)"; exit 2 }
$profileDir = Join-Path $obs "basic\profiles\Trailer"
$sceneFile = Join-Path $obs "basic\scenes\Trailer.json"
$targets = @((Join-Path $profileDir "basic.ini"), (Join-Path $profileDir "recordEncoder.json"), $sceneFile)
$existing = @($targets | Where-Object { Test-Path $_ })
if ($existing.Count -gt 0 -and -not $Force) {
	Write-Output "REFUSED: Trailer files already exist (use -Force to replace them; they are backed up first):"
	$existing | ForEach-Object { Write-Output "  $_" }
	exit 2
}

# ---- main monitor (read-only): size and the device interface path OBS uses as monitor_id ----
Add-Type -AssemblyName System.Windows.Forms
if (-not ("TrailerDisplay" -as [type])) {
	Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class TrailerDisplay {
	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
	public struct DISPLAY_DEVICE {
		public int cb;
		[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string DeviceName;
		[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceString;
		public int StateFlags;
		[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceID;
		[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceKey;
	}
	[DllImport("user32.dll", CharSet = CharSet.Unicode)]
	public static extern bool EnumDisplayDevices(string lpDevice, uint iDevNum, ref DISPLAY_DEVICE lpDisplayDevice, uint dwFlags);
	[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
	public static string MonitorInterface(string adapter) {
		DISPLAY_DEVICE d = new DISPLAY_DEVICE();
		d.cb = Marshal.SizeOf(d);
		if (EnumDisplayDevices(adapter, 0, ref d, 1)) return d.DeviceID; // EDD_GET_DEVICE_INTERFACE_NAME
		return null;
	}
}
"@
}
[void][TrailerDisplay]::SetProcessDPIAware()  # this PowerShell process only, so Screen reports physical pixels
$primary = [System.Windows.Forms.Screen]::PrimaryScreen
$monW, $monH = $primary.Bounds.Width, $primary.Bounds.Height
$monitorId = [TrailerDisplay]::MonitorInterface($primary.DeviceName)
if (-not $monitorId) { $monitorId = ""; Write-Output "WARNING: monitor id not resolved - pick the main monitor in the Display Capture properties." }
if ($monW -ne 2560 -or $monH -ne 1440) { Write-Output "WARNING: primary monitor is ${monW}x${monH}, the spec expects 2560x1440." }

if ($NoFfmpeg) {
	$baseW, $baseH, $outW, $outH = 1920, 1080, 1920, 1080
	$cropW = $monW - $CropLeft - $CropRight
	$cropH = $monH - $CropTop - $CropBottom
	if ($cropW -le 0 -or $cropH -le 0) { Write-Output "REFUSED: crop leaves nothing (${cropW}x${cropH})"; exit 2 }
	$ratio = $cropW / $cropH
	if ([math]::Abs($ratio - 16 / 9) -gt 0.002) { Write-Output ("WARNING: crop box {0}x{1} is not 16:9 ({2:N4})" -f $cropW, $cropH, $ratio) }
} else {
	$baseW, $baseH, $outW, $outH = $monW, $monH, $monW, $monH
}

function New-Uuid { [guid]::NewGuid().ToString() }
$canvas = "6c69626f-6273-4c00-9d88-c5136d61696e"  # OBS main canvas uuid (as in wiktor's collection)
$prevVer = 537001986                              # OBS 32.2.2 (0x20020002), as in wiktor's collection
function New-Source([string]$name, [string]$id, $settings, [bool]$muted, $filters, [int]$mixers) {
	$s = [ordered]@{
		prev_ver = $prevVer; name = $name; uuid = (New-Uuid); id = $id; versioned_id = $id; settings = $settings
		mixers = $mixers; sync = 0; flags = 0; volume = 1.0; balance = 0.5; enabled = $true; muted = $muted
		"push-to-mute" = $false; "push-to-mute-delay" = 0; "push-to-talk" = $false; "push-to-talk-delay" = 0
		hotkeys = @{}; deinterlace_mode = 0; deinterlace_field_order = 0; monitoring_type = 0; private_settings = @{}
	}
	if ($filters) { $s.filters = @($filters) }
	return $s
}
function New-SceneItem([string]$name, [string]$uuid, [int]$id, [bool]$cropBounds) {
	$item = [ordered]@{
		name = $name; source_uuid = $uuid; visible = $true; locked = $true; rot = 0.0
		scale_ref = @{ x = [double]$baseW; y = [double]$baseH }; align = 5
		bounds_type = $(if ($cropBounds) { 2 } else { 0 }); bounds_align = 0; bounds_crop = $false
		crop_left = 0; crop_top = 0; crop_right = 0; crop_bottom = 0; id = $id; group_item_backup = $false
		pos = @{ x = 0.0; y = 0.0 }; scale = @{ x = 1.0; y = 1.0 }
		bounds = $(if ($cropBounds) { @{ x = [double]$baseW; y = [double]$baseH } } else { @{ x = 0.0; y = 0.0 } })
		scale_filter = "disable"; blend_method = "default"; blend_type = "normal"
		show_transition = @{ duration = 0 }; hide_transition = @{ duration = 0 }; private_settings = @{}
	}
	return $item
}

$filters = $null
if ($NoFfmpeg) {
	$filters = @([ordered]@{
		prev_ver = $prevVer; name = "Crop to SafeFrame"; uuid = (New-Uuid); id = "crop_filter"; versioned_id = "crop_filter"
		settings = [ordered]@{ left = $CropLeft; top = $CropTop; right = $CropRight; bottom = $CropBottom; relative = $true }
		mixers = 0; sync = 0; flags = 0; volume = 1.0; balance = 0.5; enabled = $true; muted = $false
		hotkeys = @{}; deinterlace_mode = 0; deinterlace_field_order = 0; monitoring_type = 0; private_settings = @{}
	})
}
$display = New-Source "Studio Display" "monitor_capture" ([ordered]@{ method = 2; monitor_id = $monitorId; capture_cursor = $false }) $false $filters 255
$appAudio = New-Source "Studio Audio" "wasapi_process_output_capture" ([ordered]@{ window = "Roblox Studio::RobloxStudioBeta.exe"; priority = 2 }) $false $null 255
$scene = New-Source "Trailer" "scene" ([ordered]@{
	id_counter = 2; custom_size = $false
	items = @((New-SceneItem $display.name $display.uuid 1 ([bool]$NoFfmpeg)), (New-SceneItem $appAudio.name $appAudio.uuid 2 $false))
}) $false $null 0
$scene.canvas_uuid = $canvas
$scene.hotkeys = @{ "OBSBasic.SelectScene" = @() }

$desktop = New-Source "Desktop Audio" "wasapi_output_capture" ([ordered]@{ device_id = "default" }) $true $null 255
$mic = New-Source "Mic/Aux" "wasapi_input_capture" ([ordered]@{ device_id = "default" }) $true $null 255

$collection = [ordered]@{
	name = "Trailer"
	DesktopAudioDevice1 = $desktop
	AuxAudioDevice1 = $mic
	sources = @($scene, $display, $appAudio)
	groups = @()
	scene_order = @(@{ name = "Trailer" })
	current_scene = "Trailer"
	current_program_scene = "Trailer"
	current_transition = "Fade"
	transition_duration = 300
	transitions = @()
	quick_transitions = @()
	saved_projectors = @()
	preview_locked = $true
	scaling_enabled = $false
	scaling_level = 0
	scaling_off_x = 0.0
	scaling_off_y = 0.0
	modules = [ordered]@{
		"scripts-tool" = @()
		"output-timer" = [ordered]@{
			streamTimerHours = 0; streamTimerMinutes = 0; streamTimerSeconds = 30
			recordTimerHours = 0; recordTimerMinutes = $TimerMinutes; recordTimerSeconds = 0
			autoStartStreamTimer = $false; autoStartRecordTimer = $true; pauseRecordTimer = $true
		}
	}
	resolution = @{ x = $baseW; y = $baseH }
	version = 2
}

$basicIni = @"
[General]
Name=Trailer

[Output]
Mode=Advanced
FilenameFormatting=Trailer_take_%CCYY-%MM-%DD_%hh-%mm-%ss

[AdvOut]
RecType=Standard
RecFilePath=$OutDir
RecFormat2=hybrid_mp4
RecEncoder=obs_nvenc_h264_tex
RecTracks=1

[Video]
BaseCX=$baseW
BaseCY=$baseH
OutputCX=$outW
OutputCY=$outH
FPSType=0
FPSCommon=$Fps
ScaleType=lanczos
ColorFormat=NV12
ColorSpace=709
ColorRange=Partial

[Audio]
SampleRate=48000
ChannelSetup=Stereo
"@
$encoderJson = '{"rate_control":"CQP","cqp":16,"preset2":"p6","tune":"hq","multipass":"qres","profile":"high","bf":2,"keyint_sec":2}'
$sceneJson = $collection | ConvertTo-Json -Depth 30

Write-Output ("monitor: {0} {1}x{2} id='{3}'" -f $primary.DeviceName, $monW, $monH, $monitorId)
Write-Output ("canvas {0}x{1} -> output {2}x{3} @ {4} fps; crop L{5} T{6} R{7} B{8} ({9})" -f $baseW, $baseH, $outW, $outH, $Fps,
	$CropLeft, $CropTop, $CropRight, $CropBottom, $(if ($NoFfmpeg) { "no-ffmpeg path, crop in OBS" } else { "full screen, crop later with ffmpeg" }))
if ($DryRun) {
	Write-Output "DRY RUN - would write:"; $targets | ForEach-Object { Write-Output "  $_" }
	Write-Output "--- basic.ini ---"; Write-Output $basicIni
	Write-Output "--- Trailer.json ---"; Write-Output $sceneJson
	exit 0
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
foreach ($f in $existing) { Copy-Item -LiteralPath $f -Destination "$f.bak-$stamp"; Write-Output "backup: $f.bak-$stamp" }
New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
[IO.File]::WriteAllText((Join-Path $profileDir "basic.ini"), $basicIni.Replace("`r`n", "`n"), $utf8)
[IO.File]::WriteAllText((Join-Path $profileDir "recordEncoder.json"), $encoderJson, $utf8)
[IO.File]::WriteAllText($sceneFile, $sceneJson, $utf8)
Write-Output "wrote $(Join-Path $profileDir 'basic.ini')"
Write-Output "wrote $(Join-Path $profileDir 'recordEncoder.json')"
Write-Output "wrote $sceneFile"
Write-Output "output folder: $OutDir"
Write-Output "Unverified for OBS 32 (check in rehearsal round 2): output-timer auto stop, the monitor_id match, the app-audio window string."
