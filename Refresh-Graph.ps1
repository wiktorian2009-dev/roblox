$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    graphify extract game --code-only --out . --max-workers 2
    if ($LASTEXITCODE -ne 0) { throw 'Graphify extraction failed.' }
    graphify cluster-only . --no-label
    if ($LASTEXITCODE -ne 0) { throw 'Graphify report generation failed.' }
} finally {
    Pop-Location
}
