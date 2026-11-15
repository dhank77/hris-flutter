---
name: starter-debug-fix
description: Finds and fixes bugs fast using the Dart MCP server (runtime errors, widget inspector, logs, hot reload) and a reproducing test. Use when the user reports a crash, red screen, layout overflow, wrong data, or "it doesn't work".
---

# Debug & fix

Goal: reproduce → locate → fix → prove with a test. Do not guess-edit.

## 1. Reproduce

- App already running from the IDE? Connect: Dart MCP `dtd` → `listDtdUris` → `connect`.
- Not running? `list_devices`, then `launch_app` (pass `--dart-define-from-file=config/dev.json`).
- Ask the user for the exact steps if missing. Use the `mobile` MCP to perform them on the
  simulator/emulator (tap, type, swipe) and take a screenshot of the broken state.

## 2. Collect evidence (before touching code)

| Symptom | Tool |
|---|---|
| Exception / red screen | `get_runtime_errors`, `get_app_logs` |
| Overflow, unbounded constraints | `get_runtime_errors` + `widget_inspector` (widget tree around the error); load official skill `flutter-fix-layout-issues` |
| Wrong data on screen | read controller state flow: page → controller → repository → api; check JSON with a real response |
| Analyzer/type errors | `analyze_files` |
| Package/version conflicts | official skill `dart-resolve-package-conflicts` |

## 3. Locate & explain

State the root cause in one or two sentences, with file:line, before editing.
Typical starter-specific causes:
- `state =` after dispose → missing `if (!ref.mounted) return;`.
- Stale results → missing `requestId` check (see `ProductsController` (branch `example`)).
- `TypeError` in `fromJson` → model field should be nullable/`@Default`, then `make gen`.
- 401 loops → check `skipAuthKey` and `AuthInterceptor` retry flag.

## 4. Fix & prove

1. Write a failing test that reproduces the bug (skill `starter-testing`).
2. Apply the smallest fix.
3. `hot_reload` (or `hot_restart` if state/initState/main changed) and re-run the steps with the `mobile` MCP.
4. `run_tests` / `make check`. Report: cause, fix, test added, evidence (screenshot or log).
