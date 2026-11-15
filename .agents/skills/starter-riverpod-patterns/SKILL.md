---
name: starter-riverpod-patterns
description: Riverpod 3 patterns used in this starter (Provider, Notifier, AsyncNotifier, family, autoDispose, ref.mounted, retry, overrides). Use when writing or reviewing providers and controllers.
---

# Riverpod 3 patterns

| Need | Use | Example in repo |
|---|---|---|
| Dependency (service, repo) | `Provider<T>` | `dioProvider`, `<feature>RepositoryProvider` |
| Sync state + methods | `Notifier<T>` + `NotifierProvider` | `ThemeModeController` |
| Async load + methods | `AsyncNotifier<T>` | generated `<Feature>Controller`; `AuthController`/`ProductsController` (branch `example`) |
| One-shot fetch by id | `FutureProvider.autoDispose.family<T, Arg>` | `productDetailProvider` |
| Form submit status | `AsyncNotifierProvider.autoDispose<_, void>` | `LoginController` |
| Event from core to feature | counter `Notifier<int>` + `ref.listen` | `sessionExpiryProvider` |

## Rules

- `ref.watch` in `build`/provider bodies; `ref.read` in callbacks; `ref.listen` for side effects
  (snackbar, navigation).
- After every `await` in a notifier method: `if (!ref.mounted) return;` before writing `state`.
- Stale responses: keep an `int _requestId`; ignore results whose id is not current.
- Keep old data during refresh: compute with `AsyncValue.guard`, then assign once.
- `autoDispose` for screen-scoped data; plain providers for app-wide state.
- Retry is global (`core/riverpod/retry_policy.dart`): only `NetworkException`, max 2.
- Tests: `ProviderContainer.test(overrides: [...], retry: (_, _) => null)`; widget tests wrap in
  `ProviderScope(overrides: ...)`.
- Imports: `package:flutter_riverpod/flutter_riverpod.dart`; `ProviderException`/`Override` come
  from `package:flutter_riverpod/misc.dart`. Do not use `legacy.dart` (StateNotifier, StateProvider).
