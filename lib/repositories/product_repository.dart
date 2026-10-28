/// Repository untuk mengelola data produk dan jasa di database.
library product_repository;

import '../models/product.dart';
import '../core/database/app_database.dart';

/// Hasil operasi repository: berhasil dengan data atau gagal dengan pesan error.
class ProductRepositoryResult<T> {
  final T? data;
  final String? error;
  final bool success;

  ProductRepositoryResult._({this.data, this.error, this.success = false});

  factory ProductRepositoryResult.success(T data) {
    return ProductRepositoryResult._(data: data, success: true);
  }

  factory ProductRepositoryResult.error(String error) {
    return ProductRepositoryResult._(error: error, success: false);
  }
}

class ProductRepository {
  final AppDatabase _db = AppDatabase();

  /// Ambil semua produk (aktif dan nonaktif).
  Future<ProductRepositoryResult<List<Product>>> getAllProducts() async {
    try {
      final db = await _db.database;
      final maps = await db.query(
        'products',
        orderBy: 'name ASC',
      );
      return ProductRepositoryResult.success(
        maps.map((m) => Product.fromMap(m)).toList(),
      );
    } catch (e) {
      return ProductRepositoryResult.error('Gagal memuat produk: $e');
    }
  }

  /// Ambil hanya produk yang aktif.
  Future<ProductRepositoryResult<List<Product>>> getActiveProducts() async {
    try {
      final db = await _db.database;
      final maps = await db.query(
        'products',
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'name ASC',
      );
      return ProductRepositoryResult.success(
        maps.map((m) => Product.fromMap(m)).toList(),
      );
    } catch (e) {
      return ProductRepositoryResult.error('Gagal memuat produk: $e');
    }
  }

  /// Ambil produk berdasarkan ID.
  Future<ProductRepositoryResult<Product?>> getProductById(int id) async {
    try {
      final db = await _db.database;
      final maps = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) {
        return ProductRepositoryResult.success(null);
      }
      return ProductRepositoryResult.success(Product.fromMap(maps.first));
    } catch (e) {
      return ProductRepositoryResult.error('Gagal memuat produk: $e');
    }
  }

  /// Ambil produk berdasarkan SKU.
  Future<ProductRepositoryResult<Product?>> getProductBySku(String sku) async {
    try {
      final db = await _db.database;
      final maps = await db.query(
        'products',
        where: 'sku = ?',
        whereArgs: [sku],
        limit: 1,
      );
      if (maps.isEmpty) {
        return ProductRepositoryResult.success(null);
      }
      return ProductRepositoryResult.success(Product.fromMap(maps.first));
    } catch (e) {
      return ProductRepositoryResult.error('Gagal memuat produk: $e');
    }
  }

  /// Tambah produk baru. SKU harus unik.
  Future<ProductRepositoryResult<int>> createProduct(Product product) async {
    try {
      final db = await _db.database;
      final now = DateTime.now();
      final prod = product.copyWith(
        createdAt: now,
        updatedAt: now,
      );
      final id = await db.insert('products', prod.toMapForInsert());
      return ProductRepositoryResult.success(id);
    } catch (e) {
      return ProductRepositoryResult.error('Gagal menambah produk: $e');
    }
  }

  /// Perbarui produk. Harga historis pada transaksi lama tidak berubah.
  Future<ProductRepositoryResult<bool>> updateProduct(Product product) async {
    try {
      final db = await _db.database;
      final now = DateTime.now();
      final prod = product.copyWith(updatedAt: now);
      final rows = await db.update(
        'products',
        prod.toMap(),
        where: 'id = ?',
        whereArgs: [prod.id],
      );
      return ProductRepositoryResult.success(rows > 0);
    } catch (e) {
      return ProductRepositoryResult.error('Gagal memperbarui produk: $e');
    }
  }

  /// Nonaktifkan produk (soft delete). Produk dengan riwayat transaksi
  /// tidak boleh dihapus permanen.
  Future<ProductRepositoryResult<bool>> deactivateProduct(int id) async {
    try {
      final db = await _db.database;
      final rows = await db.update(
        'products',
        {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      return ProductRepositoryResult.success(rows > 0);
    } catch (e) {
      return ProductRepositoryResult.error('Gagal menonaktifkan produk: $e');
    }
  }

  /// Aktifkan kembali produk yang nonaktif.
  Future<ProductRepositoryResult<bool>> activateProduct(int id) async {
    try {
      final db = await _db.database;
      final rows = await db.update(
        'products',
        {'is_active': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      return ProductRepositoryResult.success(rows > 0);
    } catch (e) {
      return ProductRepositoryResult.error('Gagal mengaktifkan produk: $e');
    }
  }

  /// Perbarui stok produk dan catat pergerakan stok.
  /// Operasi ini harus dipanggil dalam transaksi database.
  Future<ProductRepositoryResult<bool>> updateStock({
    required int productId,
    required int newStock,
    required String movementType,
    required int quantityChange,
    required int stockBefore,
    required String? reason,
    String? referenceType,
    int? referenceId,
  }) async {
    try {
      final db = await _db.database;
      final now = DateTime.now();

      await db.update(
        'products',
        {
          'stock': newStock,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [productId],
      );

      await db.insert('stock_movements', {
        'product_id': productId,
        'movement_type': movementType,
        'quantity_change': quantityChange,
        'stock_before': stockBefore,
        'stock_after': newStock,
        'reason': reason,
        'reference_type': referenceType,
        'reference_id': referenceId,
        'created_at': now.toIso8601String(),
      });

      return ProductRepositoryResult.success(true);
    } catch (e) {
      return ProductRepositoryResult.error('Gagal memperbarui stok: $e');
    }
  }

  /// Cek apakah SKU sudah digunakan oleh produk lain (tidak termasuk ID yang diberikan).
  Future<ProductRepositoryResult<bool>> isSkuExists(
    String sku, {
    int? excludeId,
  }) async {
    try {
      final db = await _db.database;
      if (excludeId != null) {
        final maps = await db.query(
          'products',
          where: 'sku = ? AND id != ?',
          whereArgs: [sku, excludeId],
          limit: 1,
        );
        return ProductRepositoryResult.success(maps.isNotEmpty);
      } else {
        final maps = await db.query(
          'products',
          where: 'sku = ?',
          whereArgs: [sku],
          limit: 1,
        );
        return ProductRepositoryResult.success(maps.isNotEmpty);
      }
    } catch (e) {
      return ProductRepositoryResult.error('Gagal memeriksa SKU: $e');
    }
  }

  /// Ambil produk dengan stok menipis (stok <= min_stock).
  Future<ProductRepositoryResult<List<Product>>> getLowStockProducts() async {
    try {
      final db = await _db.database;
      final maps = await db.query(
        'products',
        where: 'is_active = ? AND stock <= min_stock',
        whereArgs: [1],
        orderBy: 'stock ASC',
      );
      return ProductRepositoryResult.success(
        maps.map((m) => Product.fromMap(m)).toList(),
      );
    } catch (e) {
      return ProductRepositoryResult.error('Gagal memuat stok menipis: $e');
    }
  }
}

/// Tambahkan copyWith ke Product.
extension ProductCopyWith on Product {
  Product copyWith({
    int? id,
    String? name,
    String? sku,
    int? categoryId,
    String? itemType,
    int? costPrice,
    int? sellingPrice,
    int? stock,
    int? minStock,
    String? photoPath,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      categoryId: categoryId ?? this.categoryId,
      itemType: itemType ?? this.itemType,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      photoPath: photoPath ?? this.photoPath,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
