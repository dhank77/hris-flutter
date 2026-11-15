# Project Instructions — Flutter AI Starter

## Mission
Build maintainable Flutter applications with a clear separation between presentation, state, data access and infrastructure. The developer must be able to understand and audit every change.

## Approved stack
- Flutter / Dart
- Riverpod 3 (`flutter_riverpod`)
- Dio for HTTP
- Freezed + `json_serializable` for immutable models and JSON mapping
- GoRouter for navigation
- `shared_preferences` for non-sensitive preferences
- `flutter_secure_storage` for secrets/tokens when appropriate
- `build_runner` for code generation

Do not add another state-management, networking, model-generation or routing framework without explaining the trade-off and asking first.

## Architecture
- Prefer feature-first organization.
- Keep widgets focused on rendering and user interaction.
- Put state transitions and feature logic in Riverpod `Notifier` / `AsyncNotifier`.
- Put HTTP calls in services/data sources.
- Put application-facing data operations behind repositories.
- Keep DTO/model mapping explicit and testable.
- Dependencies flow inward; presentation must not instantiate Dio or repositories directly.
- Avoid abstractions that do not solve a real problem.

## Project layout (already scaffolded)
Dependency rule: `app → features → core`. Full description: `docs/architecture.md`.
- `lib/main.dart` — one line: `bootstrap(() => const App())`.
- `lib/app/` — application shell; the ONLY place that knows every feature.
  - `bootstrap.dart`: async init, global error handlers, `ProviderScope` (retry policy, `ProviderLogger`, overrides).
  - `router/`: `app_router.dart` (GoRouter + generator markers), `app_routes.dart` (path constants).
  - `theme/`: `app_theme.dart`, `app_tokens.dart` (AppSpacing/AppRadius/AppDurations), `theme_mode_controller.dart`.
- `lib/core/` — reusable infrastructure; must never import `lib/app/` or `lib/features/`.
  - `network/` (dioProvider, AuthInterceptor, tokenRefresherProvider, RedactingLogInterceptor, guardApi), `error/` (AppException, mapDioException, describeError),
    `storage/`, `session/`, `logging/`, `riverpod/retry_policy.dart`, `config/env.dart`,
    `extensions/context_extensions.dart`, `widgets/` (AsyncValueView, LoadingView, ErrorView, EmptyView).
- `lib/features/<feature>/{data,application,presentation}` — features may import `core/`, `app/router/app_routes.dart` and `app/theme/`, never `app_router.dart` or `bootstrap.dart`.

## Branches
- `main` is the empty boilerplate: only `features/home` and `features/settings`.
- `example` adds reference features on top of `main`: `auth` (login, session restore, DummyJSON token refresh,
  route guard with deep link) and `products` (pagination, search with debounce, detail page) plus their tests.
- When a skill points to a reference file that does not exist locally, read it from that branch:
  `git show example:<path>` (e.g. `git show example:lib/features/products/application/products_controller.dart`).
  Do not copy reference features into `main` unless the user asks.

## Conventions
- New features: run `make feature name=<snake_name>` (templates in `scripts/templates/feature/`); do not hand-scaffold.
- Render `AsyncValue` with `AsyncValueView`; show snackbars with `context.showSnackBar`.
- Use `AppSpacing`/`AppRadius`/`AppDurations` instead of magic numbers; colors from `context.colors`.
- Wrap every HTTP call in `guardApi`; UI never sees `DioException`.
- Navigate with `context.go/push(AppRoutes.x)`; never hardcode path strings.
- Daily commands: `make run`, `make watch`, `make check`.

## Riverpod rules
- Use `ref.watch` for reactive dependencies in build methods/providers.
- Use `ref.read` for imperative actions such as button callbacks.
- Use `ref.listen` for UI side effects such as navigation, dialogs or snackbars.
- Prefer `Notifier` / `AsyncNotifier` and immutable state.
- Model loading, data and failure states explicitly with `AsyncValue` where appropriate.
- Do not perform network requests directly inside widget `build`.
- Do not use legacy Riverpod APIs when a current Riverpod 3 API is available.
- Explain provider lifecycle, disposal and caching behavior when introducing non-trivial providers.

