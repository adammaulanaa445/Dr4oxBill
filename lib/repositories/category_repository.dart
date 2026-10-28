/// Repository untuk mengelola data kategori produk di database.
library category_repository;

import '../models/category.dart';
import '../core/database/app_database.dart';

/// Hasil operasi repository: berhasil dengan data atau gagal dengan pesan error.
class RepositoryResult<T> {
  final T? data;
  final String? error;
  final bool success;

  RepositoryResult._({
    this.data,
    this.error,
    this.success = false,
  });

  factory RepositoryResult.success(T data) {
    return RepositoryResult._(data: data, success: true);
  }

  factory RepositoryResult.error(String error) {
    return RepositoryResult._(error: error, success: false);
  }
}

class CategoryRepository {
  final AppDatabase _db = AppDatabase();

  /// Ambil semua kategori yang aktif.
  Future<RepositoryResult<List<Category>>> getAllCategories() async {
    try {
      final db = await _db.database;
      final maps = await db.query(
        'categories',
        orderBy: 'name ASC',
      );
      return RepositoryResult.success(
        maps.map((m) => Category.fromMap(m)).toList(),
      );
    } catch (e) {
      return RepositoryResult.error('Gagal memuat kategori: $e');
    }
  }

  /// Ambil kategori berdasarkan ID.
  Future<RepositoryResult<Category?>> getCategoryById(int id) async {
    try {
      final db = await _db.database;
      final maps = await db.query(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) {
        return RepositoryResult.success(null);
      }
      return RepositoryResult.success(Category.fromMap(maps.first));
    } catch (e) {
      return RepositoryResult.error('Gagal memuat kategori: $e');
    }
  }

  /// Tambah kategori baru.
  Future<RepositoryResult<int>> createCategory(Category category) async {
    try {
      final db = await _db.database;
      final now = DateTime.now();
      final cat = category.copyWith(
        createdAt: now,
        updatedAt: now,
      );
      final id = await db.insert('categories', cat.toMapForInsert());
      return RepositoryResult.success(id);
    } catch (e) {
      return RepositoryResult.error('Gagal menambah kategori: $e');
    }
  }

  /// Perbarui kategori.
  Future<RepositoryResult<bool>> updateCategory(Category category) async {
    try {
      final db = await _db.database;
      final now = DateTime.now();
      final cat = category.copyWith(updatedAt: now);
      final rows = await db.update(
        'categories',
        cat.toMap(),
        where: 'id = ?',
        whereArgs: [cat.id],
      );
      return RepositoryResult.success(rows > 0);
    } catch (e) {
      return RepositoryResult.error('Gagal memperbarui kategori: $e');
    }
  }

  /// Hapus kategori. Akan gagal jika kategori masih digunakan produk.
  Future<RepositoryResult<bool>> deleteCategory(int id) async {
    try {
      final db = await _db.database;

      // Cek apakah ada produk yang menggunakan kategori ini.
      final productResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM products WHERE category_id = ?',
        [id],
      );
      final productCount = (productResult.first['count'] as int?) ?? 0;
      if (productCount > 0) {
        return RepositoryResult.error(
          'Kategori tidak dapat dihapus karena masih digunakan oleh produk.',
        );
      }

      final rows = await db.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );
      return RepositoryResult.success(rows > 0);
    } catch (e) {
      return RepositoryResult.error('Gagal menghapus kategori: $e');
    }
  }

  /// Cek apakah nama kategori sudah ada (tidak termasuk ID yang diberikan).
  Future<RepositoryResult<bool>> isNameExists(
    String name, {
    int? excludeId,
  }) async {
    try {
      final db = await _db.database;
      if (excludeId != null) {
        final maps = await db.query(
          'categories',
          where: 'name = ? AND id != ?',
          whereArgs: [name, excludeId],
          limit: 1,
        );
        return RepositoryResult.success(maps.isNotEmpty);
      } else {
        final maps = await db.query(
          'categories',
          where: 'name = ?',
          whereArgs: [name],
          limit: 1,
        );
        return RepositoryResult.success(maps.isNotEmpty);
      }
    } catch (e) {
      return RepositoryResult.error('Gagal memeriksa nama kategori: $e');
    }
  }
}
