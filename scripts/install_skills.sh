#!/usr/bin/env bash
# Memasang skill AGENT RESMI tim Flutter & Dart (+ satu skill Riverpod komunitas)
# ke .agents/skills/ — folder yang dibaca Antigravity, Claude Code, Cursor, Copilot, dll.
#
#   ./scripts/install_skills.sh        (atau: make skills)
#
# Skill proyek (starter-*) sudah ada di repo dan TIDAK disentuh.
# Hanya skill yang cocok dengan stack starter yang dipasang:
#   - dilewati: flutter-use-http-package (kita pakai Dio),
#               flutter-implement-json-serialization (kita pakai Freezed),
#               dart-generate-test-mocks (kita pakai mocktail), skill CLI/FFI.
set -euo pipefail
cd "$(dirname "$0")/.."

DEST=".agents/skills"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$DEST"

FLUTTER_SKILLS=(
  flutter-apply-architecture-best-practices
  flutter-build-responsive-layout
  flutter-fix-layout-issues
  flutter-setup-declarative-routing
  flutter-setup-localization
  flutter-add-widget-test
  flutter-add-integration-test
  flutter-add-widget-preview
)
DART_SKILLS=(
  dart-run-static-analysis
  dart-fix-runtime-errors
  dart-add-unit-test
  dart-resolve-package-conflicts
  dart-use-pattern-matching
  dart-collect-coverage
  dart-write-documentation
)
COMMUNITY_SKILLS=(
  state-management-riverpod   # zakariaf/Flutter-Skills — resmi belum ada skill Riverpod
)

install_from() { # <repo-url> <folder-skills-di-repo> <nama...>
  local repo="$1" sub="$2"; shift 2
  local dir="$TMP/$(basename "$repo" .git)-$RANDOM"
  echo "==> $repo"
  git clone --quiet --depth 1 "$repo" "$dir"
  for skill in "$@"; do
    if [[ -d "$dir/$sub/$skill" ]]; then
      rm -rf "$DEST/$skill"
      cp -R "$dir/$sub/$skill" "$DEST/$skill"
      echo "  + $skill"
    else
      echo "  ! tidak ditemukan di upstream: $skill"
    fi
  done
}

install_from https://github.com/flutter/skills.git skills "${FLUTTER_SKILLS[@]}"
install_from https://github.com/dart-lang/skills.git skills "${DART_SKILLS[@]}"
install_from https://github.com/zakariaf/Flutter-Skills.git skills "${COMMUNITY_SKILLS[@]}"

echo
echo "Selesai. Skill terpasang di $DEST:"
ls -1 "$DEST" | sed 's/^/  - /'
echo
echo "Skill adalah instruksi pihak ketiga: baca SKILL.md-nya, lalu commit agar tim memakai versi yang sama."
echo "Bila skill resmi bertentangan dengan starter (mis. memakai http/mockito), skill starter-* yang berlaku."
