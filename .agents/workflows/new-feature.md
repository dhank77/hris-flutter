---
description: Buat fitur baru lengkap (data, controller, halaman, test, route) dari generator framework.
---

1. Tanyakan ke developer: nama fitur (snake_case), nama model (PascalCase), endpoint API, dan key list di respons JSON bila belum disebutkan. Tunjukkan contoh respons API bila ada.
2. Muat skill `starter-new-feature` dan ikuti langkahnya.
3. Jalankan generator: `ENDPOINT=<endpoint> JSON_KEY=<key> make feature name=<nama> model=<Model>`.
4. Sesuaikan field model di `lib/features/<nama>/data/models/` dengan contoh JSON, lalu `make gen`.
5. Perbarui test `fromJson` dengan contoh JSON sungguhan (field opsional, nested, null).
6. Tambahkan pintu masuk navigasi bila diminta (`context.push(AppRoutes.<namaCamel>)`).
7. Jalankan `make check`.
8. Bila ada simulator/emulator aktif, verifikasi halaman baru dengan skill `starter-verify-on-device` (screenshot).
9. Laporkan hasil apa adanya, beserta daftar file yang dibuat/diubah.
