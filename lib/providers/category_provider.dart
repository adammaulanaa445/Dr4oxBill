/// State management untuk data kategori produk.
library category_provider;

import 'package:flutter/foundation.dart';

import '../models/category.dart' as cat_model;
import '../repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  final _repository = CategoryRepository();
  List<cat_model.Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<cat_model.Category> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.getAllCategories();
      if (result.success) {
        _categories = result.data!;
      } else {
        _error = result.error;
      }
    } catch (e) {
      _error = 'Gagal memuat kategori: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<RepositoryResult<int>> createCategory(
      cat_model.Category category) async {
    final result = await _repository.createCategory(category);
    if (result.success) {
      await loadCategories();
    }
    return result;
  }

  Future<RepositoryResult<bool>> updateCategory(
      cat_model.Category category) async {
    final result = await _repository.updateCategory(category);
    if (result.success) {
      await loadCategories();
    }
    return result;
  }

  Future<RepositoryResult<bool>> deleteCategory(int id) async {
    final result = await _repository.deleteCategory(id);
    if (result.success) {
      await loadCategories();
    }
    return result;
  }

  Future<RepositoryResult<bool>> isNameExists(
    String name, {
    int? excludeId,
  }) async {
    return await _repository.isNameExists(name, excludeId: excludeId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
