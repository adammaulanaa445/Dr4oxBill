# Dr4oxBill

Aplikasi kasir desktop (Point of Sale) untuk bengkel motor Dr4ox Motor.

## Tentang Aplikasi

Dr4oxBill adalah aplikasi kasir desktop Windows yang dirancang khusus untuk kebutuhan bengkel motor. Aplikasi ini dapat beroperasi sepenuhnya tanpa koneksi internet dan menyimpan semua data secara lokal di SQLite.

Nama aplikasi: **Dr4oxBill**
Nama usaha default: **Dr4ox Motor**

## Fitur Utama

### Dashboard
- Omzet hari ini, jumlah transaksi, barang terjual
- Produk stok menipis
- Transaksi terbaru

### Kasir (POS)
- Katalog produk dalam kartu dengan foto
- Pencarian berdasarkan nama atau SKU
- Filter kategori
- Keranjang belanja dengan pengubahan kuantitas
- Diskon per item dan transaksi
- Perhitungan kembalian otomatis
- Metode pembayaran (tunai, transfer, kartu)
- Transaksi atomik dengan validasi stok
- Pencegahan transaksi ganda

### Kelola Produk dan Jasa
- CRUD produk dan jasa
- SKU unik
- Foto produk (pilih dari laptop)
- Stok minimum dan peringatan stok menipis
- Harga beli dan harga jual
- Nonaktifkan produk (soft delete)

### Kategori Produk
- CRUD kategori (Oli, Sparepart, Ban, Jasa, Aksesori)
- Validasi integritas (kategori yang digunakan tidak dapat dihapus)

### Manajemen Stok
- Penetapan stok awal
- Penambahan, pengurangan, penyesuaian stok
- Riwayat pergerakan stok lengkap
- Validasi stok tidak negatif

### Riwayat Transaksi
- Daftar transaksi dengan pencarian dan filter tanggal
- Detail transaksi lengkap
- Cetak ulang struk
- Pembatalan transaksi dengan pengembalian stok

### Struk PDF
- Struk PDF profesional untuk bengkel motor
- Simpan secara lokal, opsi buka file
- Layout siap untuk printer thermal

### Laporan
- Penjualan harian dan rentang tanggal
- Omzet, jumlah transaksi, transaksi dibatalkan
- Ekspor CSV

### Pengaturan
- Nama bengkel, alamat, telepon, pesan terima kasih
- Simpan secara permanen

### Backup dan Restore
- Backup database SQLite, foto produk, pengaturan
- Validasi arsip backup sebelum restore
- Safety backup data aktif sebelum restore
- Restore sebagai satu kesatuan yang konsisten

## Arsitektur

```
Dr4oxBill/
├── lib/
│   ├── main.dart                 # Entry point aplikasi
│   ├── app.dart                  # Konfigurasi tema dan routing
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart
│   │   ├── database/
│   │   │   ├── app_database.dart
│   │   │   └── migration/
│   │   │       └── schema_v1.dart
│   │   └── utils/
│   │       ├── money.dart
│   │       └── date_utils.dart
│   ├── models/
│   │   ├── category.dart
│   │   ├── product.dart
│   │   ├── transaction.dart
│   │   ├── transaction_item.dart
│   │   ├── stock_movement.dart
│   │   └── setting.dart
│   ├── repositories/
│   │   ├── category_repository.dart
│   │   ├── product_repository.dart
│   │   ├── transaction_repository.dart
│   │   ├── stock_movement_repository.dart
│   │   └── setting_repository.dart
│   ├── providers/
│   │   ├── app_provider.dart
│   │   ├── category_provider.dart
│   │   ├── product_provider.dart
│   │   ├── transaction_provider.dart
│   │   ├── setting_provider.dart
│   │   └── cart_provider.dart
│   ├── screens/
│   │   ├── dashboard_screen.dart
│   │   ├── pos_screen.dart
│   │   ├── product_list_screen.dart
│   │   ├── product_form_screen.dart
│   │   ├── category_list_screen.dart
│   │   ├── category_form_screen.dart
│   │   ├── stock_management_screen.dart
│   │   ├── transaction_history_screen.dart
│   │   ├── transaction_detail_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── backup_screen.dart
│   │   └── reports_screen.dart
│   ├── services/
│   │   ├── pdf_service.dart
│   │   ├── file_service.dart
│   │   ├── image_service.dart
│   │   ├── csv_service.dart
│   │   └── backup_service.dart
│   └── widgets/
│       └── sidebar.dart
├── test/
│   └── widget_test.dart
├── windows/                      # File native Windows (Flutter)
├── pubspec.yaml
└── README.md
```

