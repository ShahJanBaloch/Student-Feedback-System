param(
  [Parameter(Mandatory = $true, Position = 0)]
  [ValidateSet('run', 'build')]
  [string]$FlutterCommand,

  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterArguments
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$envPath = Join-Path $repositoryRoot '.env.example'

if (-not (Test-Path -LiteralPath $envPath -PathType Leaf)) {
  throw 'Missing .env.example. Set the Supabase URL and anon key in .env.example.'
}

$values = Get-Content -LiteralPath $envPath -Raw | ConvertFrom-Json

foreach ($requiredName in @('SUPABASE_URL', 'SUPABASE_ANON_KEY')) {
  if ([string]::IsNullOrWhiteSpace($values.$requiredName)) {
    throw "Missing $requiredName in .env.example."
  }
}

$dartDefines = @(
  "--dart-define=SUPABASE_URL=$($values.SUPABASE_URL)",
  "--dart-define=SUPABASE_ANON_KEY=$($values.SUPABASE_ANON_KEY)"
)

& flutter $FlutterCommand @FlutterArguments @dartDefines
exit $LASTEXITCODE
