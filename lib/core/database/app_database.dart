
/// Database aplikasi Dr4oxBill untuk Web dan Desktop.
library app_database;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../../core/constants/app_constants.dart';
import 'migration/schema_v1.dart' as schema;

class AppDatabase {
  static AppDatabase? _instance;
  static Database? _db;

  AppDatabase._();

  factory AppDatabase() => _instance ??= AppDatabase._();

  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }

    late final Database openedDb;

    if (kIsWeb) {
      // Database web tersimpan di IndexedDB browser.
      openedDb = await databaseFactoryFfiWeb.openDatabase(
        databaseFileName,
        options: OpenDatabaseOptions(
          version: databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onDowngrade: _onDowngrade,
        ),
      );
    } else {
      // Database desktop tetap menggunakan SQLite FFI.
      sqfliteFfiInit();

      final dir = await getApplicationDocumentsDirectory();
      final dbPath = path.join(dir.path, databaseFileName);

      openedDb = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onDowngrade: _onDowngrade,
        ),
      );
    }

    await openedDb.execute('PRAGMA foreign_keys = ON');

    _db = openedDb;
    return openedDb;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await schema.createAll(db);
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Pertahankan migrasi yang sudah ada.
  }

  static Future<void> _onDowngrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Pertahankan perilaku downgrade yang sudah ada.
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }

  static Future<void> deleteDatabaseFile() async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Penghapusan database web perlu ditangani '
        'menggunakan API database web.',
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(dir.path, databaseFileName);

    await databaseFactoryFfi.deleteDatabase(dbPath);
  }
}
