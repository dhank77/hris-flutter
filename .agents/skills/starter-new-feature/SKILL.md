---
name: starter-new-feature
description: Creates a new feature module with the project generator (model, api, repository, controller, page, test, route). Use whenever the user asks for a new screen, module, or resource list.
---

# New feature

Never scaffold by hand — the generator keeps every feature identical.

## Steps

1. Pick names: feature `snake_case` plural (`posts`, `user_profiles`), model `PascalCase` singular (`Post`).
2. Find the endpoint and a real JSON sample. Note the list key (`{"posts": [...]}` → `posts`) or a bare list.
3. Run:
   ```bash
   ENDPOINT=/posts JSON_KEY=posts make feature name=posts model=Post
   ```
   This creates `lib/features/<name>/{data,application,presentation}`, a controller test,
   adds `AppRoutes.<nameCamel>` + a `GoRoute`, then runs build_runner.
4. Edit `data/models/<model>.dart` to match the JSON:
   - always-present → `required`; optional → nullable or `@Default(...)`;
   - nested objects → their own `@freezed` class; lists → `@Default(<T>[]) List<T>`.
5. `make gen`, then extend the generated test with the real JSON sample.
6. Add navigation entry if requested: `context.push(AppRoutes.<nameCamel>)`.
7. `make check`.

## Afterwards (optional upgrades)

- Detail page: `FutureProvider.autoDispose.family<Model, int>` + route `':id'` (reference: `lib/features/products` on branch `example`).
- Pagination/search: follow `ProductsController` (branch `example`) (requestId pattern for stale responses).
- Templates live in `scripts/templates/feature/` — change them to change every future feature.
