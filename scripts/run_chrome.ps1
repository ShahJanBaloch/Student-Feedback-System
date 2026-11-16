$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$flutter = Get-Command flutter.bat -ErrorAction SilentlyContinue
if (-not $flutter) {
  $flutter = Get-Command flutter -ErrorAction SilentlyContinue
}
if (-not $flutter) {
  throw 'Flutter was not found on PATH. Add the Flutter SDK bin directory to PATH.'
}

Set-Location $root
& $flutter.Source run -d chrome --dart-define-from-file=.env.example
