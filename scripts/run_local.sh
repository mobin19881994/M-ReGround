#!/usr/bin/env bash
set -euo pipefail

echo "Running app in local-only mode (no Firebase)..."
flutter run --dart-define=MREGROUND_USE_LOCAL_ONLY=true
