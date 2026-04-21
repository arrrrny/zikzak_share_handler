#!/bin/bash

echo "🔥 ZikZak Share Handler - Restoring Development Mode 🔥"
echo "Converting all dependencies to path dependencies..."

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Root directory: $ROOT_DIR"

update_for_dev_mode() {
  local package_dir=$1
  local pubspec_file="$package_dir/pubspec.yaml"

  if [ ! -f "$pubspec_file" ]; then
    echo "⚠️ Pubspec file not found at $pubspec_file"
    return
  fi

  echo "Processing $pubspec_file"

  sed -i.tmp -E 's|^    #([ ]+path: ../zikzak_share_handler.*)[ ]#[ ]Commented for publishing|\1|g' "$pubspec_file"

  awk '
  BEGIN {
    in_dev_dependencies = 0;
    packages["zikzak_share_handler_platform_interface"] = 1;
    packages["zikzak_share_handler_android"] = 1;
    packages["zikzak_share_handler_ios"] = 1;
    packages["zikzak_share_handler_macos"] = 1;
    packages["zikzak_share_handler"] = 1;
  }

  /^dev_dependencies:/ {
    in_dev_dependencies = 1;
    print;
    next;
  }

  in_dev_dependencies && /^  zikzak_share_handler/ {
    pkg_name = $1;
    sub(/:$/, "", pkg_name);

    if (packages[pkg_name]) {
      if ($0 !~ /path:/) {
        print "  " pkg_name ":";
        print "    path: ../" pkg_name;
        getline;
        next;
      }
    }
  }

  in_dev_dependencies && /^[a-zA-Z]/ && !/^  / {
    in_dev_dependencies = 0;
  }

  { print }
  ' "$pubspec_file" > "${pubspec_file}.new"

  if [ -s "${pubspec_file}.new" ]; then
    mv "${pubspec_file}.new" "$pubspec_file"
  else
    echo "⚠️ Warning: awk processing failed for $pubspec_file"
  fi

  sed -i.tmp -E 's|zikzak_share_handler_platform_interface: \^[0-9]+\.[0-9]+\.[0-9]+|zikzak_share_handler_platform_interface:\n    path: ../zikzak_share_handler_platform_interface|g' "$pubspec_file"

  sed -i.tmp -E 's|zikzak_share_handler_android: \^[0-9]+\.[0-9]+\.[0-9]+|zikzak_share_handler_android:\n    path: ../zikzak_share_handler_android|g' "$pubspec_file"

  sed -i.tmp -E 's|zikzak_share_handler_ios: \^[0-9]+\.[0-9]+\.[0-9]+|zikzak_share_handler_ios:\n    path: ../zikzak_share_handler_ios|g' "$pubspec_file"

  sed -i.tmp -E 's|zikzak_share_handler_macos: \^[0-9]+\.[0-9]+\.[0-9]+|zikzak_share_handler_macos:\n    path: ../zikzak_share_handler_macos|g' "$pubspec_file"

  rm -f "${pubspec_file}.tmp"

  echo "✅ Updated $pubspec_file to use path dependencies"
}

for package in zikzak_share_handler zikzak_share_handler_android zikzak_share_handler_ios zikzak_share_handler_macos zikzak_share_handler_platform_interface; do
  if [ -d "$ROOT_DIR/$package" ]; then
    update_for_dev_mode "$ROOT_DIR/$package"
  else
    echo "⚠️ Directory not found: $ROOT_DIR/$package"
  fi
done

echo "Running 'flutter pub get' on all packages..."
for package in zikzak_share_handler zikzak_share_handler_platform_interface zikzak_share_handler_android zikzak_share_handler_ios zikzak_share_handler_macos; do
  if [ -d "$ROOT_DIR/$package" ]; then
    echo "Getting dependencies for $package..."
    (cd "$ROOT_DIR/$package" && flutter pub get)
  fi
done

echo ""
echo "🔥 INITIATING NUCLEAR CLEANING MODE 🔥"

echo "Do you want to perform a deep clean of Flutter/Dart caches? (y/n)"
read -r deep_clean_choice

if [[ "$deep_clean_choice" == "y" || "$deep_clean_choice" == "Y" ]]; then
  echo "☢️ NUCLEAR CLEANING: PURGING ALL PUB CACHES ☢️"

  find "$ROOT_DIR" -name ".dart_tool" -type d -exec rm -rf {} +

  find "$ROOT_DIR" -name "build" -type d -exec rm -rf {} +

  echo "Purging Dart pub cache..."
  dart pub cache clean --all

  for package in zikzak_share_handler zikzak_share_handler_platform_interface zikzak_share_handler_android zikzak_share_handler_ios zikzak_share_handler_macos; do
    if [ -d "$ROOT_DIR/$package" ]; then
      echo "Running flutter clean in $package..."
      (cd "$ROOT_DIR/$package" && flutter clean)
    fi
  done

  echo "🧨 NUCLEAR CLEANING COMPLETE! ALL CACHES OBLITERATED! 🧨"
fi

echo ""
echo "🔬 VERIFYING DEVELOPMENT SETUP 🔬"
verify_issues=0

for package in zikzak_share_handler zikzak_share_handler_android zikzak_share_handler_ios zikzak_share_handler_macos; do
  if [ -f "$ROOT_DIR/$package/pubspec.yaml" ]; then
    commented_paths=$(grep "#.*path:.*\.\.\/zikzak_share_handler.*# Commented for publishing" "$ROOT_DIR/$package/pubspec.yaml" 2>/dev/null | wc -l)

    versioned_deps=$(grep "zikzak_share_handler.*: \^[0-9]" "$ROOT_DIR/$package/pubspec.yaml" 2>/dev/null | wc -l)

    actual_path_deps=$(grep "path:.*\.\.\/zikzak_share_handler" "$ROOT_DIR/$package/pubspec.yaml" 2>/dev/null | wc -l)

    expected_deps=0
    missing_path_deps=0

    if [ "$package" = "zikzak_share_handler" ]; then
      expected_deps=3
      if [ "$actual_path_deps" -lt 3 ]; then
        missing_path_deps=1
      fi
    elif [[ "$package" = *"_android"* || "$package" = *"_ios"* || "$package" = *"_macos"* ]]; then
      expected_deps=1
      if [ "$actual_path_deps" -lt 1 ]; then
        missing_path_deps=1
      fi
    fi

    if [ "$commented_paths" -gt 0 ]; then
      echo "⚠️ WARNING: $package still has $commented_paths commented path dependencies!"
      verify_issues=$((verify_issues + 1))
    fi

    if [ "$versioned_deps" -gt 0 ]; then
      echo "⚠️ WARNING: $package still has $versioned_deps versioned dependencies!"
      verify_issues=$((verify_issues + 1))
    fi

    if [ "$missing_path_deps" -gt 0 ]; then
      echo "⚠️ WARNING: $package is missing expected path dependencies! Found $actual_path_deps, expected ~$expected_deps"
      verify_issues=$((verify_issues + 1))
    else
      echo "✅ $package: Found $actual_path_deps path dependencies (expected ~$expected_deps)"
    fi
  fi
done

if [ $verify_issues -eq 0 ]; then
  echo "✅ VERIFICATION COMPLETE: Development setup is PERFECT!"
else
  echo "⚠️ VERIFICATION FOUND $verify_issues ISSUES: You may need to manually fix some dependencies."
fi

echo ""
echo "🔥🔥🔥 DEVELOPMENT MODE SETUP COMPLETE! 🔥🔥🔥"
echo "All packages now use path dependencies for local development!"
