#!/usr/bin/env bash
# Menyiapkan project dari nol sampai siap dijalankan. Aman dijalankan ulang.
#
#   ./scripts/setup.sh
#
# Variabel opsional:
#   ORG=com.namakamu          bundle id / package Android (default com.example)
#   PLATFORMS=android,ios,web platform yang dibuat (default android,ios,web)
#   SKIP_CHECKS=1             lewati analyze & test
set -euo pipefail

cd "$(dirname "$0")/.."
PROJECT_NAME="flutter_antigravity_starter_pack"
ORG="${ORG:-com.example}"
PLATFORMS="${PLATFORMS:-android,ios,web}"

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$1"; }

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK tidak ditemukan. Install Flutter dan pastikan 'flutter' ada di PATH."
  exit 1
fi

step "Versi Flutter"
flutter --version

# ---------------------------------------------------------------------------
step "Membuat folder platform ($PLATFORMS)"
# `flutter create .` hanya menambahkan file yang belum ada; kode di lib/ aman.
flutter create . \
  --project-name "$PROJECT_NAME" \
  --org "$ORG" \
  --platforms "$PLATFORMS" \
  --no-pub

# Template counter default tidak cocok dengan project ini.
if [[ -f test/widget_test.dart ]] && grep -q "MyApp" test/widget_test.dart; then
  rm test/widget_test.dart
  echo "Menghapus test/widget_test.dart bawaan template."
fi

# ---------------------------------------------------------------------------
# Flutter >= 3.47 memindahkan Material ke paket `material_ui` dan menandai
# `package:flutter/material.dart` sebagai deprecated.
FLUTTER_ROOT="$(flutter --version --machine 2>/dev/null \
  | grep '"flutterRoot"' | sed -E 's/.*"flutterRoot": *"([^"]+)".*/\1/')"
MATERIAL_LIB="$FLUTTER_ROOT/packages/flutter/lib/material.dart"
if [[ -f "$MATERIAL_LIB" ]] && grep -q "@Deprecated" "$MATERIAL_LIB"; then
  step "Migrasi import Material → package:material_ui"
  if grep -q "^  material_ui:" pubspec.yaml || flutter pub add material_ui; then
    while IFS= read -r file; do
      perl -pi -e 's#package:flutter/material\.dart#package:material_ui/material_ui.dart#g' "$file"
    done < <(grep -rl "package:flutter/material.dart" lib test 2>/dev/null || true)
  else
    warn "Gagal menambahkan material_ui; import lama dipertahankan (hanya peringatan deprecated)."
  fi
fi

# ---------------------------------------------------------------------------
if [[ -d android ]]; then
  step "Konfigurasi Android"
  MANIFEST="android/app/src/main/AndroidManifest.xml"
  # Template hanya memberi izin INTERNET untuk debug; release juga butuh.
  if [[ -f "$MANIFEST" ]] && ! grep -q "android.permission.INTERNET" "$MANIFEST"; then
    perl -0pi -e 's#(<manifest[^>]*>)#$1\n    <uses-permission android:name="android.permission.INTERNET" />#' "$MANIFEST"
    echo "Menambahkan izin INTERNET."
  fi
  # flutter_secure_storage membutuhkan minSdk >= 23.
  if [[ -f android/app/build.gradle.kts ]]; then
    perl -pi -e 's/minSdk = flutter\.minSdkVersion/minSdk = maxOf(23, flutter.minSdkVersion)/' android/app/build.gradle.kts
  elif [[ -f android/app/build.gradle ]]; then
    perl -pi -e 's/minSdk(Version)? flutter\.minSdkVersion/minSdkVersion Math.max(23, flutter.minSdkVersion)/' android/app/build.gradle
  fi
fi

if [[ -d macos ]]; then
  step "Konfigurasi macOS"
  for f in macos/Runner/DebugProfile.entitlements macos/Runner/Release.entitlements; do
    if [[ -f "$f" ]] && ! grep -q "com.apple.security.network.client" "$f"; then
      perl -0pi -e 's#</dict>#\t<key>com.apple.security.network.client</key>\n\t<true/>\n</dict>#' "$f"
      echo "Menambahkan izin jaringan di $f"
    fi
  done
fi

# ---------------------------------------------------------------------------
step "Mengunduh dependensi"
if ! flutter pub get; then
  warn "Resolusi versi gagal, mencoba 'flutter pub upgrade --major-versions'..."
  flutter pub upgrade --major-versions
fi

step "Code generation (Freezed + JSON)"
dart run build_runner build --delete-conflicting-outputs

step "Format kode"
dart format lib test

if [[ "${SKIP_CHECKS:-0}" == "1" ]]; then
  warn "SKIP_CHECKS=1 → analyze & test dilewati."
  exit 0
fi

step "flutter analyze"
flutter analyze

step "flutter test"
flutter test

printf '\n\033[1;32mSelesai! Jalankan aplikasi dengan:\033[0m\n'
echo "  flutter run --dart-define-from-file=config/dev.json"
