# Learning Roadmap

Learn the stack in this order; avoid asking AI to generate a whole app before understanding the foundations.

1. Dart: null safety, classes, generics, collections, Future, async/await, exceptions.
2. Flutter: widget tree, stateful lifecycle, composition, forms, navigation.
3. Riverpod 3: ProviderScope, `ref.watch/read/listen`, Notifier, AsyncNotifier, AsyncValue, families, lifecycle, overrides and tests.
4. Dio: HTTP methods, request/response, interceptors, timeout, error mapping and cancellation.
5. Freezed + JSON: immutable model, nested JSON, defaults, nullable fields, generated code.
6. GoRouter: path/query parameters, nested routes, redirects and deep links.
7. Architecture: service, repository, feature-first structure, dependency direction.
8. Audit: read AI diffs, run analyzer/tests, inspect lifecycle/security/error handling and challenge assumptions.

For each lesson:
- Explain the concept first.
- Show a small example.
- Compare it with the nearest GetX concept when useful.
- Ask the learner to implement a small task without AI.
- Review the learner's code and explain why a correction is needed.
