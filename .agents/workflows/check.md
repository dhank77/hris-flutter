---
description: Jalankan quality gate (format, analyze, test) dan perbaiki masalah yang muncul.
---

1. Jalankan `make gen` bila ada perubahan pada file yang memakai Freezed/json_serializable.
2. Jalankan `make check` (atau Dart MCP `dart_format`, `analyze_files`, `run_tests`).
3. Jika ada error analyzer atau test gagal: baca pesan error, perbaiki penyebabnya (bukan menonaktifkan lint atau menghapus test). Untuk error yang bisa diperbaiki otomatis, coba Dart MCP `dart_fix` dulu, lalu ulangi langkah 2. Maksimal 3 putaran; setelah itu berhenti dan jelaskan sisa masalahnya.
4. Laporkan ringkas: perintah yang dijalankan, hasilnya, dan file yang diubah untuk perbaikan.
