---
trigger: always_on
---

# Project contract (always on)

This repository is **Flutter AI Starter**: Flutter + Riverpod 3 + Dio + Freezed + GoRouter, built to be
developed together with AI agents. Full contract: `AGENTS.md`. Architecture: `docs/architecture.md`.
Agent toolkit guide: `docs/ai-dev-workflow.md`.

- Talk to the developer in **Bahasa Indonesia**. Identifiers in English; code comments follow the
  existing style (Indonesian).
- Dependency rule: `app → features → core`. `lib/core/` never imports `lib/app/` or `lib/features/`.
  Features may import `core/`, `app/router/app_routes.dart` and `app/theme/` only.
- New screen/module: run `make feature name=<snake_name>` (skill `starter-new-feature`), never hand-scaffold.
- Every HTTP call goes through `guardApi`; UI never sees `DioException`.
- Prefer MCP tools over guessing (Dart MCP): `analyze_files`, `run_tests`, `pub_dev_search`, `launch_app`,
  `dtd` → `get_runtime_errors`, `widget_inspector`, `hot_reload`/`hot_restart`. Use the `mobile` MCP to see
  the screen and tap through flows on a simulator/emulator.
- Project skills (`starter-*`) override official Flutter/Dart skills when they disagree
  (e.g. Dio instead of `http`, Freezed instead of hand-written JSON, mocktail instead of mockito).
- Never put secrets in code or committed config. Never run destructive commands (`rm -rf`, `git reset --hard`,
  `flutter clean` on CI caches) without asking.
- Before saying "done", run `make check` (format + analyze + test) and report the real output.
  Never claim a command passed without running it.
- Generated files (`*.g.dart`, `*.freezed.dart`) are never edited by hand; run `make gen`.
