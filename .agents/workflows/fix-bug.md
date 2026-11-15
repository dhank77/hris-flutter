---
description: Cari akar masalah sebuah bug, perbaiki, dan buktikan dengan test (memakai Dart MCP & mobile MCP).
---

1. Minta developer menjelaskan gejala dan langkah reproduksi bila belum ada (halaman mana, aksi apa, hasil yang diharapkan vs yang terjadi).
2. Muat skill `starter-debug-fix` dan ikuti urutannya: reproduksi → kumpulkan bukti → jelaskan akar masalah → perbaiki → buktikan.
3. Sebelum mengubah kode, tulis akar masalah dalam 1–2 kalimat beserta file:baris, lalu tunggu persetujuan bila perbaikannya menyentuh lebih dari 3 file.
4. Tambahkan test yang gagal sebelum perbaikan dan lulus sesudahnya.
5. `hot_reload`, ulangi langkah reproduksi di perangkat, ambil screenshot.
6. Jalankan `make check` dan laporkan: penyebab, perbaikan, test baru, bukti.
