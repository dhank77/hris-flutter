# Alur Kerja Pengembangan Berbantuan AI

Starter ini dirancang untuk dikerjakan **bersama agen AI** (Antigravity, Claude Code, Cursor, Copilot, Codex).
Agen tidak menebak-nebak: ia membaca kontrak proyek, memakai skill yang tepat, dan memeriksa hasilnya
langsung di aplikasi yang berjalan lewat MCP.

```
                ┌──────────────────────────── AGENTS.md (kontrak proyek) ───────────────────────────┐
 Developer ──▶  │ Rules (.agents/rules)   selalu aktif / per jenis file                               │
  /workflow     │ Skills (.agents/skills) dipilih agen sesuai tugas: starter-* + resmi Flutter/Dart │
                │ MCP (.agents/mcp_config.json)                                                       │
                │   dart   → analyze, test, pub.dev, launch, hot reload, runtime error, widget tree │
                │   mobile → lihat layar, tap, ketik, swipe di simulator/emulator                   │
                └─────────────────────────────────────────────────────────────────────────────────────┘
```

## 1. Isi toolkit

| Lapisan | Lokasi | Isi |
|---|---|---|
| Kontrak | `AGENTS.md`, `CLAUDE.md` (→ `@AGENTS.md`) | stack, arsitektur, aturan, quality gate |
| Rules | `.agents/rules/` | `00-project-contract` (selalu), `dart-style` (file Dart), `flutter-hot-reload` (resmi Flutter: hot reload otomatis setelah edit `lib/`) |
| Skill proyek | `.agents/skills/starter-*` | architecture, new-feature, api-integration, riverpod-patterns, testing, code-audit, debug-fix, verify-on-device, ui-from-design, add-package |
| Skill resmi | `.agents/skills/flutter-*`, `dart-*` | layout & responsive, routing, l10n, widget/integration test, widget preview, static analysis, runtime errors, package conflicts, pattern matching, coverage, dokumentasi |
| Skill komunitas | `.agents/skills/state-management-riverpod` | pola Riverpod umum |
| Workflows | `.agents/workflows/` | `/new-feature`, `/ui-from-design`, `/fix-bug`, `/verify`, `/check`, `/audit`, `/belajar` |
| MCP | `.agents/mcp_config.json` | `dart` (resmi), `mobile` (Mobile Next) |

Bila skill resmi bertentangan dengan starter (resmi memakai `http`, `mockito`, JSON manual), **skill `starter-*` yang menang**.
Perbarui skill resmi dengan `make skills`.

## 2. Persiapan sekali

1. Flutter/Dart terbaru (Dart MCP butuh `dart mcp-server`): `flutter upgrade`.
2. Node.js (untuk `npx` mobile MCP).
3. Simulator/emulator: `xcrun simctl boot "iPhone 16"` atau `emulator -avd <nama>`.
4. Buka folder proyek di Antigravity → Agent panel → **MCP Servers**: pastikan `dart` dan `mobile` hijau.
5. Customizations → pastikan rules, skills, dan workflows proyek terbaca.

## 3. Siklus kerja harian

```
/new-feature  →  /ui-from-design  →  /verify  →  /check  →  /audit  →  commit
                       ▲                │
                       └── /fix-bug ◀───┘ (bila ada temuan)
```

| Saya ingin… | Ketik | Agen akan… |
|---|---|---|
| Halaman/modul baru dari API | `/new-feature` | menjalankan generator, menyesuaikan model dari contoh JSON, test, verifikasi |
| Tampilan sesuai desain | `/ui-from-design` + lampirkan gambar | memetakan ke token tema, membangun widget, membandingkan screenshot |
| Memperbaiki bug | `/fix-bug` | reproduksi di emulator, baca runtime error & widget tree, test gagal → perbaikan → bukti |
| Memastikan fitur jalan | `/verify` | menjalankan app, mengetuk alur via mobile MCP, screenshot, cek error |
| Semua hijau sebelum commit | `/check` | format, analyze, test, perbaiki |
| Review kode buatan AI | `/audit` | laporan Blocker/Major/Minor/Note |
| Memahami kode | `/belajar` | penjelasan bertahap + latihan, tanpa mengubah kode |
| Pakai package baru | "tambah package untuk …" | skill `starter-add-package`: cari di pub.dev, bandingkan, bungkus dengan provider |

## 4. Pola prompt yang efektif

- **Beri konteks konkret**: endpoint + contoh JSON, screenshot desain, langkah reproduksi bug.
- **Minta rencana dulu untuk perubahan besar**: "Jelaskan rencanamu dan file yang akan diubah, tunggu persetujuan."
- **Minta bukti, bukan klaim**: "Tunjukkan output `make check` dan screenshot dari emulator."
- **Satu tugas per percakapan**; mulai percakapan baru untuk fitur berikutnya.
- **Selalu `/audit` sebelum commit**, apalagi untuk perubahan yang tidak Anda tulis sendiri.

## 5. MCP opsional (tambahkan sesuai kebutuhan)

Tambahkan ke `.agents/mcp_config.json` di dalam `mcpServers`:

```jsonc
// Dokumentasi package terbaru langsung di konteks agen
"context7": { "command": "npx", "args": ["-y", "@upstash/context7-mcp"] },
// Bila memakai Firebase (Auth, Firestore, Crashlytics)
"firebase": { "command": "npx", "args": ["-y", "firebase-tools@latest", "mcp"] }
```

Untuk desain dari Figma, aktifkan Figma Dev Mode MCP server dari aplikasi Figma desktop dan tambahkan sesuai panduan Figma.
Setiap MCP baru memberi agen akses tambahan — pasang hanya yang Anda butuhkan.
