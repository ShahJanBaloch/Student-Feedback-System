$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$flutter = "S:\flutter\bin\flutter.bat"
Set-Location $root
& $flutter run -d chrome --dart-define-from-file=.env
