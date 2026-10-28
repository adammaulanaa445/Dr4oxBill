/// State management untuk pengaturan aplikasi.
library setting_provider;

import 'package:flutter/foundation.dart';

import '../repositories/setting_repository.dart';

class SettingProvider extends ChangeNotifier {
  final _repository = SettingRepository();
  Map<String, String> _settings = {};
  bool _isLoading = false;
  String? _error;

  Map<String, String> get settings => Map.unmodifiable(_settings);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Ambil nilai pengaturan dengan default jika tidak ada.
  String get(String key, {String defaultValue = ''}) {
    return _settings[key] ?? defaultValue;
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.getAllSettings();
      if (result.success) {
        _settings = {for (final s in result.data!) s.key: s.value};
      } else {
        _error = result.error;
      }
    } catch (e) {
      _error = 'Gagal memuat pengaturan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SettingRepositoryResult<bool>> saveSetting(
    String key,
    String value,
  ) async {
    final result = await _repository.saveSetting(key, value);
    if (result.success) {
      _settings[key] = value;
      notifyListeners();
    }
    return result;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
