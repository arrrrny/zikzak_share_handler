#!/bin/bash

ALL_PACKAGES=(
  zikzak_share_handler
  zikzak_share_handler_android
  zikzak_share_handler_ios
  zikzak_share_handler_linux
  zikzak_share_handler_macos
  zikzak_share_handler_platform_interface
  zikzak_share_handler_web
  zikzak_share_handler_windows
)

echo "🔥 ZikZak Share Handler - Restoring Development Mode 🔥"
echo "Converting all dependencies to path dependencies..."

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Root directory: $ROOT_DIR"

update_for_dev_mode() {
  local pubspec_file="$1/pubspec.yaml"

  if [ ! -f "$pubspec_file" ]; then
    echo "⚠️  Pubspec file not found at $pubspec_file"
    return 1
  fi

  echo "Processing $pubspec_file"

  # Use a Python one-liner for reliable YAML-aware transformation:
  # 1. Remove lines that are commented-out path deps with "# Commented for publishing"
  # 2. Convert any hosted version deps (e.g. "zikzak_share_handler_foo: ^0.0.32")
  #    into path deps pointing to ../zikzak_share_handler_foo
  python3 -c "
import re, sys

with open('$pubspec_file', 'r') as f:
    content = f.read()

# Remove commented-out path lines with publishing marker
content = re.sub(r'^\s*#\s*zikzak_share_handler[^\n]*#[^\n]*Commented for publishing[^\n]*\n', '', content, flags=re.MULTILINE)
# Remove orphaned commented package name lines left behind
content = re.sub(r'^\s*#\s*zikzak_share_handler_\w+:\s*\n', '', content, flags=re.MULTILINE)

# Convert versioned deps to path deps
def to_path(match):
    pkg = match.group(1)
    return f'{pkg}:\n    path: ../{pkg}'

content = re.sub(r'^(  zikzak_share_handler(?:_\w+)?): \^[0-9]+\.[0-9]+\.[0-9]+$', to_path, content, flags=re.MULTILINE)

with open('$pubspec_file', 'w') as f:
    f.write(content)
"

  if [ $? -eq 0 ]; then
    echo "✅ Updated $pubspec_file to use path dependencies"
  else
    echo "⚠️  Failed to update $pubspec_file"
    return 1
  fi
}

# --- Phase 1: Update pubspecs ---
for package in "${ALL_PACKAGES[@]}"; do
  if [ -d "$ROOT_DIR/$package" ]; then
    update_for_dev_mode "$ROOT_DIR/$package"
  else
    echo "⚠️  Directory not found: $ROOT_DIR/$package"
  fi
done

# --- Phase 2: flutter pub get ---
echo ""
echo "Running 'flutter pub get' on all packages..."
# platform_interface first since others depend on it
for package in zikzak_share_handler_platform_interface "${ALL_PACKAGES[@]}"; do
  if [ -d "$ROOT_DIR/$package" ]; then
    echo "Getting dependencies for $package..."
    (cd "$ROOT_DIR/$package" && flutter pub get)
  fi
done

# --- Phase 3: Deep clean (optional) ---
echo ""
echo "🔥 INITIATING NUCLEAR CLEANING MODE 🔥"
echo "Do you want to perform a deep clean of Flutter/Dart caches? (y/n)"
read -r deep_clean_choice

if [[ "$deep_clean_choice" == "y" || "$deep_clean_choice" == "Y" ]]; then
  echo "☢️  NUCLEAR CLEANING: PURGING ALL PUB CACHES ☢️"

  find "$ROOT_DIR" -name ".dart_tool" -type d -exec rm -rf {} +
  find "$ROOT_DIR" -name "build" -type d -exec rm -rf {} +

  echo "Purging Dart pub cache..."
  dart pub cache clean --all

  for package in "${ALL_PACKAGES[@]}"; do
    if [ -d "$ROOT_DIR/$package" ]; then
      echo "Running flutter clean in $package..."
      (cd "$ROOT_DIR/$package" && flutter clean)
    fi
  done

  echo "🧨 NUCLEAR CLEANING COMPLETE! ALL CACHES OBLITERATED! 🧨"
fi

# --- Phase 4: Verify ---
echo ""
echo "🔬 VERIFYING DEVELOPMENT SETUP 🔬"
verify_issues=0

for package in "${ALL_PACKAGES[@]}"; do
  pubspec="$ROOT_DIR/$package/pubspec.yaml"
  if [ ! -f "$pubspec" ]; then
    continue
  fi

  versioned_deps=$(grep -c 'zikzak_share_handler.*: \^[0-9]' "$pubspec" 2>/dev/null || echo 0)
  actual_path_deps=$(grep -c 'path:.*\.\.\/zikzak_share_handler' "$pubspec" 2>/dev/null || echo 0)

  if [ "$versioned_deps" -gt 0 ]; then
    echo "⚠️  WARNING: $package still has $versioned_deps versioned dependencies!"
    verify_issues=$((verify_issues + 1))
  fi

  if [ "$actual_path_deps" -gt 0 ]; then
    echo "✅ $package: Found $actual_path_deps path dependencies"
  fi
done

if [ "$verify_issues" -eq 0 ]; then
  echo "✅ VERIFICATION COMPLETE: Development setup is PERFECT!"
else
  echo "⚠️  VERIFICATION FOUND $verify_issues ISSUES: You may need to manually fix some dependencies."
fi

echo ""
echo "🔥🔥🔥 DEVELOPMENT MODE SETUP COMPLETE! 🔥🔥🔥"
echo "All packages now use path dependencies for local development!"
