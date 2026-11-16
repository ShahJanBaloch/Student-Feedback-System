#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || "$1" != "run" && "$1" != "build" ]]; then
  echo "Usage: $0 {run|build} [Flutter arguments...]" >&2
  exit 2
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not installed or is not on PATH." >&2
  echo "Install Flutter in this Codespace, then run this command again." >&2
  exit 127
fi

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_path="$repository_root/.env.example"

if [[ ! -f "$env_path" ]]; then
  echo "Missing $env_path." >&2
  exit 1
fi

supabase_url="$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["SUPABASE_URL"])' "$env_path")"
supabase_anon_key="$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["SUPABASE_ANON_KEY"])' "$env_path")"

if [[ -z "$supabase_url" || -z "$supabase_anon_key" ]]; then
  echo "SUPABASE_URL and SUPABASE_ANON_KEY must be set in $env_path." >&2
  exit 1
fi

flutter_command="$1"
shift
exec flutter "$flutter_command" "$@" \
  "--dart-define=SUPABASE_URL=$supabase_url" \
  "--dart-define=SUPABASE_ANON_KEY=$supabase_anon_key"
