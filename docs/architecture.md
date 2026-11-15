# Arsitektur

Project ini dibagi menjadi tiga lapisan besar dengan aturan dependensi yang tegas:

```
            ┌─────────────────────────────┐
            │ app/   (shell aplikasi)     │  bootstrap, router, tema
            └──────────────┬──────────────┘
                           │ merangkai
            ┌──────────────▼──────────────┐
            │ features/  (modul fitur)    │  home, settings, fiturmu, …
            └──────────────┬──────────────┘
                           │ memakai
            ┌──────────────▼──────────────┐
            │ core/  (infrastruktur)      │  network, error, storage, widget dasar
            └─────────────────────────────┘
```

| Dari \ Ke | `core/` | `features/` | `app/router/app_routes.dart`, `app/theme/` | `app/` lainnya |
|---|---|---|---|---|
| `core/` | ✅ | ❌ | ❌ | ❌ |
| `features/` | ✅ | ⚠️ hanya lewat provider publik fitur lain | ✅ (konstanta route, token desain, mode tema) | ❌ |
| `app/` | ✅ | ✅ | ✅ | ✅ |

- **`core/` tidak mengenal fitur maupun aplikasi.** Bisa disalin ke project lain apa adanya.
- **`features/` tidak mengimpor `app_router.dart` atau `bootstrap.dart`.** Navigasi cukup
  `context.push(AppRoutes.xxx)`.
- **`app/` adalah satu-satunya tempat yang mengenal semua fitur** (untuk mendaftarkan route).

## Struktur folder

```
lib/
├── main.dart                         # bootstrap(() => const App())
├── app/                              # SHELL APLIKASI
│   ├── app.dart                      # MaterialApp.router + tema
│   ├── bootstrap.dart                # init async, error handler global, ProviderScope
│   ├── router/
│   │   ├── app_router.dart           # GoRouter: daftar route (+ penanda generator)
│   │   └── app_routes.dart           # konstanta path (dipakai fitur untuk navigasi)
│   └── theme/
│       ├── app_theme.dart            # ThemeData terang/gelap dari seed color
│       ├── app_tokens.dart           # AppSpacing, AppRadius, AppDurations
│       └── theme_mode_controller.dart# mode tema tersimpan (system/light/dark)
├── core/                             # INFRASTRUKTUR (reusable)
│   ├── config/env.dart               # nilai --dart-define (base URL, flag log)
│   ├── error/app_exception.dart      # AppException + mapper DioException + describeError
│   ├── extensions/context_extensions.dart  # context.colors, context.showSnackBar, …
│   ├── logging/
│   │   ├── app_logger.dart           # Logger bersama
│   │   └── provider_logger.dart      # log setiap provider yang gagal
│   ├── network/
│   │   ├── dio_provider.dart         # satu instance Dio
│   │   ├── auth_interceptor.dart     # bearer token + refresh 1x saat 401
│   │   ├── token_refresher.dart      # cara refresh token (default: tidak ada)
│   │   ├── redacting_log_interceptor.dart  # log HTTP tanpa token/body
│   │   └── api_guard.dart            # guardApi(): semua error → AppException
│   ├── riverpod/retry_policy.dart    # retry otomatis Riverpod 3 (hanya error jaringan)
│   ├── session/session_expiry.dart   # event "sesi berakhir" core → fitur auth
│   ├── storage/                      # token (secure storage), SharedPreferences
│   └── widgets/
│       ├── async_value_view.dart     # loading / error+retry / data untuk AsyncValue
│       └── state_views.dart          # LoadingView, ErrorView, EmptyView
└── features/                         # MODUL FITUR
    ├── home/        presentation (halaman awal, ganti sesukamu)
    └── settings/    presentation (tema, info API)
```

Setiap fitur memiliki struktur yang sama:

| Folder | Isi | Boleh tahu tentang |
|---|---|---|
| `data/` | `*_api.dart` (HTTP), `*_repository.dart`, `models/` (Freezed) | Dio, JSON |
| `application/` | `Notifier` / `AsyncNotifier` + state | repository |
| `presentation/` | halaman & widget | controller (lewat `ref`) |

