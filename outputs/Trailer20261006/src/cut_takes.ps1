# cut_takes.ps1 (2026-10-06, Claude): cut points for the trailer take (DESIGN rev 2, section 13).
# One clock: A = [T_A, T_A + 29.5]; B = [T_A, T_A + 25.5] + [T_B, T_B + 4.0], T_B = T_A + 33.5. T_A is estimated from the client's
# "[Trailer] TRAILER_ROLL_A unixms=..." line minus OBS's "Recording Start" log time (both use this PC's clock).
#   ffmpeg present  -> prints the section 13.1 commands; with -Run it finds the crop box from the magenta slate frame (needs
#                      -SlateUnixMs or -Crop), refines T_A / T_B with blackdetect ON THE CROPPED PICTURE (review fix: the full
#                      desktop never reads as black) and runs them (outputs go to outputs\Trailer only). No crop box -> exit 3.
#   ffmpeg missing  -> refines T_A / T_B on the black runs with Windows.Media.Editing thumbnails (DESIGN 13.2, review fix; the OBS
#                      file is already cropped to the SafeFrame) and prints the trim points for Windows.Media.Editing / Clipchamp.
#                      -NoRefine skips that. Installing ffmpeg needs wiktor's yes (winget install Gyan.FFmpeg); this script never
#                      installs anything.
# Read-only on the take, the OBS log and the Studio log (the ffmpeg path writes slate.png and the outputs into -OutDir).
[CmdletBinding()]
param(
	[string]$Take,
	[Int64]$RollAUnixMs = 0,
	[Int64]$SlateUnixMs = 0,
	[string]$ObsLog,
	[ValidateSet(60, 30)][int]$Fps = 60,
	[string]$Crop,
	[double]$PassA = 29.5,
	[double]$CutB = 25.5,
	[double]$PassB = 4.0,
	[double]$RollBOffset = 33.5,
	[string]$OutDir = "C:\Users\wikto\Desktop\Roblox Gra\outputs\Trailer",
	[Int64]$SlateEndUnixMs = 0,
	[Int64]$DoneUnixMs = 0,
	[switch]$NoRefine,
	[switch]$Run
)
$ErrorActionPreference = "Stop"
$inv = [Globalization.CultureInfo]::InvariantCulture
function F([double]$x) { $x.ToString("0.000", $inv) }

# ---- the take ----
if (-not $Take) {
	$t = Get-ChildItem -LiteralPath $OutDir -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "Trailer_take_*" -and $_.Extension -in ".mp4", ".mkv", ".mov" } |
		Sort-Object LastWriteTime -Descending | Select-Object -First 1
	if (-not $t) { Write-Output "No Trailer_take_* file in $OutDir"; exit 2 }
	$Take = $t.FullName
}
$takeItem = Get-Item -LiteralPath $Take
Write-Output "take: $Take ($([math]::Round($takeItem.Length / 1MB, 1)) MB)"