## Dio rules
- Use a shared, injected Dio instance.
- Configure base URL, timeouts and interceptors centrally.
- Convert transport/server failures into app-level errors at a clear boundary.
- Never log passwords, access tokens, refresh tokens or personal data.
- Do not hardcode production endpoints or secrets.

## Models and code generation
- Use Freezed for immutable data models where it adds value.
- Use `json_serializable` for JSON conversion.
- Never manually edit generated `.freezed.dart` or `.g.dart` files.
- After changing annotated models, run build_runner and inspect generated output.
- Test nullable fields, missing keys, defaults and nested objects.

## Routing
- Keep route definitions centralized with GoRouter.
- Use path parameters for resource identity and query parameters for filters/search.
- Keep auth redirects deterministic and testable.
- Do not put business logic in route builders.

## Quality gates
Before declaring work complete, run the relevant commands:
- `dart format .`
- `flutter analyze`
- `flutter test`
- `dart run build_runner build --delete-conflicting-outputs` when generated code changed

Report commands that were not run and why. Never claim a test or analyzer passed without executing it.

## AI change protocol
1. Inspect relevant files and existing conventions before editing.
2. State the proposed approach for changes spanning multiple files.
3. Make the smallest coherent change.
4. Preserve unrelated user code.
5. Do not delete, overwrite, migrate or reformat large areas without explicit approval.
6. Explain important design decisions and trade-offs.
7. Provide a concise audit summary: files changed, behavior, tests, risks and follow-ups.

## Agent toolkit (AI for development)
Guide: `docs/ai-dev-workflow.md`.
- Rules (`.agents/rules/`): `00-project-contract` (always on), `dart-style` (Dart files),
  `flutter-hot-reload` (official Flutter rule: hot reload/restart after editing `lib/`).
- Workflows (`.agents/workflows/`, slash commands): `/new-feature`, `/ui-from-design`, `/fix-bug`, `/verify`,
  `/check`, `/audit`, `/belajar`.
- MCP (`.agents/mcp_config.json`): `dart` (analyze, run_tests, pub_dev_search, launch_app, dtd,
  get_runtime_errors, widget_inspector, hot_reload) and `mobile` (screenshots, tap/type/swipe on simulator/emulator).
- Prefer evidence from MCP tools over assumptions; verify UI changes on a device before reporting done.

## Skill routing
Project skills (`.agents/skills/starter-*`) win when they conflict with official ones.
- Where code belongs / layer imports: `starter-architecture`
- New screen or module: `starter-new-feature`
- REST endpoints, models, errors: `starter-api-integration`
- Providers and controllers: `starter-riverpod-patterns` (+ community `state-management-riverpod`)
- Tests: `starter-testing` (+ official `flutter-add-widget-test`, `flutter-add-integration-test`, `dart-add-unit-test`)
- Bugs, crashes, layout errors: `starter-debug-fix` (+ official `flutter-fix-layout-issues`, `dart-fix-runtime-errors`)
- Run & check on a device: `starter-verify-on-device`
- Screens from a design/screenshot: `starter-ui-from-design` (+ official `flutter-build-responsive-layout`, `flutter-add-widget-preview`)
- New dependency: `starter-add-package` (+ official `dart-resolve-package-conflicts`)
- Reviews before commit: `starter-code-audit` (+ `docs/audit-checklist.md`)
- Localization: official `flutter-setup-localization`
- Do NOT use official `flutter-use-http-package` (we use Dio), `flutter-implement-json-serialization`
  (we use Freezed) or `dart-generate-test-mocks` (we use mocktail); they are intentionally not installed.
Update official skills with `make skills`.
