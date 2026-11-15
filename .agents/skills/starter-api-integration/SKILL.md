---
name: starter-api-integration
description: Adds or changes REST API calls with Dio, Freezed models and error mapping following the starter conventions. Use for new endpoints, auth changes, pagination, or JSON parsing problems.
---

# API integration

## Rules

- One shared `dioProvider` (base URL from `Env`, `AuthInterceptor`, `RedactingLogInterceptor`).
  Never create `Dio()` in features.
- Every call: `guardApi(() async { ... })`. Parse with `asJsonObject(response.data)` then `Model.fromJson`.
- Request typing: `_dio.get<Object?>(...)` — never trust the body shape.
- Public endpoints (login, register): `Options(extra: {skipAuthKey: true})`.
- Errors reach UI only as `AppException` subclasses; messages are user-safe Indonesian text.

## Patterns

```dart
Future<List<Order>> fetchOrders({required int page}) => guardApi(() async {
  final response = await _dio.get<Object?>('/orders', queryParameters: {'page': page});
  final json = asJsonObject(response.data);
  final list = json['orders'];
  if (list is! List<dynamic>) throw const BadResponseException();
  return [for (final item in list) Order.fromJson(asJsonObject(item))];
});
```

- Cancel on dispose: create `CancelToken` in the provider, `ref.onDispose(token.cancel)`.
- Token refresh: override `tokenRefresherProvider` (`core/network/token_refresher.dart`); login/me live in the auth feature (reference: `lib/features/auth/data/auth_api.dart` on branch `example`).
- New base URL: `config/dev.json` → `API_BASE_URL`.

## Testing

Use `FakeHttpAdapter` from `test/helpers/fakes.dart` with a real `Dio` so JSON parsing and
error mapping are exercised (see `test/features/auth/data/auth_repository_test.dart` on branch `example`).
