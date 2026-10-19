#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../frontend"
export CI=true FLUTTER_SUPPRESS_ANALYTICS=true
flutter pub get --enforce-lockfile
flutter run -d chrome --web-port 5173 --dart-define=API_BASE_URL="${API_BASE_URL:-http://localhost:8000}"
