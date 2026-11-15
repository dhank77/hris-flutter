#!/usr/bin/env bash
# Generator fitur baru (data → application → presentation + test + route).
#
#   ./scripts/new_feature.sh <nama_fitur> [NamaModel]
#   make feature name=posts
#
# Contoh (langsung jalan dengan DummyJSON):
#   ./scripts/new_feature.sh posts            # model Post, endpoint /posts
#   ./scripts/new_feature.sh recipes Recipe   # lalu sesuaikan field model
#
# Variabel opsional:
#   ENDPOINT=/v1/articles   endpoint API (default /<nama-fitur>)
#   JSON_KEY=data           key list di respons (default <namaFitur>)
set -euo pipefail
cd "$(dirname "$0")/.."

usage() {
  sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
}

[[ $# -ge 1 ]] || usage
FEATURE="$1"
if [[ ! "$FEATURE" =~ ^[a-z][a-z0-9_]*$ ]]; then
  echo "Nama fitur harus snake_case, mis. 'posts' atau 'user_profiles'."
  exit 1
fi
if [[ -d "lib/features/$FEATURE" ]]; then
  echo "Fitur '$FEATURE' sudah ada di lib/features/$FEATURE."
  exit 1
fi

pascal() { printf '%s' "$1" | perl -pe 's/(^|_)([a-z0-9])/\U$2/g'; }
camel() { printf '%s' "$1" | perl -pe 's/_([a-z0-9])/\U$1/g'; }
title() { printf '%s' "$1" | perl -pe 's/_/ /g; s/\b([a-z])/\U$1/g'; }

PKG="$(grep -m1 '^name:' pubspec.yaml | awk '{print $2}')"
FEATURE_PASCAL="$(pascal "$FEATURE")"
FEATURE_CAMEL="$(camel "$FEATURE")"
FEATURE_TITLE="$(title "$FEATURE")"
MODEL="${2:-$(pascal "${FEATURE%s}")}"
if [[ ! "$MODEL" =~ ^[A-Z][A-Za-z0-9]*$ ]]; then
  echo "Nama model harus PascalCase, mis. 'Post'."
  exit 1
fi
MODEL_SNAKE="$(printf '%s' "$MODEL" | perl -pe 's/([a-z0-9])([A-Z])/$1_$2/g; $_ = lc')"
ROUTE_PATH="/$(printf '%s' "$FEATURE" | tr '_' '-')"
ENDPOINT="${ENDPOINT:-$ROUTE_PATH}"
JSON_KEY="${JSON_KEY:-$FEATURE_CAMEL}"

export PKG FEATURE FEATURE_PASCAL FEATURE_CAMEL FEATURE_TITLE MODEL MODEL_SNAKE \
  ROUTE_PATH ENDPOINT JSON_KEY

TPL="scripts/templates/feature"
render() {
  mkdir -p "$(dirname "$2")"
  perl -pe '
    s/__PKG__/$ENV{PKG}/g;
    s/__FEATURE_PASCAL__/$ENV{FEATURE_PASCAL}/g;
    s/__FEATURE_CAMEL__/$ENV{FEATURE_CAMEL}/g;
    s/__FEATURE_TITLE__/$ENV{FEATURE_TITLE}/g;
    s/__FEATURE__/$ENV{FEATURE}/g;
    s/__MODEL_SNAKE__/$ENV{MODEL_SNAKE}/g;
    s/__MODEL__/$ENV{MODEL}/g;
    s/__ENDPOINT__/$ENV{ENDPOINT}/g;
    s/__JSON_KEY__/$ENV{JSON_KEY}/g;
  ' "$TPL/$1" > "$2"
  echo "  + $2"
}

DIR="lib/features/$FEATURE"
echo "Membuat fitur '$FEATURE' (model $MODEL, route $ROUTE_PATH, endpoint $ENDPOINT)"
render model.dart.tmpl "$DIR/data/models/$MODEL_SNAKE.dart"
render api.dart.tmpl "$DIR/data/${FEATURE}_api.dart"
render repository.dart.tmpl "$DIR/data/${FEATURE}_repository.dart"
render controller.dart.tmpl "$DIR/application/${FEATURE}_controller.dart"
render page.dart.tmpl "$DIR/presentation/${FEATURE}_page.dart"
render controller_test.dart.tmpl "test/features/$FEATURE/application/${FEATURE}_controller_test.dart"

# --- Daftarkan route -------------------------------------------------------
ROUTES="lib/app/router/app_routes.dart"
ROUTER="lib/app/router/app_router.dart"

perl -0pi -e 's{^([ \t]*)// <generator:paths>}{$1static const $ENV{FEATURE_CAMEL} = \x27$ENV{ROUTE_PATH}\x27;\n\n$1// <generator:paths>}m' "$ROUTES"
perl -0pi -e 's{^// <generator:imports>}{import \x27package:$ENV{PKG}/features/$ENV{FEATURE}/presentation/$ENV{FEATURE}_page.dart\x27;\n// <generator:imports>}m' "$ROUTER"
perl -0pi -e 's{^([ \t]*)// <generator:routes>}{$1GoRoute(\n$1  path: AppRoutes.$ENV{FEATURE_CAMEL},\n$1  builder: (context, state) => const $ENV{FEATURE_PASCAL}Page(),\n$1),\n$1// <generator:routes>}m' "$ROUTER"
echo "  ~ $ROUTES (AppRoutes.$FEATURE_CAMEL)"
echo "  ~ $ROUTER (GoRoute)"

# --- Codegen & format ------------------------------------------------------
if command -v dart >/dev/null 2>&1; then
  echo "Menjalankan build_runner..."
  dart run build_runner build --delete-conflicting-outputs
  dart format "$DIR" "test/features/$FEATURE" "$ROUTES" "$ROUTER" >/dev/null
fi

cat <<EOF

Selesai. Langkah berikutnya:
  1. Sesuaikan field di $DIR/data/models/$MODEL_SNAKE.dart lalu: make gen
  2. Buka halaman dari mana saja: context.push(AppRoutes.$FEATURE_CAMEL)
  3. make check   (format + analyze + test)
EOF
