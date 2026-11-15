---
name: starter-add-package
description: Evaluates and adds a pub.dev package safely (search, compare, check compatibility, wire it through a provider). Use when a task needs a new dependency, or the user asks "pakai package apa untuk ...".
---

# Add a package

1. Check `AGENTS.md` → "Approved stack". If an approved package already covers the need, use it.
   Replacing state management, networking, routing or model generation requires the developer's approval.
2. Search with Dart MCP `pub_dev_search` (2–3 queries). Compare top candidates in a short table:
   likes/popularity, publisher (verified?), last update, null-safety & Dart 3, platforms, license.
3. Recommend one and explain why; wait for approval if it is a new architectural dependency.
4. Add with Dart MCP `pub` (`add <name>`) or `flutter pub add <name>`. Dev-only tools: `--dev`.
5. On version conflicts: official skill `dart-resolve-package-conflicts`; never pin with `any`.
6. Wrap the package behind a small interface + `Provider` in `core/` (or the feature's `data/`) so it can
   be faked in tests — like `TokenStorage` wraps `flutter_secure_storage`.
7. Platform setup (Android manifest, iOS Info.plist, entitlements): apply it and list every file changed.
8. `make check`, then mention the package and its purpose in the summary.
