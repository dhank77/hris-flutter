---
name: starter-architecture
description: Explains and enforces the app → features → core architecture of Flutter AI Starter. Use when deciding where new code belongs, moving files, or reviewing imports between layers.
---

# Starter architecture

## Layers

| Layer | Path | Owns | May import |
|---|---|---|---|
| App shell | `lib/app/` | `bootstrap.dart`, `app.dart`, `router/`, `theme/` | everything |
| Features | `lib/features/<name>/` | `data/`, `application/`, `presentation/` | `core/`, `app/router/app_routes.dart`, `app/theme/` |
| Core | `lib/core/` | network, error, storage, session, logging, riverpod, config, extensions, widgets | `core/` only |

## Where does my code go?

- HTTP endpoint + JSON → `features/<f>/data/<f>_api.dart` (wrap with `guardApi`).
- App-facing data operation, caching, combining sources → `features/<f>/data/<f>_repository.dart`.
- State and business rules → `features/<f>/application/` (`Notifier` / `AsyncNotifier`).
- Widgets and pages → `features/<f>/presentation/`.
- Reusable across features, no feature knowledge → `core/` (e.g. `core/widgets/`).
- New route → path constant in `app/router/app_routes.dart`, `GoRoute` in `app/router/app_router.dart`.
- App-wide startup work (Firebase, local DB) → `app/bootstrap.dart`, injected via `overrides`.
- Colors/spacing → `app/theme/`.
- Cross-feature data: read the other feature's public provider (e.g. `authControllerProvider`);
  never import its `data/` internals.

## Verify

```bash
grep -rln "starter_pack/\(app\|features\)/" lib/core          # must print nothing
grep -rln "app/router/app_router.dart\|app/bootstrap.dart" lib/features   # must print nothing
```
