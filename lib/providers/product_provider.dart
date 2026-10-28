/// State management untuk data produk dan jasa.
library product_provider;

import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final _repository = ProductRepository();
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => List.unmodifiable(_products);
  List<Product> get activeProducts =>
      _products.where((p) => p.isActive).toList();
  List<Product> get lowStockProducts =>
      _products.where((p) => p.isLowStock && p.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.getAllProducts();
      if (result.success) {
        _products = result.data!;
      } else {
        _error = result.error;
      }
    } catch (e) {
      _error = 'Gagal memuat produk: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ProductRepositoryResult<int>> createProduct(Product product) async {
    final result = await _repository.createProduct(product);
    if (result.success) {
      await loadProducts();
    }
    return result;
  }

  Future<ProductRepositoryResult<bool>> updateProduct(Product product) async {
    final result = await _repository.updateProduct(product);
    if (result.success) {
      await loadProducts();
    }
    return result;
  }

  Future<ProductRepositoryResult<bool>> deactivateProduct(int id) async {
    final result = await _repository.deactivateProduct(id);
    if (result.success) {
      await loadProducts();
    }
    return result;
  }

  Future<ProductRepositoryResult<bool>> activateProduct(int id) async {
    final result = await _repository.activateProduct(id);
    if (result.success) {
      await loadProducts();
    }
    return result;
  }

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
    final result = await _repository.updateStock(
      productId: productId,
      newStock: newStock,
      movementType: movementType,
      quantityChange: quantityChange,
      stockBefore: stockBefore,
      reason: reason,
      referenceType: referenceType,
      referenceId: referenceId,
    );
    if (result.success) {
      await loadProducts();
    }
    return result;
  }

  Future<ProductRepositoryResult<List<Product>>> getLowStock() async {
    return await _repository.getLowStockProducts();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
