#!/usr/bin/env bash
# Dependensi kini sudah dideklarasikan di pubspec.yaml.
# Skrip ini dipertahankan untuk kompatibilitas: ia menaikkan semua paket ke
# versi mayor terbaru yang cocok dengan SDK Anda, lalu menjalankan codegen.
#
# Untuk setup pertama kali, gunakan ./scripts/setup.sh
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK tidak ditemukan. Install Flutter dan pastikan flutter ada di PATH."
  exit 1
fi

echo "Menaikkan dependensi ke versi terbaru yang kompatibel..."
flutter pub upgrade --major-versions

echo "Menjalankan code generation..."
dart run build_runner build --delete-conflicting-outputs

echo
echo "Berikutnya: flutter analyze && flutter test"
echo "Periksa perubahan pubspec.yaml / breaking changes di CHANGELOG paket sebelum commit."
