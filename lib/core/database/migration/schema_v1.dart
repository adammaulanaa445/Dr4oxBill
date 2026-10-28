/// Skema database versi 1 — struktur awal Dr4oxBill.
///
/// Semua tabel dibuat di sini. Data lama tidak dihapus saat migrasi.
library schema_v1;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Buat semua tabel dan indeks untuk versi 1.
Future<void> createAll(Database db) async {
  await db.transaction((txn) async {
    // Tabel kategori produk.
    await txn.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tabel produk dan jasa.
    await txn.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sku TEXT UNIQUE NOT NULL,
        category_id INTEGER,
        item_type TEXT NOT NULL CHECK(item_type IN ('goods', 'service')),
        cost_price INTEGER NOT NULL DEFAULT 0,
        selling_price INTEGER NOT NULL DEFAULT 0,
        stock INTEGER NOT NULL DEFAULT 0,
        min_stock INTEGER NOT NULL DEFAULT 0,
        photo_path TEXT,
        description TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    // Tabel transaksi.
    await txn.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_number TEXT UNIQUE NOT NULL,
        transaction_date TEXT NOT NULL,
        subtotal INTEGER NOT NULL DEFAULT 0,
        discount INTEGER NOT NULL DEFAULT 0,
        total INTEGER NOT NULL DEFAULT 0,
        cash_received INTEGER NOT NULL DEFAULT 0,
        change_amount INTEGER NOT NULL DEFAULT 0,
        payment_method TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'completed',
        cancellation_reason TEXT,
        cancelled_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tabel detail item transaksi.
    await txn.execute('''
      CREATE TABLE IF NOT EXISTS transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        product_id INTEGER,
        sku TEXT NOT NULL,
        name TEXT NOT NULL,
        item_type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price INTEGER NOT NULL,
        subtotal INTEGER NOT NULL,
        discount INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id),
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    // Tabel riwayat pergerakan stok.
    await txn.execute('''
      CREATE TABLE IF NOT EXISTS stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        movement_type TEXT NOT NULL
          CHECK(movement_type IN ('in', 'out', 'adjustment', 'sale', 'return')),
        quantity_change INTEGER NOT NULL,
        stock_before INTEGER NOT NULL,
        stock_after INTEGER NOT NULL,
        reason TEXT,
        reference_type TEXT,
        reference_id INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    // Tabel pengaturan aplikasi.
    await txn.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Indeks untuk pencarian dan pelaporan yang cepat.
    await txn.execute('''
      CREATE INDEX IF NOT EXISTS idx_products_sku
      ON products(sku)
    ''');

    await txn.execute('''
      CREATE INDEX IF NOT EXISTS idx_products_category
      ON products(category_id)
    ''');

    await txn.execute('''
      CREATE INDEX IF NOT EXISTS idx_products_active
      ON products(is_active)
    ''');

    await txn.execute('''
      CREATE INDEX IF NOT EXISTS idx_transactions_number
      ON transactions(transaction_number)
    ''');

    await txn.execute('''
      CREATE INDEX IF NOT EXISTS idx_transactions_date
      ON transactions(transaction_date)
    ''');

    await txn.execute('''
      CREATE INDEX IF NOT EXISTS idx_transactions_status
      ON transactions(status)
    ''');

    await txn.execute('''
      CREATE INDEX IF NOT EXISTS idx_transaction_items_transaction
      ON transaction_items(transaction_id)
    ''');

    await txn.execute('''
      CREATE INDEX IF NOT EXISTS idx_stock_movements_product
      ON stock_movements(product_id)
    ''');

    await txn.execute('''
      CREATE INDEX IF NOT EXISTS idx_stock_movements_date
      ON stock_movements(created_at)
    ''');

    // Masukkan kategori awal.
    final now = DateTime.now().toIso8601String();
    final categories = [
      'Oli',
      'Sparepart',
      'Ban',
      'Jasa',
      'Aksesori',
    ];

    for (final name in categories) {
      await txn.execute(
        'INSERT INTO categories (name, created_at, updated_at) VALUES (?, ?, ?)',
        [name, now, now],
      );
    }
  });
}
