---
name: starter-code-audit
description: Reviews code changes (especially AI-generated) against the starter's architecture, Riverpod, API, security and testing rules, producing a Blocker/Major/Minor/Note report. Use before commits, after large AI edits, or when asked to review.
---

# Code audit

1. Collect the change set: `git diff` / `git diff --staged` (or the files the user names).
2. Run `make check` first (or Dart MCP `analyze_files` + `run_tests`); analyzer errors and failing
   tests are automatic **Blockers**.
3. Walk `docs/audit-checklist.md` section by section. Starter-specific checks:
   - Architecture: core imports nothing from app/features; features don't import `app_router.dart`.
   - New screen made by hand instead of `make feature`? → Minor (consistency).
   - HTTP outside `guardApi`, `Dio()` created in a feature, `DioException` in UI → Major.
   - `state =` after `await` without `ref.mounted` check → Major.
   - Secrets in code/config, tokens in logs → Blocker.
   - Subscriptions/controllers/timers not cancelled or disposed → Major.
   - Package added outside the approved stack in `AGENTS.md` without justification → Major.
   - Magic numbers instead of `AppSpacing`/`AppRadius`, raw path strings instead of `AppRoutes` → Minor.
   - New logic without tests → Major for controllers/repositories, Minor for widgets.
4. Report format (Indonesian):

```
## Hasil audit
Perintah: make check → <ringkasan hasil>

### Blocker
- lib/...:42 — <masalah>. Dampak: <...>. Saran: <...>
### Major
### Minor
### Note
### Kesimpulan
Siap commit / Perlu perbaikan (n Blocker, n Major)
```

Do not modify code during the audit unless the user asks afterwards.
