---
name: starter-verify-on-device
description: Runs the app on a simulator/emulator and verifies a feature end to end with the Dart MCP (launch, hot reload, runtime errors) and the mobile MCP (tap, type, screenshot). Use after implementing UI/flows, before saying a feature is done, or when asked to "coba di HP/emulator".
---

# Verify on device

Static checks prove the code compiles; this proves the feature works.

## Prerequisites

- A booted iOS Simulator (`xcrun simctl boot "iPhone 16"`) or Android emulator (`emulator -avd <name>`),
  or Chrome for web.
- MCP servers `dart` and `mobile` connected (`.agents/mcp_config.json`).

## Steps

1. `list_devices` (Dart MCP) → pick the running simulator/emulator.
2. `launch_app` with `--dart-define-from-file=config/dev.json`; keep the returned DTD URI.
3. With the `mobile` MCP: list elements / take a screenshot of the first screen.
4. Walk the user flow defined in the task, one action per step. Prefer elements with keys
   (e.g. `home.settings`) over coordinates.
5. After each important step: screenshot + `get_runtime_errors`. Any runtime error = stop and switch
   to skill `starter-debug-fix`.
6. Check edge states too: loading, empty, error/offline (toggle airplane mode or use a wrong base URL),
   long text, dark mode (Settings → Tema), small screen / landscape.
7. `stop_app` when done.

## Report

```
## Verifikasi di perangkat
Perangkat: <nama>      Alur: <langkah-langkah>
Hasil: ✅/❌ per langkah (+ screenshot)
Runtime error: tidak ada / <ringkasan>
Temuan UI: <overflow, teks terpotong, kontras, dsb>
```

Optionally turn a verified flow into a permanent test with the official skill
`flutter-add-integration-test`.
