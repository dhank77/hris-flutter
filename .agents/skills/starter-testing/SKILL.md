---
name: starter-testing
description: Writes tests the way this starter does (model JSON, repositories with fake HTTP, controllers with ProviderContainer.test, widgets with ProviderScope overrides). Use when adding tests or fixing failing ones.
---

# Testing

Run: `make test` (or `flutter test path/to/file_test.dart`). Test files mirror `lib/`.

| What | How | Example |
|---|---|---|
| Freezed model | `fromJson` full payload, missing optional fields, missing required → `TypeError`, round-trip | `test/features/products/data/product_model_test.dart` ¹ |
| Error mapping | build `DioException.*` and assert `AppException` type/message | `test/core/error/app_exception_test.dart` |
| Repository/API | real `Dio` + `FakeHttpAdapter` | `test/features/auth/data/auth_repository_test.dart` ¹ |
| Interceptor | two Dio sharing one adapter | `test/core/network/auth_interceptor_test.dart` |
| Controller | `ProviderContainer.test(overrides: [repo.overrideWithValue(mock)], retry: (_, _) => null)` | `products_controller_test.dart` ¹ |
| Race conditions | `Completer` to finish an old request after a newer one | `products_controller_test.dart` ¹ |
| Widget | `ProviderScope(overrides: ...)` + `MaterialApp(home: ...)`, find by `Key` | `login_page_test.dart` ¹ |
| Router guard | pure function `resolveAuthRedirect` | `test/app/router/route_guards_test.dart` ¹ |

## Rules

- No real network, no real secure storage (`InMemoryTokenStorage`).
- Run tests through the Dart MCP `run_tests` tool when available (structured output), else `make test`.
- autoDispose providers: `container.listen(...)` before reading, close in `addTearDown`.
- Wait for async state with a few `Future<void>.delayed(Duration.zero)` (`settle()` in fakes).
- A failing test is information: fix the code or the expectation with a reason; never delete it
  to make the suite green.

¹ Reference test on branch `example` — read it with `git show example:<path>`. On `main`, see also `test/core/network/auth_interceptor_test.dart` and `test/app/app_test.dart`.
