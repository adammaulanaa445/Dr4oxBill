/// Repository untuk mengelola pengaturan aplikasi (key-value) di database.
library setting_repository;

import '../models/setting.dart';
import '../core/database/app_database.dart';

class SettingRepositoryResult<T> {
  final T? data;
  final String? error;
  final bool success;

  SettingRepositoryResult._({this.data, this.error, this.success = false});

  factory SettingRepositoryResult.success(T data) {
    return SettingRepositoryResult._(data: data, success: true);
  }

  factory SettingRepositoryResult.error(String error) {
    return SettingRepositoryResult._(error: error, success: false);
  }
}

class SettingRepository {
  final AppDatabase _db = AppDatabase();

  /// Ambil nilai pengaturan berdasarkan kunci.
  Future<SettingRepositoryResult<String?>> getSetting(String key) async {
    try {
      final db = await _db.database;
      final maps = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (maps.isEmpty) {
        return SettingRepositoryResult.success(null);
      }
      return SettingRepositoryResult.success((maps.first['value'] as String));
    } catch (e) {
      return SettingRepositoryResult.error('Gagal memuat pengaturan: $e');
    }
  }

  /// Simpan atau perbarui pengaturan.
  Future<SettingRepositoryResult<bool>> saveSetting(
    String key,
    String value,
  ) async {
    try {
      final db = await _db.database;
      final now = DateTime.now();

      // Cek apakah sudah ada.
      final existing = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        await db.update(
          'settings',
          {
            'value': value,
            'updated_at': now.toIso8601String(),
          },
          where: 'key = ?',
          whereArgs: [key],
        );
      } else {
        await db.insert('settings', {
          'key': key,
          'value': value,
          'updated_at': now.toIso8601String(),
        });
      }

      return SettingRepositoryResult.success(true);
    } catch (e) {
      return SettingRepositoryResult.error('Gagal menyimpan pengaturan: $e');
    }
  }

  /// Ambil semua pengaturan.
  Future<SettingRepositoryResult<List<Setting>>> getAllSettings() async {
    try {
      final db = await _db.database;
      final maps = await db.query('settings', orderBy: 'key ASC');
      return SettingRepositoryResult.success(
        maps.map((m) => Setting.fromMap(m)).toList(),
      );
    } catch (e) {
      return SettingRepositoryResult.error('Gagal memuat pengaturan: $e');
    }
  }
}

/// Tambahkan copyWith ke Setting.
extension SettingCopyWith on Setting {
  Setting copyWith({
    String? key,
    String? value,
    DateTime? updatedAt,
  }) {
    return Setting(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
