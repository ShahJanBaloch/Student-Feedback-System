param(
  [Parameter(Mandatory = $true, Position = 0)]
  [ValidateSet('run', 'build')]
  [string]$FlutterCommand,

  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterArguments
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$envPath = Join-Path $repositoryRoot '.env'

if (-not (Test-Path -LiteralPath $envPath -PathType Leaf)) {
  throw 'Missing .env. Copy .env.example and set the Supabase URL and anon key.'
}

$values = @{}
foreach ($line in Get-Content -LiteralPath $envPath) {
  $trimmed = $line.Trim()
  if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith('#')) {
    continue
  }

  $separator = $trimmed.IndexOf('=')
  if ($separator -lt 1) {
    throw 'Invalid .env line. Expected KEY=VALUE.'
  }

  $name = $trimmed.Substring(0, $separator).Trim()
  $value = $trimmed.Substring($separator + 1).Trim()
  if ($value.Length -ge 2 -and
      (($value[0] -eq '"' -and $value[$value.Length - 1] -eq '"') -or
       ($value[0] -eq "'" -and $value[$value.Length - 1] -eq "'"))) {
    $value = $value.Substring(1, $value.Length - 2)
  }
  $values[$name] = $value
}

foreach ($requiredName in @('SUPABASE_URL', 'SUPABASE_ANON_KEY')) {
  if ([string]::IsNullOrWhiteSpace($values[$requiredName])) {
    throw "Missing $requiredName in .env."
  }
}

$dartDefines = @(
  "--dart-define=SUPABASE_URL=$($values['SUPABASE_URL'])",
  "--dart-define=SUPABASE_ANON_KEY=$($values['SUPABASE_ANON_KEY'])"
)

& flutter $FlutterCommand @FlutterArguments @dartDefines
exit $LASTEXITCODE
