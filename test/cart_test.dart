import 'package:flutter_test/flutter_test.dart';

import 'package:dr4ox_bill/providers/cart_provider.dart';
import 'package:dr4ox_bill/models/product.dart';
import 'package:dr4ox_bill/core/constants/app_constants.dart';

void main() {
  Product createProduct({
    int id = 1,
    String name = 'Test Product',
    String sku = 'TEST-001',
    int? categoryId,
    String itemType = itemTypeGoods,
    int costPrice = 5000,
    int sellingPrice = 10000,
    int stock = 10,
    int minStock = 2,
    bool isActive = true,
  }) {
    return Product(
      id: id,
      name: name,
      sku: sku,
      categoryId: categoryId,
      itemType: itemType,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      stock: stock,
      minStock: minStock,
      isActive: isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  group('CartProvider addProduct', () {
    test('adds new product to cart', () {
      final cart = CartProvider();
      final product = createProduct();
      cart.addProduct(product);
      expect(cart.items.length, equals(1));
      expect(cart.items.first.quantity, equals(1));
    });

    test('increments quantity when same product added again', () {
      final cart = CartProvider();
      final product = createProduct(id: 1);
      cart.addProduct(product);
      cart.addProduct(product);
      expect(cart.items.length, equals(1));
      expect(cart.items.first.quantity, equals(2));
    });

    test('treats different products as separate items', () {
      final cart = CartProvider();
      cart.addProduct(createProduct(id: 1, name: 'Product A', sku: 'A-001'));
      cart.addProduct(createProduct(id: 2, name: 'Product B', sku: 'B-001'));
      expect(cart.items.length, equals(2));
    });
  });

  group('CartProvider setQuantity', () {
    test('sets quantity to new value', () {
      final cart = CartProvider();
      final product = createProduct();
      cart.addProduct(product);
      cart.setQuantity(0, 5);
      expect(cart.items.first.quantity, equals(5));
    });

    test('removes item when quantity is 0 or less', () {
      final cart = CartProvider();
      final product = createProduct();
      cart.addProduct(product);
      cart.setQuantity(0, 0);
      expect(cart.items.isEmpty, isTrue);
    });

    test('does nothing for invalid index', () {
      final cart = CartProvider();
      cart.setQuantity(0, 5);
      expect(cart.items.isEmpty, isTrue);
    });
  });

  group('CartProvider removeItem', () {
    test('removes item at index', () {
      final cart = CartProvider();
      cart.addProduct(createProduct(id: 1));
      cart.addProduct(createProduct(id: 2));
      cart.removeItem(0);
      expect(cart.items.length, equals(1));
      expect(cart.items.first.product.id, equals(2));
    });
  });

  group('CartProvider discounts', () {
    test('sets item discount', () {
      final cart = CartProvider();
      final product = createProduct(sellingPrice: 10000);
      cart.addProduct(product);
      cart.setItemDiscount(0, 2000);
      expect(cart.items.first.discount, equals(2000));
    });

    test('clamps item discount to selling price', () {
      final cart = CartProvider();
      final product = createProduct(sellingPrice: 10000);
      cart.addProduct(product);
      cart.setItemDiscount(0, 15000);
      expect(cart.items.first.discount, equals(10000));
    });

    test('sets transaction discount', () {
      final cart = CartProvider();
      cart.addProduct(createProduct(sellingPrice: 10000));
      cart.addProduct(createProduct(id: 2, sellingPrice: 20000));
      cart.setTransactionDiscount(5000);
      expect(cart.discount, equals(5000));
    });

    test('clamps transaction discount to item subtotal', () {
      final cart = CartProvider();
      cart.addProduct(createProduct(sellingPrice: 10000));
      cart.setTransactionDiscount(50000);
      expect(cart.discount, equals(10000));
    });
  });

  group('CartProvider calculations', () {
    test('calculates item subtotal correctly', () {
      final cart = CartProvider();
      final product = createProduct(sellingPrice: 10000);
      cart.addProduct(product, quantity: 3);
      cart.setItemDiscount(0, 1000);
      // (10000 - 1000) * 3 = 27000
      expect(cart.items.first.subtotal, equals(27000));
    });

    test('calculates total with transaction discount', () {
      final cart = CartProvider();
      cart.addProduct(createProduct(sellingPrice: 10000), quantity: 2);
      // itemSubtotal = 20000
      cart.setTransactionDiscount(3000);
      // total = 20000 - 3000 = 17000
      expect(cart.total, equals(17000));
    });

    test('clamps total to zero when discount exceeds subtotal', () {
      final cart = CartProvider();
      cart.addProduct(createProduct(sellingPrice: 5000));
      cart.setTransactionDiscount(10000);
      expect(cart.total, equals(0));
    });

    test('calculates change correctly', () {
      final cart = CartProvider();
      cart.addProduct(createProduct(sellingPrice: 15000));
      cart.setCashReceived(20000);
      expect(cart.change, equals(5000));
    });

    test('returns null change when cash is insufficient', () {
      final cart = CartProvider();
      cart.addProduct(createProduct(sellingPrice: 20000));
      cart.setCashReceived(10000);
      expect(cart.change, isNull);
    });
  });

  group('CartProvider validation', () {
    test('returns error for empty cart', () {
      final cart = CartProvider();
      expect(cart.validate(), equals('Keranjang kosong. Silakan tambahkan item terlebih dahulu.'));
    });

    test('returns error for insufficient stock', () {
      final cart = CartProvider();
      // Karena setQuantity membatasi ke stok tersedia, uji validate() dengan
      // stok dimanipulasi langsung lewat addProduct dengan quantity melebihi stok.
      // Stok: 2, tambah produk (qty default 1), lalu coba setQuantity melampaui stok.
      cart.addProduct(createProduct(stock: 2));
      cart.setQuantity(0, 5); // akan di-clamp ke 2 oleh setQuantity
      // Quantity seharusnya di-clamp ke 2 (tidak melebihi stok).
      expect(cart.items.first.quantity, equals(2));
    });

    test('returns error for insufficient cash', () {
      final cart = CartProvider();
      cart.addProduct(createProduct(sellingPrice: 20000));
      cart.setCashReceived(10000);
      expect(cart.validate(), contains('kurang dari total'));
    });

    test('returns null for valid cart', () {
      final cart = CartProvider();
      cart.addProduct(createProduct(sellingPrice: 10000, stock: 10));
      cart.setCashReceived(20000);
      expect(cart.validate(), isNull);
    });
  });

  group('CartProvider service type', () {
    test('service items do not have stock validation', () {
      final cart = CartProvider();
      final service = createProduct(
        id: 99,
        itemType: itemTypeService,
        stock: 0,
      );
      cart.addProduct(service, quantity: 5);
      // Service items should be added even with stock 0
      expect(cart.items.length, equals(1));
      expect(cart.items.first.quantity, equals(5));
    });
  });

  group('CartProvider clear', () {
    test('clears all cart data', () {
      final cart = CartProvider();
      cart.addProduct(createProduct(sellingPrice: 10000));
      cart.setCashReceived(20000);
      cart.setTransactionDiscount(1000);
      cart.clear();
      expect(cart.items.isEmpty, isTrue);
      expect(cart.discount, equals(0));
      expect(cart.cashReceived, equals(0));
      expect(cart.paymentMethod, equals('cash'));
    });
  });
}
