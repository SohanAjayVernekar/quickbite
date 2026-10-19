#!/usr/bin/env bash
# Copy the UI/artwork update without touching any port or environment settings.
set -euo pipefail
source_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ $# -ne 1 ]]; then
  printf 'Usage: bash "%s" "/path/to/existing/quickbite-food-delivery"\n' "$0"
  exit 1
fi
python3 - "$source_dir" "$1" <<'PY'
import json
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path
source = Path(sys.argv[1]).resolve()
target = Path(sys.argv[2]).expanduser().resolve()
if not (target / 'frontend/pubspec.yaml').is_file() or not (target / 'backend/app/database/catalog.py').is_file():
    raise SystemExit('Choose the existing QuickBite project root containing frontend/ and backend/.')
if source == target:
    print('The updated files are already in this folder. Run: bash scripts/start.sh')
    raise SystemExit(0)
files = json.loads((source / 'docs/UI_UPDATE_FILES.json').read_text())
protected = {'.env', '.env.example', 'compose.yaml', 'compose.test.yaml', 'frontend/Dockerfile', 'backend/Dockerfile', 'frontend/nginx.conf', 'frontend/lib/core/config/environment.dart'}
for relative in files:
    origin = (source / relative).resolve()
    destination = (target / relative).resolve()
    if (relative in protected or relative.startswith('scripts/')
            or not origin.is_relative_to(source)
            or not destination.is_relative_to(target)
            or not origin.is_file()):
        raise SystemExit(f'Refusing invalid or protected update entry: {relative}')
backup = target / '.ui-backups' / datetime.now(timezone.utc).strftime('%Y%m%d-%H%M%S-%f')
for relative in files:
    origin = source / relative
    destination = target / relative
    if destination.is_file():
        previous = backup / relative
        previous.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(destination, previous)
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(origin, destination)
print(f'Updated {len(files)} UI, artwork and documentation files.')
print(f'Previous copies: {backup}')
print('Your .env, ports, Compose files and database volumes were not modified.')
print(f'Next: cd "{target}"')
print('Then: bash scripts/start.sh')
PY
