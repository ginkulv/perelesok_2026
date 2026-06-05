# Run GUT unit tests headless (uses godot.exe in project root and .gutconfig.json).
$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

$Godot = Join-Path $ProjectRoot "godot.exe"
if (-not (Test-Path $Godot)) {
    throw "godot.exe not found at $Godot"
}

& $Godot --headless --path . -s addons/gut/gut_cmdln.gd -gexit
exit $LASTEXITCODE
