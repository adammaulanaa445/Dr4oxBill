/// State management untuk data transaksi.
library transaction_provider;

import 'package:flutter/foundation.dart';

import '../repositories/transaction_repository.dart';

class TransactionProvider extends ChangeNotifier {
  final _repository = TransactionRepository();
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get transactions =>
      List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTransactions({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.getAllTransactions(
        status: status,
        startDate: startDate,
        endDate: endDate,
        search: search,
      );
      if (result.success) {
        _transactions = result.data!;
      } else {
        _error = result.error;
      }
    } catch (e) {
      _error = 'Gagal memuat transaksi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TransactionRepositoryResult<Map<String, dynamic>?>>
      getTransactionDetail(
    int transactionId,
  ) async {
    return await _repository.getTransactionDetail(transactionId);
  }

  Future<TransactionRepositoryResult<bool>> cancelTransaction({
    required int transactionId,
    required String reason,
  }) async {
    final result = await _repository.cancelTransaction(
      transactionId: transactionId,
      reason: reason,
    );
    if (result.success) {
      await loadTransactions();
    }
    return result;
  }

  Future<TransactionRepositoryResult<bool>> isTransactionNumberExists(
    String transactionNumber,
  ) async {
    return await _repository.isTransactionNumberExists(transactionNumber);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
