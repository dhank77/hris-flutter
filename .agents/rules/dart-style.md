---
trigger: glob
globs: lib/**/*.dart, test/**/*.dart
---

# Dart & Flutter style (applies to Dart files)

- Package imports only: `package:flutter_antigravity_starter_pack/...`.
- `prefer_single_quotes`, `prefer_final_locals`; trailing commas are handled by `dart format`.
- Wrap fire-and-forget futures in `unawaited(...)` (lint `unawaited_futures`).
- UI values: spacing/radius/durations from `AppSpacing`, `AppRadius`, `AppDurations`;
  colors and text styles from `context.colors` / `context.textTheme`; no magic numbers.
- Render `AsyncValue` with `AsyncValueView`; snackbars with `context.showSnackBar`.
- Navigate with `context.go/push(AppRoutes.x)`; never hardcode path strings.
- Controllers: check `ref.mounted` after every `await` before writing `state`.
- Widgets never create `Dio`, repositories, or call APIs inside `build`.
- Give interactive widgets a stable `Key('feature.element')` so tests and the mobile MCP can find them.
