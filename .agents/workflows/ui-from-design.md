---
description: Bangun atau ubah tampilan halaman dari screenshot/mockup/Figma memakai token tema starter, lalu bandingkan hasilnya di perangkat.
---

1. Minta developer melampirkan gambar desain (atau link Figma) dan menyebut halaman/fitur tujuannya.
2. Muat skill `starter-ui-from-design`.
3. Uraikan dulu komponen, state, dan token yang akan dipakai; tanyakan bagian yang ambigu.
4. Bila halaman belum ada, buat fiturnya dulu dengan `/new-feature`.
5. Implementasikan widget di `presentation/` (pecah menjadi widget kecil, beri `Key`).
6. Jalankan di perangkat, ambil screenshot, bandingkan dengan desain, rapikan perbedaannya (cek juga mode gelap & layar kecil).
7. `make check`, lalu laporkan file yang diubah beserta screenshot akhir.