## Alur data (contoh: fitur `posts` hasil generator)

```
PostsPage ──ref.watch──▶ postsControllerProvider (AsyncNotifier)
                                   │
                                   ▼
                          postsRepositoryProvider
                                   │
                                   ▼
                           postsApiProvider ──▶ dioProvider ──▶ HTTP
                                                     │
                                         AuthInterceptor (token, refresh)
```

1. Widget hanya `watch` state dan memanggil method controller.
2. Controller memegang aturan (paginasi, mengabaikan respons basi, status error).
3. Repository adalah API yang dilihat aplikasi; tempat cache/mapping ditambahkan.
4. Api tahu endpoint & JSON; semua error dibungkus `guardApi` → `AppException`.
5. UI menampilkan error lewat `AsyncValueView` / `describeError`, tidak pernah `DioException`.

## Autentikasi

Branch `main` sengaja tidak memiliki halaman login. Infrastrukturnya sudah ada di `core/`:

- `TokenStorage` menyimpan token di secure storage.
- `AuthInterceptor` menempelkan `Authorization: Bearer …` dan, saat 401, memanggil
  `tokenRefresherProvider` **sekali**. Default-nya `null`: 401 langsung dianggap sesi berakhir.
- `sessionExpiryProvider` memberi tahu fitur auth bahwa sesi berakhir.

Contoh lengkap (login, pemulihan sesi, refresh token DummyJSON, guard redirect + deep link)
ada di branch `example`. Untuk memakainya di proyekmu:

```bash
git checkout example -- lib/features/auth lib/app/router/route_guards.dart test/features/auth
```

lalu rangkai `refreshListenable` + `redirect` di `app_router.dart` seperti di branch tersebut.

## Menambah fitur baru

```bash
make feature name=posts            # atau: ./scripts/new_feature.sh posts [Post]
```

Generator membuat `data/`, `application/`, `presentation/`, test controller, mendaftarkan
`AppRoutes.posts` + `GoRoute`, lalu menjalankan build_runner. Contoh `posts` langsung
berjalan dengan DummyJSON. Untuk API lain: `ENDPOINT=/v1/articles JSON_KEY=data make feature name=articles`.

Template ada di `scripts/templates/feature/` — ubah sesuai konvensi tim Anda.

## Titik kustomisasi

| Ingin mengubah… | Lokasi |
|---|---|
| Warna brand | `AppTheme.seedColor` |
| Jarak, radius, durasi | `app/theme/app_tokens.dart` |
| Base URL / flag | `config/dev.json`, `config/prod.json` |
| Halaman pertama | `AppRoutes.home` |
| Endpoint refresh token | override `tokenRefresherProvider` |
| Pesan error | `core/error/app_exception.dart` |
| Kebijakan retry | `core/riverpod/retry_policy.dart` |
| Inisialisasi async baru (Firebase, DB lokal) | `app/bootstrap.dart` |
| Guard route (login, role, onboarding) | `redirect` di `app/router/app_router.dart` (contoh: branch `example`) |

## Tooling agent (AI untuk developer)

Panduan lengkap: [`docs/ai-dev-workflow.md`](ai-dev-workflow.md).

| Lapisan | Lokasi | Kapan aktif |
|---|---|---|
| Kontrak proyek | `AGENTS.md` (+ `CLAUDE.md` → `@AGENTS.md`) | selalu dibaca agen |
| Rules | `.agents/rules/*.md` | selalu / file Dart / setelah edit `lib/` (hot reload) |
| Skills | `.agents/skills/` — `starter-*` (proyek) + `flutter-*`, `dart-*` (resmi) | dipilih agen sesuai deskripsi tugas |
| Workflows | `.agents/workflows/*.md` | `/new-feature`, `/ui-from-design`, `/fix-bug`, `/verify`, `/check`, `/audit`, `/belajar` |
| MCP | `.agents/mcp_config.json` | `dart` (analisis, test, hot reload, runtime error, widget inspector) · `mobile` (layar & sentuhan di emulator) |
