#!/usr/bin/env bash
# Sign build/TCCPreflight.app. Ad-hoc by default; Developer ID if CODESIGN_IDENTITY is set
# (e.g. CODESIGN_IDENTITY="Developer ID Application: You (TEAMID)"). No secrets live in this repo.
set -euo pipefail
cd "$(dirname "$0")/.."
APP=build/TCCPreflight.app
ID="${CODESIGN_IDENTITY:--}"
[[ "$(uname -s)" == Darwin ]] || { echo "codesign: macOS only (skipped)"; exit 0; }
opts=(--force --options runtime --entitlements helper/Resources/entitlements.plist --sign "$ID")
[[ "$ID" == "-" ]] && opts=(--force --entitlements helper/Resources/entitlements.plist --sign -)
codesign "${opts[@]}" "$APP"
codesign --verify --strict --verbose=2 "$APP"
echo "signed with: $ID  (re-signing with a different identity or moving the app invalidates existing grants)"