## Database

- **Engine:** SQLite (via `sqflite_common_ffi` untuk dukungan Windows Desktop)
- **Lokasi:** `%APPDATA%\dr4ox_bill\dr4ox_bill.db`
- **Foto produk:** `%APPDATA%\dr4ox_bill\product_photos\`
- **Dokumen (PDF, CSV):** `%APPDATA%\dr4ox_bill\documents\`

Semua data disimpan secara lokal dan persisten antara restart aplikasi.

## Dependensi Utama

| Paket | Fungsi |
|-------|--------|
| `sqflite_common_ffi` | Database SQLite untuk Windows Desktop |
| `path_provider` | Akses direktori sistem Windows |
| `provider` | State management |
| `pdf` | Generate struk dan laporan PDF |
| `printing` | Pencetakan PDF ke printer Windows |
| `file_picker` | Pilih file foto produk |
| `image` | Validasi dan pemrosesan gambar |
| `csv` | Ekspor laporan ke CSV |
| `archive` | Arsip ZIP untuk backup/restore |
| `intl` | Format tanggal dan mata uang |
| `uuid` | ID unik untuk nomor transaksi |

## Prasyarat Pengembangan

- Flutter SDK (3.1.0 atau lebih baru)
- Dart SDK
- Windows 10 atau lebih baru
- **Visual Studio 2022 dengan workload "Desktop development with C++"**
  - MSVC v142 build tools
  - C++ CMake tools
  - Windows 10 SDK

## Cara Menjalankan

```bash
# Masuk ke direktori proyek
cd D:\Projek\Dr4oxBill

# Unduh dependensi
flutter pub get

# Jalankan analisis statis
flutter analyze

# Jalankan aplikasi (debug mode)
flutter run -d windows
```

## Build Release Windows

```bash
flutter build windows --release
```

Hasil build akan berada di `build/windows/runner/`.

**Catatan:** Build Windows membutuhkan Visual Studio C++ build tools yang sepenuhnya terpasang. Jika belum tersedia, build akan gagal dengan pesan "Unable to find suitable Visual Studio toolchain."

## Lokasi Data

Semua data aplikasi disimpan di direktori data aplikasi Windows:

```
%APPDATA%\dr4ox_bill\
├── dr4ox_bill.db          # Database SQLite
├── product_photos\        # Foto produk
└── documents\             # PDF struk dan laporan CSV
```

## Backup dan Restore

1. **Backup:** Buka menu Backup & Restore, klik "Buat Backup", pilih lokasi file ZIP
2. **Restore:** Klik "Pilih File Backup & Restore", pilih file ZIP, konfirmasi restore
3. Backup mencakup database, semua foto produk, dan metadata validasi

## Pemindahan Data ke Laptop Lain

1. Buat backup di laptop lama
2. Salin file ZIP backup ke laptop baru
3. Install Dr4oxBill di laptop baru
4. Jalankan aplikasi sekali (untuk membuat direktori data)
5. Gunakan fitur Restore untuk memulihkan data dari backup

## Keterbatasan

- **Printer thermal:** Belum terintegrasi karena belum ada printer untuk pengujian. Implementasi PDF sudah siap dan dapat dicetak ke printer mana pun melalui Windows.
- **Build Windows:** Terhambat karena Visual Studio C++ build tools belum terpasang di lingkungan pengembangan. Kode Dart siap dan lolos analisis statis.
- **WhatsApp sharing:** Tersedia sebagai opsi berbagi file PDF ketika internet tersedia, bukan fitur wajib.

## Pengujian

```bash
flutter test
```

## Lisensi

Aplikasi ini dikembangkan untuk Dr4ox Motor. Pribadi, tidak untuk didistribusikan publik.
