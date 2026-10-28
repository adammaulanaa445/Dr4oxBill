/// Repository untuk mengelola data transaksi dan detail item di database.
library transaction_repository;

import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../core/database/app_database.dart';

/// Hasil operasi repository.
class TransactionRepositoryResult<T> {
  final T? data;
  final String? error;
  final bool success;

  TransactionRepositoryResult._({this.data, this.error, this.success = false});

  factory TransactionRepositoryResult.success(T data) {
    return TransactionRepositoryResult._(data: data, success: true);
  }

  factory TransactionRepositoryResult.error(String error) {
    return TransactionRepositoryResult._(error: error, success: false);
  }
}

class TransactionRepository {
  final AppDatabase _db = AppDatabase();

  /// Simpan transaksi baru secara atomik beserta detail item dan pergerakan stok.
  ///
  /// Semua operasi dilakukan dalam satu transaksi SQLite. Jika salah satu gagal,
  /// semua dibatalkan (rollback).
  Future<TransactionRepositoryResult<int>> createTransaction({
    required String transactionNumber,
    required DateTime transactionDate,
    required int subtotal,
    required int discount,
    required int total,
    required int cashReceived,
    required int changeAmount,
    required String paymentMethod,
    required List<Map<String, dynamic>>
        items, // item data untuk transaction_items
    required List<Map<String, dynamic>> stockUpdates, // pembaruan stok
  }) async {
    final db = await _db.database;

    try {
      await db.transaction((txn) async {
        // 1. Simpan transaksi utama.
        final now = DateTime.now();
        final transactionId = await txn.insert('transactions', {
          'transaction_number': transactionNumber,
          'transaction_date': transactionDate.toIso8601String(),
          'subtotal': subtotal,
          'discount': discount,
          'total': total,
          'cash_received': cashReceived,
          'change_amount': changeAmount,
          'payment_method': paymentMethod,
          'status': 'completed',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });

        // 2. Simpan detail semua item.
        for (final item in items) {
          await txn.insert('transaction_items', {
            'transaction_id': transactionId,
            'product_id': item['product_id'],
            'sku': item['sku'],
            'name': item['name'],
            'item_type': item['item_type'],
            'quantity': item['quantity'],
            'unit_price': item['unit_price'],
            'subtotal': item['subtotal'],
            'discount': item['discount'] ?? 0,
          });
        }

        // 3. Kurangi stok dan catat pergerakan stok.
        for (final update in stockUpdates) {
          await txn.update(
            'products',
            {
              'stock': update['new_stock'],
              'updated_at': now.toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [update['product_id']],
          );

          await txn.insert('stock_movements', {
            'product_id': update['product_id'],
            'movement_type': 'sale',
            'quantity_change': -update['quantity_sold'],
            'stock_before': update['stock_before'],
            'stock_after': update['new_stock'],
            'reason': 'Penjualan transaksi $transactionNumber',
            'reference_type': 'transaction',
            'reference_id': transactionId,
            'created_at': now.toIso8601String(),
          });
        }
      });

      return TransactionRepositoryResult.success(
          0); // transactionId tidak digunakan di sini
    } catch (e) {
      return TransactionRepositoryResult.error('Gagal menyimpan transaksi: $e');
    }
  }

  /// Ambil semua transaksi, dengan opsi filter status.
  Future<TransactionRepositoryResult<List<Map<String, dynamic>>>>
      getAllTransactions({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
  }) async {
    try {
      final db = await _db.database;
      String where = '';
      List<dynamic> whereArgs = [];

      final conditions = <String>[];

      if (status != null && status.isNotEmpty) {
        conditions.add('status = ?');
        whereArgs.add(status);
      }

      if (startDate != null) {
        conditions.add('transaction_date >= ?');
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        conditions.add('transaction_date <= ?');
        whereArgs.add(endDate.toIso8601String());
      }

      if (search != null && search.isNotEmpty) {
        conditions.add('transaction_number LIKE ?');
        whereArgs.add('%$search%');
      }

      if (conditions.isNotEmpty) {
        where = conditions.join(' AND ');
      }

      final maps = await db.query(
        'transactions',
        where: where.isEmpty ? null : where,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'transaction_date DESC',
      );

      return TransactionRepositoryResult.success(maps);
    } catch (e) {
      return TransactionRepositoryResult.error('Gagal memuat transaksi: $e');
    }
  }

  /// Ambil detail transaksi beserta item-itemnya berdasarkan ID.
  Future<TransactionRepositoryResult<Map<String, dynamic>?>>
      getTransactionDetail(
    int transactionId,
  ) async {
    try {
      final db = await _db.database;

      final transactionMaps = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
        limit: 1,
      );

      if (transactionMaps.isEmpty) {
        return TransactionRepositoryResult.success(null);
      }

      final items = await db.query(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [transactionId],
        orderBy: 'id ASC',
      );

      return TransactionRepositoryResult.success({
        'transaction': transactionMaps.first,
        'items': items,
      });
    } catch (e) {
      return TransactionRepositoryResult.error(
          'Gagal memuat detail transaksi: $e');
    }
  }

