/// Repository untuk mengelola riwayat pergerakan stok di database.
library stock_movement_repository;

import '../models/stock_movement.dart';
import '../core/database/app_database.dart';

class StockMovementRepositoryResult<T> {
  final T? data;
  final String? error;
  final bool success;

  StockMovementRepositoryResult._(
      {this.data, this.error, this.success = false});

  factory StockMovementRepositoryResult.success(T data) {
    return StockMovementRepositoryResult._(data: data, success: true);
  }

  factory StockMovementRepositoryResult.error(String error) {
    return StockMovementRepositoryResult._(error: error, success: false);
  }
}

class StockMovementRepository {
  final AppDatabase _db = AppDatabase();

  /// Ambil semua pergerakan stok untuk suatu produk.
  Future<StockMovementRepositoryResult<List<StockMovement>>>
      getMovementsForProduct(
    int productId,
  ) async {
    try {
      final db = await _db.database;
      final maps = await db.query(
        'stock_movements',
        where: 'product_id = ?',
        whereArgs: [productId],
        orderBy: 'created_at DESC',
      );
      return StockMovementRepositoryResult.success(
        maps.map((m) => StockMovement.fromMap(m)).toList(),
      );
    } catch (e) {
      return StockMovementRepositoryResult.error(
          'Gagal memuat pergerakan stok: $e');
    }
  }

  /// Ambil semua pergerakan stok dalam rentang tanggal.
  Future<StockMovementRepositoryResult<List<StockMovement>>>
      getMovementsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final db = await _db.database;
      final maps = await db.query(
        'stock_movements',
        where: 'created_at >= ? AND created_at <= ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: 'created_at DESC',
      );
      return StockMovementRepositoryResult.success(
        maps.map((m) => StockMovement.fromMap(m)).toList(),
      );
    } catch (e) {
      return StockMovementRepositoryResult.error(
          'Gagal memuat pergerakan stok: $e');
    }
  }

  /// Catat pergerakan stok baru.
  Future<StockMovementRepositoryResult<int>> createMovement(
      StockMovement movement) async {
    try {
      final db = await _db.database;
      final id = await db.insert('stock_movements', movement.toMapForInsert());
      return StockMovementRepositoryResult.success(id);
    } catch (e) {
      return StockMovementRepositoryResult.error(
          'Gagal mencatat pergerakan stok: $e');
    }
  }
}

/// Tambahkan copyWith ke StockMovement.
extension StockMovementCopyWith on StockMovement {
  StockMovement copyWith({
    int? id,
    int? productId,
    String? movementType,
    int? quantityChange,
    int? stockBefore,
    int? stockAfter,
    String? reason,
    String? referenceType,
    int? referenceId,
    DateTime? createdAt,
  }) {
    return StockMovement(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      movementType: movementType ?? this.movementType,
      quantityChange: quantityChange ?? this.quantityChange,
      stockBefore: stockBefore ?? this.stockBefore,
      stockAfter: stockAfter ?? this.stockAfter,
      reason: reason ?? this.reason,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
