#!/usr/bin/env bash
set -euo pipefail

echo "Running flutter analyze..."
flutter analyze

echo "Basic smoke checks complete. If you want to run widget tests, run: flutter test"
