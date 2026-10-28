/// State management untuk keranjang belanja di layanan kasir (POS).
library cart_provider;

import 'package:flutter/foundation.dart';

import '../models/product.dart';

/// Item dalam keranjang belanja.
class CartItem {
  final Product product;
  int quantity;
  final int discount; // diskon per item dalam Rupiah

  CartItem({
    required this.product,
    this.quantity = 1,
    this.discount = 0,
  });

  /// Subtotal item ini (harga satuan - diskon) * kuantitas.
  int get subtotal {
    final unitAfterDiscount = (product.sellingPrice - discount).clamp(
      0,
      product.sellingPrice,
    );
    return unitAfterDiscount * quantity;
  }

  /// Salin item dengan kuantitas baru.
  CartItem copyWith({int? quantity, int? discount}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
    );
  }
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  int _discount = 0; // diskon transaksi secara keseluruhan dalam Rupiah
  int _cashReceived = 0;
  String _paymentMethod = 'cash';

  /// Daftar item keranjang (salinan).
  List<CartItem> get items => List.unmodifiable(_items);

  /// Diskon transaksi secara keseluruhan.
  int get discount => _discount;

  /// Uang yang diterima dari pembeli.
  int get cashReceived => _cashReceived;

  /// Metode pembayaran yang dipilih.
  String get paymentMethod => _paymentMethod;

  /// Subtotal semua item sebelum diskon.
  int get itemSubtotal {
    return _items.fold(0, (sum, item) => sum + item.subtotal);
  }

  /// Total setelah diskon transaksi.
  int get total {
    return (itemSubtotal - _discount).clamp(0, itemSubtotal);
  }

  /// Kembalian yang harus diberikan.
  int? get change {
    if (_cashReceived < total) {
      return null;
    }
    return _cashReceived - total;
  }

  /// Jumlah item berbeda dalam keranjang.
  int get itemCount => _items.length;

  /// Total kuantitas semua item.
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Apakah keranjang kosong.
  bool get isEmpty => _items.isEmpty;

  /// Tambah produk ke keranjang atau tambah kuantitas jika sudah ada.
  void addProduct(Product product, {int quantity = 1}) {
    final existingIndex =
        _items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + quantity,
      );
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  /// Hapus item dari keranjang berdasarkan indeks.
  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  /// Set kuantitas item. Jika 0 atau kurang, item dihapus.
  void setQuantity(int index, int quantity) {
    if (index < 0 || index >= _items.length) return;
    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      final item = _items[index];
      // Batasi ke stok tersedia untuk barang fisik.
      final maxQty =
          item.product.isGoods ? item.product.stock : quantity;
      _items[index] = item.copyWith(quantity: quantity.clamp(1, maxQty > 0 ? maxQty : 1));
    }
    notifyListeners();
  }

  /// Set diskon per item.
  void setItemDiscount(int index, int discount) {
    if (index < 0 || index >= _items.length) return;
    final item = _items[index];
    final maxDiscount = item.product.sellingPrice;
    _items[index] = item.copyWith(discount: discount.clamp(0, maxDiscount));
    notifyListeners();
  }

  /// Set diskon transaksi secara keseluruhan.
  void setTransactionDiscount(int discount) {
    _discount = discount.clamp(0, itemSubtotal);
    notifyListeners();
  }

  /// Set uang yang diterima.
  void setCashReceived(int cashReceived) {
    _cashReceived = cashReceived < 0 ? 0 : cashReceived;
    notifyListeners();
  }

  /// Set metode pembayaran.
  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  /// Kosongkan keranjang.
  void clear() {
    _items.clear();
    _discount = 0;
    _cashReceived = 0;
    _paymentMethod = 'cash';
    notifyListeners();
  }

  /// Konversi keranjang ke daftar data item transaksi untuk disimpan.
  List<Map<String, dynamic>> toTransactionItems() {
    return _items.map((item) {
      return {
        'product_id': item.product.id,
        'sku': item.product.sku,
        'name': item.product.name,
        'item_type': item.product.itemType,
        'quantity': item.quantity,
        'unit_price': item.product.sellingPrice,
        'subtotal': item.subtotal,
        'discount': item.discount,
      };
    }).toList();
  }

  /// Konversi keranjang ke daftar pembaruan stok untuk transaksi.
  List<Map<String, dynamic>> toStockUpdates() {
    return _items.where((item) => item.product.isGoods).map((item) {
      return {
        'product_id': item.product.id,
        'quantity_sold': item.quantity,
        'stock_before': item.product.stock,
        'new_stock': item.product.stock - item.quantity,
      };
    }).toList();
  }

  /// Validasi apakah keranjang siap untuk checkout.
  /// Mengembalikan pesan error jika tidak valid, null jika valid.
  String? validate({bool validateCash = true}) {
    if (_items.isEmpty) {
      return 'Keranjang kosong. Silakan tambahkan item terlebih dahulu.';
    }

    for (final item in _items) {
      if (item.quantity <= 0) {
        return 'Kuantitas untuk ${item.product.name} harus lebih dari nol.';
      }
      if (item.product.isGoods && item.quantity > item.product.stock) {
        return 'Stok ${item.product.name} tidak mencukupi (tersedia: ${item.product.stock}).';
      }
    }

    if (validateCash && _cashReceived < total) {
      return 'Uang diterima kurang dari total yang harus dibayar.';
    }

    return null;
  }
}
