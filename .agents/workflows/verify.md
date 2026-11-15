---
description: Jalankan aplikasi di simulator/emulator dan uji sebuah alur dari ujung ke ujung, lengkap dengan screenshot.
---

1. Tanyakan alur yang ingin diuji bila belum disebutkan (contoh: "buka Beranda → Pengaturan → ganti tema ke Gelap").
2. Muat skill `starter-verify-on-device`.
3. Pastikan ada simulator/emulator aktif (`list_devices`). Bila tidak ada, beri tahu developer perintah untuk menyalakannya lalu tunggu.
4. Jalankan app, lakukan setiap langkah dengan mobile MCP, ambil screenshot dan cek `get_runtime_errors` setelah langkah penting.
5. Uji juga kondisi tepi: data kosong, error jaringan, teks panjang, mode gelap.
6. Tulis laporan verifikasi (format di skill). Jangan mengubah kode di workflow ini; usulkan `/fix-bug` bila ada temuan.
