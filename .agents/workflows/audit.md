---
description: Audit perubahan kode (terutama hasil AI) memakai checklist framework sebelum di-commit.
---

1. Muat skill `starter-code-audit`.
2. Lihat perubahan dengan `git diff` (atau `git diff --staged`). Jika bukan repositori git, minta developer menyebutkan file yang diubah.
3. Periksa setiap perubahan terhadap `docs/audit-checklist.md` dan aturan di `.agents/rules/`.
4. Jalankan `make check`.
5. Tulis laporan dengan kategori Blocker / Major / Minor / Note. Setiap temuan: file:baris, masalah, dampak, saran perbaikan.
6. JANGAN mengubah kode pada workflow ini kecuali developer memintanya setelah membaca laporan.