  /// Batalkan transaksi dan kembalikan stok barang fisik.
  Future<TransactionRepositoryResult<bool>> cancelTransaction({
    required int transactionId,
    required String reason,
  }) async {
    final db = await _db.database;

    return await db.transaction((txn) async {
      try {
        // Cek status transaksi saat ini.
        final maps = await txn.query(
          'transactions',
          where: 'id = ? AND status = ?',
          whereArgs: [transactionId, 'completed'],
          limit: 1,
        );

        if (maps.isEmpty) {
          return TransactionRepositoryResult.error(
            'Transaksi tidak ditemukan atau sudah dibatalkan.',
          );
        }

        final now = DateTime.now();

        // Tandai transaksi sebagai dibatalkan.
        await txn.update(
          'transactions',
          {
            'status': 'cancelled',
            'cancellation_reason': reason,
            'cancelled_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [transactionId],
        );

        // Ambil semua item transaksi.
        final items = await txn.query(
          'transaction_items',
          where: 'transaction_id = ?',
          whereArgs: [transactionId],
        );

        // Kembalikan stok untuk barang fisik.
        for (final item in items) {
          if (item['item_type'] == 'goods' && item['product_id'] != null) {
            final productId = item['product_id'] as int;
            final quantitySold = item['quantity'] as int;

            // Ambil stok saat ini.
            final productMaps = await txn.query(
              'products',
              where: 'id = ?',
              whereArgs: [productId],
              limit: 1,
            );

            if (productMaps.isNotEmpty) {
              final currentStock = productMaps.first['stock'] as int;
              final newStock = currentStock + quantitySold;

              await txn.update(
                'products',
                {
                  'stock': newStock,
                  'updated_at': now.toIso8601String(),
                },
                where: 'id = ?',
                whereArgs: [productId],
              );

              // Catat pergerakan stok pengembalian.
              await txn.insert('stock_movements', {
                'product_id': productId,
                'movement_type': 'return',
                'quantity_change': quantitySold,
                'stock_before': currentStock,
                'stock_after': newStock,
                'reason': 'Pengembalian stok pembatalan transaksi',
                'reference_type': 'transaction',
                'reference_id': transactionId,
                'created_at': now.toIso8601String(),
              });
            }
          }
        }

        return TransactionRepositoryResult.success(true);
      } catch (e) {
        return TransactionRepositoryResult.error(
            'Gagal membatalkan transaksi: $e');
      }
    });
  }

  /// Cek apakah nomor transaksi sudah ada (pencegahan duplikasi).
  Future<TransactionRepositoryResult<bool>> isTransactionNumberExists(
    String transactionNumber,
  ) async {
    try {
      final db = await _db.database;
      final maps = await db.query(
        'transactions',
        where: 'transaction_number = ?',
        whereArgs: [transactionNumber],
        limit: 1,
      );
      return TransactionRepositoryResult.success(maps.isNotEmpty);
    } catch (e) {
      return TransactionRepositoryResult.error(
          'Gagal memeriksa nomor transaksi: $e');
    }
  }
}

/// Tambahkan copyWith ke Transaction.
extension TransactionCopyWith on Transaction {
  Transaction copyWith({
    int? id,
    String? transactionNumber,
    DateTime? transactionDate,
    int? subtotal,
    int? discount,
    int? total,
    int? cashReceived,
    int? changeAmount,
    String? paymentMethod,
    String? status,
    String? cancellationReason,
    DateTime? cancelledAt,
    List<TransactionItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      transactionNumber: transactionNumber ?? this.transactionNumber,
      transactionDate: transactionDate ?? this.transactionDate,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      cashReceived: cashReceived ?? this.cashReceived,
      changeAmount: changeAmount ?? this.changeAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Tambahkan copyWith ke TransactionItem.
extension TransactionItemCopyWith on TransactionItem {
  TransactionItem copyWith({
    int? id,
    int? transactionId,
    int? productId,
    String? sku,
    String? name,
    String? itemType,
    int? quantity,
    int? unitPrice,
    int? subtotal,
    int? discount,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      itemType: itemType ?? this.itemType,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
    );
  }
}
