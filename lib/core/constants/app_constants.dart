/// Konstanta aplikasi Dr4oxBill.
library app_constants;

/// Nama aplikasi yang ditampilkan kepada pengguna.
const String appName = 'Dr4oxBill';

/// Nama usaha default yang digunakan pada struk dan laporan.
const String defaultBusinessName = 'Dr4ox Motor';

/// Versi aplikasi.
const String appVersion = '1.0.0';

/// Symbol mata uang Rupiah.
const String currencySymbol = 'Rp';

/// Pemisah ribuan untuk format Rupiah.
const String thousandsSeparator = '.';

/// Pemisah desimal untuk format Rupiah.
const String decimalSeparator = ',';

/// Default batas minimum stok untuk produk baru.
const int defaultMinStock = 5;

/// Jenis item barang fisik.
const String itemTypeGoods = 'goods';

/// Jenis item jasa.
const String itemTypeService = 'service';

/// Status transaksi yang telah selesai.
const String transactionStatusCompleted = 'completed';

/// Status transaksi yang dibatalkan.
const String transactionStatusCancelled = 'cancelled';

/// Jenis pergerakan stok: masuk.
const String stockMovementIn = 'in';

/// Jenis pergerakan stok: keluar.
const String stockMovementOut = 'out';

/// Jenis pergerakan stok: penyesuaian.
const String stockMovementAdjustment = 'adjustment';

/// Jenis pergerakan stok: penjualan.
const String stockMovementSale = 'sale';

/// Jenis pergerakan stok: pengembalian pembatalan.
const String stockMovementReturn = 'return';

/// Metode pembayaran tunai.
const String paymentMethodCash = 'cash';

/// Metode pembayaran transfer.
const String paymentMethodTransfer = 'transfer';

/// Metode pembayaran debit/kredit.
const String paymentMethodCard = 'card';

/// Folder untuk menyimpan foto produk di dalam direktori data aplikasi.
const String photosFolderName = 'product_photos';

/// Nama file database SQLite.
const String databaseFileName = 'dr4ox_bill.db';

/// Versi skema database saat ini.
const int databaseVersion = 1;
