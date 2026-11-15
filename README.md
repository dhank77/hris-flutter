# Flutter AI Starter — Google Antigravity

Boilerplate Flutter siap pakai dengan **Riverpod 3 + Dio + Freezed + GoRouter + secure storage**,
plus toolkit agen AI (skills, rules, workflow, MCP) yang mempercepat pengembangan di
Google Antigravity, Claude Code, dan agen lain yang membaca `AGENTS.md`.

## Dua branch

| Branch | Isi | Kapan dipakai |
|---|---|---|
| `main` | Boilerplate kosong: shell aplikasi, infrastruktur `core/`, halaman Beranda & Pengaturan, generator, toolkit agen | Memulai proyek baru |
| `example` | `main` + fitur contoh dengan [DummyJSON](https://dummyjson.com): login, pemulihan sesi, refresh token, guard redirect + deep link, daftar produk berpaginasi, pencarian, detail, beserta testnya | Belajar polanya, dan rujukan bagi agen AI |

```bash
git clone https://github.com/dhank77/flutter-ai-starter-pack.git my_app
cd my_app                 # branch main
git switch example        # lihat contoh lengkap
git diff main example     # semua yang ditambahkan contoh
```

Mengambil satu fitur contoh ke proyekmu, misalnya login:

```bash
git checkout example -- lib/features/auth lib/app/router/route_guards.dart test/features/auth
```

## Isi boilerplate

| Area | Isi |
|---|---|
| Shell aplikasi | `bootstrap()` dengan error handler global, `ProviderScope` (retry policy, logger), GoRouter terpusat, tema terang/gelap dari seed color + design token |
| Infrastruktur | Satu Dio bersama, `AuthInterceptor` (bearer token + refresh yang bisa dipasang lewat `tokenRefresherProvider`), pemetaan error ke `AppException`, log HTTP tanpa token, secure storage, konfigurasi per lingkungan via `--dart-define-from-file` |
| UI dasar | `AsyncValueView`, `LoadingView`/`ErrorView`/`EmptyView`, extension `context.*`, halaman Beranda dan Pengaturan (tema tersimpan) |
| Generator | `make feature name=posts` → model Freezed, api, repository, controller, halaman, test, dan route |
| AI untuk developer | 10 skill proyek `starter-*` + 15 skill resmi Flutter/Dart + 1 skill Riverpod, 3 rules (termasuk hot reload otomatis resmi Flutter), 7 workflow slash command, MCP `dart` & `mobile` |
| Kualitas | Lint ketat; test untuk mapper error, interceptor, `AsyncValueView`, dan alur aplikasi |

## Struktur singkat

```
lib/
├── main.dart          # bootstrap(() => const App())
├── app/               # shell aplikasi: bootstrap, router/, theme/
├── core/              # infrastruktur reusable: network, error, storage, widgets, extensions
└── features/          # modul fitur: <fitur>/{data, application, presentation}
```

Aturan dependensi: `app → features → core`. `core/` tidak pernah mengimpor fitur atau app.
Detail lengkap dan alur data ada di [`docs/architecture.md`](docs/architecture.md).

## 1. Prasyarat

- Flutter SDK (disarankan versi stable terbaru), `flutter doctor -v` tanpa error.
- Xcode (iOS) dan/atau Android Studio (Android). Chrome cukup untuk mencoba di web.
- Git; Node.js/npm opsional (untuk Skills).

## 2. Setup (sekali saja)

```bash
cd my_app
chmod +x scripts/*.sh
./scripts/setup.sh
```

Skrip ini akan:

1. Membuat folder platform `android/`, `ios/`, `web/` (`flutter create .` — kode di `lib/` tidak disentuh).
2. Pada Flutter ≥ 3.47: memigrasi import Material ke paket `material_ui`.
3. Menambahkan izin INTERNET (release Android) dan `minSdk ≥ 23` untuk secure storage.
4. `flutter pub get` (fallback ke `pub upgrade --major-versions` bila versi bentrok).
5. Generate kode Freezed/JSON dengan `build_runner`.
6. `dart format`, `flutter analyze`, `flutter test`.

Opsi: `ORG=com.namakamu PLATFORMS=android,ios,web,macos ./scripts/setup.sh`.

## 3. Menjalankan

```bash
flutter run --dart-define-from-file=config/dev.json
# atau di browser
flutter run -d chrome --dart-define-from-file=config/dev.json
```

Di Antigravity/VS Code, pilih konfigurasi **Dev (DummyJSON)** di panel Run.
Aplikasi terbuka di halaman Beranda. Langkah berikutnya: `make feature name=posts`.

## 4. Perintah harian

```bash
make help                      # daftar semua perintah
make run                       # jalankan app (config/dev.json)
make run-web                   # jalankan di Chrome
make watch                     # build_runner watch saat mengubah model Freezed
make check                     # format + analyze + test (wajib sebelum commit)
make feature name=posts        # buat fitur baru lengkap + route
```

## 5. Membuat fitur baru

```bash
make feature name=posts              # model Post, endpoint /posts (langsung jalan di DummyJSON)
make feature name=recipes model=Recipe
ENDPOINT=/v1/articles JSON_KEY=data make feature name=articles
```

Generator membuat model Freezed, api, repository, controller (`AsyncNotifier`), halaman
dengan pull-to-refresh, test controller, mendaftarkan `AppRoutes.<fitur>` + `GoRoute`, lalu
menjalankan build_runner. Buka halamannya dengan `context.push(AppRoutes.posts)`.
Template bisa diubah di `scripts/templates/feature/`.

File `*.freezed.dart` dan `*.g.dart` adalah hasil generate: jangan diedit manual dan
tidak perlu di-commit bila tim selalu menjalankan build_runner (atau commit bila CI butuh).

## 6. Mengembangkan bersama agen AI

Panduan lengkap: [`docs/ai-dev-workflow.md`](docs/ai-dev-workflow.md). Ringkasnya, ketik di panel agent Antigravity:

| Perintah | Fungsi |
|---|---|
| `/new-feature` | Fitur lengkap lewat generator + model dari contoh JSON + verifikasi |
| `/ui-from-design` | Bangun halaman dari screenshot/mockup memakai token tema, bandingkan di emulator |
| `/fix-bug` | Reproduksi di emulator, baca runtime error & widget tree, test → perbaikan → bukti |
| `/verify` | Jalankan app dan uji alur end-to-end dengan screenshot (mobile MCP) |
| `/check` | Format, analyze, test, perbaiki sampai hijau |
| `/audit` | Review perubahan (Blocker/Major/Minor/Note) sebelum commit |
| `/belajar` | Penjelasan langkah demi langkah sebuah file/konsep, tanpa mengubah kode |

Persiapan: Node.js (untuk mobile MCP), simulator/emulator menyala, lalu cek **MCP Servers** di Antigravity
(`dart` dan `mobile` harus tersambung). Perbarui skill resmi Flutter/Dart dengan `make skills`.

## 7. Konfigurasi lingkungan

`config/dev.json` dibaca lewat `--dart-define-from-file`:

```json
{ "API_BASE_URL": "https://dummyjson.com", "ENABLE_HTTP_LOGS": true }
```

Untuk produksi salin `config/prod.example.json` → `config/prod.json` (di-ignore git).
Nilai dart-define ikut ter-bundle di aplikasi, jadi **jangan simpan secret** di sana.

## 8. Skills resmi & MCP

Skill sudah tersedia di `.agents/skills/` (ikut di-commit agar seluruh tim memakai versi yang sama):

- **Proyek** (`starter-*`, 10 skill): arsitektur, fitur baru, API, Riverpod, testing, audit, debug, verifikasi di perangkat, UI dari desain, menambah package.
- **Resmi tim Flutter & Dart** (15 skill): layout & responsive, perbaikan layout error, routing, lokalisasi, widget/integration test, widget preview, static analysis, runtime error, konflik package, pattern matching, coverage, dokumentasi.
- **Komunitas**: `state-management-riverpod`.

`make skills` mengambil versi terbaru skill resmi. Skill yang bertentangan dengan stack (paket `http`, JSON manual, mockito) sengaja tidak dipasang.

MCP di `.agents/mcp_config.json`:
- `dart` — server resmi Dart & Flutter: analisis, test, pencarian pub.dev, menjalankan app, hot reload, runtime error, widget inspector (butuh Dart SDK terbaru).
- `mobile` — Mobile Next MCP: agen melihat layar dan mengetuk/mengetik di simulator/emulator (butuh Node.js).

MCP opsional (Context7, Firebase, Figma) ada di `docs/ai-dev-workflow.md`. Jangan commit API key/token.
`AGENTS.md` adalah kontrak coding untuk agen; `docs/audit-checklist.md` untuk mereview perubahan buatan AI.

## 9. Urutan belajar

Lihat [`docs/learning-roadmap.md`](docs/learning-roadmap.md). Peta konsep → file contoh:

| Konsep | Lihat di |
|---|---|
| `Provider`, dependency injection | `core/network/dio_provider.dart` |
| `Notifier` + persistensi | `app/theme/theme_mode_controller.dart` |
| Menampilkan `AsyncValue` secara seragam | `core/widgets/async_value_view.dart` |
| Inisialisasi app & error global | `app/bootstrap.dart` |
| Interceptor & refresh token | `core/network/auth_interceptor.dart`, `core/network/token_refresher.dart` |
| Pemetaan error | `core/error/app_exception.dart`, `core/network/api_guard.dart` |
| `AsyncNotifier`, Freezed + JSON | fitur hasil `make feature name=posts` |
| Paginasi, pencarian, async safety | `features/products/` di branch `example` |
| `ref.watch` / `ref.read` / `ref.listen`, form login | `features/auth/` di branch `example` |
| GoRouter: redirect, path param, deep link | `app/router/` di branch `example` |
| Test dengan override & mock | `test/` (lebih lengkap di branch `example`) |

## Troubleshooting

- **`Could not find a file named "pubspec.yaml"` / error build_runner** → jalankan dari root project.
- **Konflik versi paket** → `make upgrade` (upgrade mayor + codegen).
- **`make: command not found`** → `xcode-select --install`, atau jalankan perintah di Makefile secara manual.
- **macOS desktop**: `flutter_secure_storage` butuh Keychain Sharing di Xcode (Signing & Capabilities).
- **Gambar tidak muncul di web** → CDN gambar harus mengizinkan CORS; DummyJSON sudah mengizinkan.

## Referensi

- Riverpod: https://riverpod.dev/
- Dio: https://pub.dev/packages/dio
- Freezed: https://pub.dev/packages/freezed
- GoRouter: https://pub.dev/packages/go_router
- DummyJSON: https://dummyjson.com/docs
- Antigravity Skills: https://antigravity.google/docs/skills
- Antigravity MCP: https://antigravity.google/docs/mcp
- Flutter AI tools: https://docs.flutter.dev/ai/tools
- Flutter-Skills: https://github.com/zakariaf/Flutter-Skills
- DucafeCat Skills: https://github.com/ducafecat/skills
# hris-flutter