# ---- OBS "Recording Start" (local time) ----
if (-not $ObsLog) {
	$ObsLog = (Get-ChildItem -LiteralPath (Join-Path $env:APPDATA "obs-studio\logs") -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
}
$logName = [IO.Path]::GetFileNameWithoutExtension($ObsLog)
$logStart = [datetime]::ParseExact($logName, "yyyy-MM-dd HH-mm-ss", $inv)
$recStart = $null
foreach ($line in [IO.File]::ReadAllLines($ObsLog)) {
	$m = [regex]::Match($line, "^(\d\d):(\d\d):(\d\d)\.(\d\d\d): =+ Recording Start")
	if ($m.Success) {
		$t = $logStart.Date.AddHours([int]$m.Groups[1].Value).AddMinutes([int]$m.Groups[2].Value).AddSeconds([int]$m.Groups[3].Value).AddMilliseconds([int]$m.Groups[4].Value)
		if ($t -lt $logStart.AddMinutes(-1)) { $t = $t.AddDays(1) }
		if ($t -le $takeItem.CreationTime.AddSeconds(10)) { $recStart = $t }
	}
}
if (-not $recStart) { Write-Output "No '==== Recording Start' line in $ObsLog before the take was created"; exit 2 }
$recStartMs = ([DateTimeOffset]$recStart).ToUnixTimeMilliseconds()
Write-Output ("OBS recording start: {0:yyyy-MM-dd HH:mm:ss.fff} (unixms {1}) from {2}" -f $recStart, $recStartMs, (Split-Path $ObsLog -Leaf))

# ---- ROLL_A / SLATE from the Studio log when not given ----
if ($RollAUnixMs -le 0 -or $SlateUnixMs -le 0) {
	$sl = Get-ChildItem -LiteralPath (Join-Path $env:LOCALAPPDATA "Roblox\logs") -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*Studio*" } |
		Sort-Object LastWriteTime -Descending | Select-Object -First 3
	foreach ($f in $sl) {
		$fs = [IO.File]::Open($f.FullName, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
		try { $text = (New-Object IO.StreamReader($fs)).ReadToEnd() } finally { $fs.Dispose() }
		if ($RollAUnixMs -le 0) {
			$ms = [regex]::Matches($text, "TRAILER_ROLL_A unixms=(\d+)")
			if ($ms.Count -gt 0) { $RollAUnixMs = [Int64]$ms[$ms.Count - 1].Groups[1].Value; Write-Output "ROLL_A unixms $RollAUnixMs from $($f.Name)" }
		}
		if ($SlateUnixMs -le 0) {
			$ms = [regex]::Matches($text, "SLATE_START unixms=(\d+)")
			if ($ms.Count -gt 0) { $SlateUnixMs = [Int64]$ms[$ms.Count - 1].Groups[1].Value }
		}
		if ($SlateEndUnixMs -le 0) {
			$ms = [regex]::Matches($text, "SLATE_END unixms=(\d+)")
			if ($ms.Count -gt 0) { $SlateEndUnixMs = [Int64]$ms[$ms.Count - 1].Groups[1].Value }
		}
		if ($DoneUnixMs -le 0) {
			$ms = [regex]::Matches($text, "TRAILER_DONE unixms=(\d+)")
			if ($ms.Count -gt 0) { $DoneUnixMs = [Int64]$ms[$ms.Count - 1].Groups[1].Value }
		}
		if ($RollAUnixMs -gt 0) { break }
	}
}
if ($RollAUnixMs -le 0) { Write-Output "ROLL_A unixms unknown: pass -RollAUnixMs from the '[Trailer] TRAILER_ROLL_A unixms=' line in Studio Output"; exit 2 }
$TA = ($RollAUnixMs - $recStartMs) / 1000.0
$TB = $TA + $RollBOffset
Write-Output ("estimate: T_A = {0} s, T_B = {1} s (refine on the black runs; OBS start-log latency is typically under 0.1 s)" -f (F $TA), (F $TB))

$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue

# ---- no-ffmpeg refinement (DESIGN 13.2): Windows.Media.Editing thumbnails around each estimate, 1/fps steps, mean luma < 16 = black;
# the cut point is the first non-black frame after the black run. The black before ROLL_A (warm-up + gate) and before ROLL_B (the 4 s
# gap) is far longer than the +-1 s window, so the frame grid is bisected (~8 thumbnails at ~0.5 s each instead of 121). Read-only.
function Get-FrameLuma($comp, [double]$t) {
	$img = Await-WinRt ($comp.GetThumbnailAsync([TimeSpan]::FromSeconds($t), 64, 36, [Windows.Media.Editing.VideoFramePrecision]::NearestFrame)) ([Windows.Graphics.Imaging.ImageStream])
	try {
		$dec = Await-WinRt ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($img)) ([Windows.Graphics.Imaging.BitmapDecoder])
		$px = (Await-WinRt ($dec.GetPixelDataAsync()) ([Windows.Graphics.Imaging.PixelDataProvider])).DetachPixelData()
	} finally { $img.Dispose() }
	$n = [int]$dec.PixelWidth * [int]$dec.PixelHeight
	return [TrailerLuma]::Mean($px, [math]::Max(1, [int]($px.Length / [math]::Max(1, $n))))
}
function Find-BlackEnd($comp, [double]$est, [int]$fps) {
	$kLo = [int][math]::Ceiling([math]::Max(0.0, $est - 1.0) * $fps)
	$kHi = [int][math]::Floor(($est + 1.0) * $fps)
	if ((Get-FrameLuma $comp ($kLo / $fps)) -ge 16) { return $null } # not black 1 s before the estimate
	if ((Get-FrameLuma $comp ($kHi / $fps)) -lt 16) { return $null } # still black 1 s after it
	while ($kHi - $kLo -gt 1) {
		$mid = [int][math]::Floor(($kLo + $kHi) / 2)
		if ((Get-FrameLuma $comp ($mid / $fps)) -lt 16) { $kLo = $mid } else { $kHi = $mid }
	}
	return $kHi / $fps
}
function Await-WinRt($op, [type]$resultType) {
	$m = $script:asTaskGeneric.MakeGenericMethod($resultType)
	$task = $m.Invoke($null, @($op))
	[void]$task.Wait(-1)
	return $task.Result
}
if (-not $ffmpeg -and -not $NoRefine) {
	try {
		if (-not ("TrailerLuma" -as [type])) {
			Add-Type -TypeDefinition @"
public static class TrailerLuma {
	// mean of the colour channels (alpha skipped); black frames sit far below 16 in every channel order
	public static double Mean(byte[] px, int bpp) {
		int c = bpp < 3 ? bpp : 3; double sum = 0; long n = 0;
		for (int i = 0; i + c <= px.Length; i += bpp) { for (int j = 0; j < c; j++) sum += px[i + j]; n += c; }
		return n > 0 ? sum / n : 0;
	}
}
"@
		}
		Add-Type -AssemblyName System.Runtime.WindowsRuntime
		$script:asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
			$_.Name -eq "AsTask" -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
		$null = [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
		$null = [Windows.Media.Editing.MediaComposition, Windows.Media.Editing, ContentType = WindowsRuntime]
		$null = [Windows.Media.Editing.MediaClip, Windows.Media.Editing, ContentType = WindowsRuntime]
		$null = [Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics.Imaging, ContentType = WindowsRuntime]
		$file = Await-WinRt ([Windows.Storage.StorageFile]::GetFileFromPathAsync($takeItem.FullName)) ([Windows.Storage.StorageFile])
		$clip = Await-WinRt ([Windows.Media.Editing.MediaClip]::CreateFromFileAsync($file)) ([Windows.Media.Editing.MediaClip])
		$comp = New-Object Windows.Media.Editing.MediaComposition
		# PowerShell 5.1 does not expose IList.Add on the projected WinRT vector; call it through the interface
		[void][System.Collections.Generic.ICollection[Windows.Media.Editing.MediaClip]].GetMethod("Add").Invoke($comp.Clips, @($clip))
		foreach ($k in @("A", "B")) {
			$est = if ($k -eq "A") { $TA } else { $TB }
			$hit = Find-BlackEnd $comp $est $Fps
			if ($null -ne $hit) {
				if ($k -eq "A") { $TA = $hit } else { $TB = $hit }
				Write-Output ("refined T_{0} = {1} s (first non-black thumbnail after the black run; estimate {2})" -f $k, (F $hit), (F $est))
			} else {
				Write-Output ("WARNING: T_{0}: no black -> picture edge within 1 s of {1} - keeping the estimate; check it by eye" -f $k, (F $est))
			}
		}
	} catch {
		Write-Output ("WARNING: Windows.Media.Editing refinement failed ({0}) - keeping the estimates; check them by eye" -f $_.Exception.Message)
	}
}

if (-not $ffmpeg) {
	Write-Output ""
	Write-Output "ffmpeg is not installed (installing it needs wiktor's permission: winget install Gyan.FFmpeg). Trim points:"
	Write-Output ("  A        : start {0} s, end {1} s (length {2} s)" -f (F $TA), (F ($TA + $PassA)), $PassA)
	Write-Output ("  B part 1 : start {0} s, end {1} s (length {2} s)" -f (F $TA), (F ($TA + $CutB)), $CutB)
	Write-Output ("  B part 2 : start {0} s, end {1} s (length {2} s), appended after part 1" -f (F $TB), (F ($TB + $PassB)), $PassB)
	Write-Output "  silent copies: the same cuts with the clip volume at 0."
	Write-Output "  Windows.Media.Editing (section 13.2): MediaClip TrimTimeFromStart = start, TrimTimeFromEnd = clip length - end; B = two clips appended."
	Write-Output "  Clipchamp: trim the take at the A numbers; for B split at the part-1 end and append part 2."
	Write-Output "  Check frame-exactly: the first non-black frame after the 0.5 s black is T_A; the frame before the black at T_A + 29.5 is the last one."
	exit 0
}

# ---- ffmpeg path ----
$take = $Take
$outA = Join-Path $OutDir "Trailer_A.mp4"
$outB = Join-Path $OutDir "Trailer_B.mp4"
if ($Run) {
	# crop box from the magenta slate (first: blackdetect below needs it)
	if (-not $Crop -and $SlateUnixMs -gt 0) {
		# review fix: grab mid-slate (SLATE_START..SLATE_END; CropOK can end it early), else the 0.5 s end magenta, else start + 2 s
		if ($SlateEndUnixMs -gt $SlateUnixMs) { $ts = (($SlateUnixMs + $SlateEndUnixMs) / 2.0 - $recStartMs) / 1000.0 }
		elseif ($DoneUnixMs -gt 0) { $ts = ($DoneUnixMs - 250 - $recStartMs) / 1000.0 }
		else { $ts = ($SlateUnixMs - $recStartMs) / 1000.0 + 2.0 }
		$png = Join-Path $OutDir "slate.png"
		& $ffmpeg.Source -hide_banner -loglevel error -y -ss (F $ts) -i $take -frames:v 1 $png
		Add-Type -AssemblyName System.Drawing
		if (-not ("TrailerSlate" -as [type])) {
			Add-Type -TypeDefinition @"
public static class TrailerSlate {
	public static int[] Box(byte[] bgra, int w, int h, int stride) {
		int x0 = w, y0 = h, x1 = -1, y1 = -1;
		for (int y = 0; y < h; y++) {
			int row = y * stride;
			for (int x = 0; x < w; x++) {
				int i = row + x * 4;
				byte b = bgra[i], g = bgra[i + 1], r = bgra[i + 2];
				if (r > 200 && g < 60 && b > 200) { if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; }
			}
		}
		return new int[] { x0, y0, x1, y1 };
	}
}
"@
		}
		$bmp = [System.Drawing.Bitmap]::FromFile($png)
		try {
			$rect = New-Object System.Drawing.Rectangle 0, 0, $bmp.Width, $bmp.Height
			$data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
			$bytes = New-Object byte[] ($data.Stride * $bmp.Height)
			[Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
			$box = [TrailerSlate]::Box($bytes, $bmp.Width, $bmp.Height, $data.Stride)
			$bmp.UnlockBits($data)
		} finally { $bmp.Dispose() }
		if ($box[2] -lt 0) { Write-Output "no magenta found in $png - pass -Crop W:H:X:Y"; exit 3 }
		# review fix: shift the origin to even first, then size from the shifted origin, so no letterbox edge pixel gets in
		$x = $box[0] + ($box[0] % 2); $y = $box[1] + ($box[1] % 2)
		$w = $box[2] - $x + 1; $h = $box[3] - $y + 1
		$w -= $w % 2; $h -= $h % 2
		if ([math]::Abs($w * 9 - $h * 16) -gt 16) { Write-Output ("WARNING: slate box {0}x{1} is not 16:9 within 1 px" -f $w, $h) }
		$Crop = "{0}:{1}:{2}:{3}" -f $w, $h, $x, $y
		Write-Output "crop from the slate: $Crop"
	}
	# refine T_A / T_B on the black runs of the CROPPED picture (review fix: Studio chrome, the taskbar and the menu button keep the
	# full desktop frame far above blackdetect's 98% black share)
	if (-not $Crop) { Write-Output "NO CROP BOX: blackdetect cannot work on the full desktop - pass -Crop W:H:X:Y or -SlateUnixMs"; exit 3 }
	$bd = & $ffmpeg.Source -hide_banner -i $take -vf "crop=$Crop,blackdetect=d=0.3:pic_th=0.98:pix_th=0.05" -an -f null - 2>&1 | Out-String
	$ends = @([regex]::Matches($bd, "black_end:([\d\.]+)") | ForEach-Object { [double]::Parse($_.Groups[1].Value, $inv) })
	foreach ($pair in @(@("A", $TA), @("B", $TB))) {
		$near = $ends | Sort-Object { [math]::Abs($_ - $pair[1]) } | Select-Object -First 1
		if ($near -ne $null -and [math]::Abs($near - $pair[1]) -le 1.0) {
			if ($pair[0] -eq "A") { $TA = $near } else { $TB = $near }
			Write-Output ("refined T_{0} = {1} s (black_end)" -f $pair[0], (F $near))
		} else { Write-Output ("WARNING: T_{0}: no black_end within 1 s of the estimate - keeping {1}; check it by eye" -f $pair[0], (F $pair[1])) }
	}
}
$cropF = if ($Crop) { "crop=$Crop,scale=1920:1080:flags=lanczos,format=yuv420p" } else { "scale=1920:1080:flags=lanczos,format=yuv420p" }
if (-not $Crop) { Write-Output "NOTE: no crop box (pass -Crop W:H:X:Y or -SlateUnixMs with -Run); commands below only scale." }
$enc = @("-r", "$Fps", "-c:v", "libx264", "-preset", "slow", "-crf", "18", "-maxrate", "15M", "-bufsize", "30M", "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-movflags", "+faststart")
$fc = "[0:v]trim=start=$(F $TA):duration=$CutB,setpts=PTS-STARTPTS[v1];[0:a]atrim=start=$(F $TA):duration=$CutB,asetpts=PTS-STARTPTS,afade=t=out:st=$(F ($CutB - 0.02)):d=0.02[a1];" +
	"[0:v]trim=start=$(F $TB):duration=$PassB,setpts=PTS-STARTPTS[v2];[0:a]atrim=start=$(F $TB):duration=$PassB,asetpts=PTS-STARTPTS,afade=t=in:d=0.02[a2];" +
	"[v1][a1][v2][a2]concat=n=2:v=1:a=1[v][a];[v]$cropF[vo]"
$jobs = @(
	@{ name = "A"; args = @("-hide_banner", "-y", "-ss", (F $TA), "-i", $take, "-t", "$PassA", "-vf", $cropF) + $enc + @($outA) },
	@{ name = "B"; args = @("-hide_banner", "-y", "-i", $take, "-filter_complex", $fc, "-map", "[vo]", "-map", "[a]") + $enc + @($outB) },
	@{ name = "A silent"; args = @("-hide_banner", "-y", "-i", $outA, "-c:v", "copy", "-an", "-movflags", "+faststart", (Join-Path $OutDir "Trailer_A_silent.mp4")) },
	@{ name = "B silent"; args = @("-hide_banner", "-y", "-i", $outB, "-c:v", "copy", "-an", "-movflags", "+faststart", (Join-Path $OutDir "Trailer_B_silent.mp4")) },
	@{ name = "A sheet"; args = @("-hide_banner", "-y", "-i", $outA, "-vf", "fps=1,scale=640:-2,tile=6x5", "-frames:v", "1", (Join-Path $OutDir "Trailer_A_sheet.png")) },
	@{ name = "A full grabs"; args = @("-hide_banner", "-y", "-i", $outA, "-vf", "fps=1", (Join-Path $OutDir "Trailer_A_full_%02d.png")) },
	@{ name = "A 360 grabs"; args = @("-hide_banner", "-y", "-i", $outA, "-vf", "fps=1,scale=-2:360", (Join-Path $OutDir "Trailer_A_360_%02d.png")) }
)
foreach ($j in $jobs) {
	$shown = ($j.args | ForEach-Object { if ($_ -match '[\s;\[\]]') { '"' + $_ + '"' } else { $_ } }) -join " "
	Write-Output "ffmpeg $shown"
	if ($Run) {
		& $ffmpeg.Source @($j.args)
		if ($LASTEXITCODE -ne 0) { Write-Output "FAILED: $($j.name) (exit $LASTEXITCODE)"; exit 4 }
	}
}
$ffprobe = Get-Command ffprobe -ErrorAction SilentlyContinue
if ($Run -and $ffprobe) {
	foreach ($o in @($outA, $outB)) {
		Write-Output "check $o"
		& $ffprobe.Source -v error -show_entries "format=duration,size:stream=width,height,r_frame_rate" -of json $o
	}
	Write-Output "acceptance: duration 29.4-29.6 s, 1920x1080, under 100 MB; review the sheet and grabs for UI, names, prices, padlocks, magenta, white-out."
}
