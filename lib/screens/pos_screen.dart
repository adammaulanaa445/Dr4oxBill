/// Layar Kasir (POS) — katalog produk, keranjang, dan pembayaran.
library pos_screen;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/setting_provider.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../core/utils/money.dart';
import '../core/constants/app_constants.dart';
import '../core/database/app_database.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedCategoryId;
  List<Category> _categories = [];
  bool _isProcessingPayment = false; // Cegah transaksi ganda.

  /// Ukuran kertas struk. Untuk printer biasa ganti ke PdfPageFormat.a5
  /// atau PdfPageFormat.a4. Untuk thermal 58mm ganti ke PdfPageFormat.roll57.
  PdfPageFormat get _receiptFormat => PdfPageFormat.roll80;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Kategori "Jasa" disembunyikan karena jasa ditambahkan manual.
  bool _isServiceCategory(Category c) =>
      (c.name ?? '').trim().toLowerCase() == 'jasa';

  Future<void> _loadData() async {
    await context.read<ProductProvider>().loadProducts();
    await context.read<CategoryProvider>().loadCategories();
    if (!mounted) return;
    setState(() {
      _categories = context
          .read<CategoryProvider>()
          .categories
          .where((c) => !_isServiceCategory(c))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Katalog hanya menampilkan barang fisik.
  List<Product> get _filteredProducts {
    final products = context.read<ProductProvider>().activeProducts;
    return products.where((product) {
      if (!product.isGoods) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!product.name.toLowerCase().contains(query) &&
            !product.sku.toLowerCase().contains(query)) {
          return false;
        }
      }
      if (_selectedCategoryId != null &&
          product.categoryId != _selectedCategoryId) {
        return false;
      }
      return true;
    }).toList();
  }

  void _addToCart(Product product) {
    if (product.isGoods && product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stok ${product.name} habis.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    context.read<CartProvider>().addProduct(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} ditambahkan ke keranjang.'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// Dialog tambah jasa manual (nama jasa dan harga).
  Future<void> _showAddServiceDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _ServiceDialog(),
    );
    if (result == null || !mounted) return;

    context.read<CartProvider>().addManualService(
          name: result['name'] as String,
          price: result['price'] as int,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${result['name']} ditambahkan ke keranjang.'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _openCheckout() {
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang kosong.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final validation = cart.validate();
    if (validation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validation),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _showPaymentDialog();
  }

  void _showPaymentDialog() {
    final cart = context.read<CartProvider>();
    final cashController = TextEditingController(
      text: cart.cashReceived.toString(),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final change = cart.change;

            return AlertDialog(
              title: const Text('Pembayaran'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total: ${formatRupiah(cart.total)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cashController,
                      decoration: const InputDecoration(
                        labelText: 'Uang Diterima',
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final parsed =
                            int.tryParse(value.replaceAll('.', '')) ?? 0;
                        cart.setCashReceived(parsed);
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kembalian:'),
                        Flexible(
                          child: Text(
                            change != null
                                ? formatRupiah(change)
                                : 'Uang kurang',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  change != null ? Colors.green : Colors.red,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: _isProcessingPayment || change == null
                      ? null
                      : () => _processPayment(cashController),
                  child: const Text('Bayar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _processPayment(TextEditingController cashController) async {
    final cart = context.read<CartProvider>();

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      final now = DateTime.now();
      final transactionNumber =
          'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.millisecondsSinceEpoch}';

      final cashReceived = int.tryParse(
            cashController.text.replaceAll('.', ''),
          ) ??
          0;

      // Simpan nilai sebelum keranjang dikosongkan (dipakai untuk struk).
      final subtotal = cart.itemSubtotal;
      final discount = cart.discount;
      final total = cart.total;
      final changeAmount = cart.change ?? 0;
      final paymentMethod = cart.paymentMethod;

      final items = cart.toTransactionItems();
      final stockUpdates = cart.toStockUpdates();

      final db = await AppDatabase().database;

      // Operasi transaksi atomik.
      await db.transaction((txn) async {
        // 1. Simpan transaksi utama.
        final transactionId = await txn.insert('transactions', {
          'transaction_number': transactionNumber,
          'transaction_date': now.toIso8601String(),
          'subtotal': subtotal,
          'discount': discount,
          'total': total,
          'cash_received': cashReceived,
          'change_amount': changeAmount,
          'payment_method': paymentMethod,
          'status': 'completed',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });

        // 2. Simpan detail semua item (jasa manual: product_id null).
        for (final item in items) {
          await txn.insert('transaction_items', {
            'transaction_id': transactionId,
            'product_id': item['product_id'],
            'sku': item['sku'],
            'name': item['name'],
            'item_type': item['item_type'],
            'quantity': item['quantity'],
            'unit_price': item['unit_price'],
            'subtotal': item['subtotal'],
            'discount': item['discount'] ?? 0,
          });
        }

        // 3. Kurangi stok dan catat pergerakan stok (hanya barang fisik).
        for (final update in stockUpdates) {
          await txn.update(
            'products',
            {
              'stock': update['new_stock'],
              'updated_at': now.toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [update['product_id']],
          );

          await txn.insert('stock_movements', {
            'product_id': update['product_id'],
            'movement_type': 'sale',
            'quantity_change': -update['quantity_sold'],
            'stock_before': update['stock_before'],
            'stock_after': update['new_stock'],
            'reason': 'Penjualan transaksi $transactionNumber',
            'reference_type': 'transaction',
            'reference_id': transactionId,
            'created_at': now.toIso8601String(),
          });
        }
      });

      // Kosongkan keranjang hanya setelah commit berhasil.
      cart.clear();

      if (!mounted) return;
      Navigator.pop(context);

      // Muat ulang data.
      await context.read<ProductProvider>().loadProducts();
      await context.read<SettingProvider>().loadSettings();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil disimpan.'),
          backgroundColor: Colors.green,
        ),
      );

      // Tampilkan pratinjau struk (bisa dicetak atau disimpan sebagai PDF).
      await _showReceipt(
        transactionNumber: transactionNumber,
        transactionDate: now,
        subtotal: subtotal,
        discount: discount,
        total: total,
        cashReceived: cashReceived,
        changeAmount: changeAmount,
        paymentMethod: paymentMethod,
        items: items,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan transaksi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Struk
  // ---------------------------------------------------------------------------

  /// Buat struk lalu tampilkan pratinjau/dialog cetak.
  /// Gagal membuat struk tidak membatalkan transaksi yang sudah tersimpan.
  Future<void> _showReceipt({
    required String transactionNumber,
    required DateTime transactionDate,
    required int subtotal,
    required int discount,
    required int total,
    required int cashReceived,
    required int changeAmount,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final settingProvider = context.read<SettingProvider>();
      final businessName = settingProvider.get('business_name',
          defaultValue: defaultBusinessName);
      final businessAddress =
          settingProvider.get('business_address', defaultValue: '');
      final businessPhone =
          settingProvider.get('business_phone', defaultValue: '');
      final thankYouMessage = settingProvider.get('thank_you_message',
          defaultValue: 'Terima kasih telah berkunjung ke Dr4ox Motor');

      final bytes = await _buildReceiptPdf(
        businessName: businessName,
        businessAddress: businessAddress,
        businessPhone: businessPhone,
        thankYouMessage: thankYouMessage,
        transactionNumber: transactionNumber,
        transactionDate: transactionDate,
        subtotal: subtotal,
        discount: discount,
        total: total,
        cashReceived: cashReceived,
        changeAmount: changeAmount,
        paymentMethod: paymentMethod,
        items: items,
      );

      await Printing.layoutPdf(
        name: transactionNumber,
        format: _receiptFormat,
        onLayout: (_) async => bytes,
      );
    } catch (e, st) {
      debugPrint('Struk ERROR: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaksi tersimpan, tetapi struk gagal dibuat: $e'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  String _formatReceiptDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  String _paymentLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Tunai';
      default:
        return method;
    }
  }

  Future<Uint8List> _buildReceiptPdf({
    required String businessName,
    required String businessAddress,
    required String businessPhone,
    required String thankYouMessage,
    required String transactionNumber,
    required DateTime transactionDate,
    required int subtotal,
    required int discount,
    required int total,
    required int cashReceived,
    required int changeAmount,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    final doc = pw.Document();

    pw.Widget row(String left, String right, {bool bold = false}) {
      final style = pw.TextStyle(
        fontSize: 9,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      );
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(left, style: style),
          pw.Text(right, style: style),
        ],
      );
    }

    pw.Widget divider() => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Divider(
            height: 1,
            thickness: 0.5,
            borderStyle: pw.BorderStyle.dashed,
          ),
        );

    doc.addPage(
      pw.Page(
        pageFormat: _receiptFormat,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                businessName,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (businessAddress.trim().isNotEmpty)
                pw.Text(
                  businessAddress,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              if (businessPhone.trim().isNotEmpty)
                pw.Text(
                  businessPhone,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              divider(),
              row('No', transactionNumber),
              row('Tanggal', _formatReceiptDate(transactionDate)),
              row('Bayar', _paymentLabel(paymentMethod)),
              divider(),
              ...items.map((item) {
                final qty = item['quantity'] as int;
                final unit = item['unit_price'] as int;
                final sub = item['subtotal'] as int;
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        item['name'] as String,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      row('$qty x ${formatRupiah(unit)}', formatRupiah(sub)),
                    ],
                  ),
                );
              }),
              divider(),
              row('Subtotal', formatRupiah(subtotal)),
              if (discount > 0) row('Diskon', '-${formatRupiah(discount)}'),
              row('TOTAL', formatRupiah(total), bold: true),
              row('Uang diterima', formatRupiah(cashReceived)),
              row('Kembalian', formatRupiah(changeAmount)),
              divider(),
              pw.SizedBox(height: 4),
              pw.Text(
                thankYouMessage,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    context.watch<ProductProvider>(); // Rebuild saat stok/produk berubah.

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Kasir'),
            actions: [
              if (isWide && cart.items.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: _isProcessingPayment ? null : _openCheckout,
                  tooltip: 'Checkout',
                ),
            ],
          ),
          body: isWide
              ? Row(
                  children: [
                    Expanded(child: _buildCatalog()),
                    SizedBox(
                      width: 360,
                      child: _buildCartPanel(cart),
                    ),
                  ],
                )
              : _buildCatalog(),
          bottomNavigationBar: isWide ? null : _buildCartBar(cart),
        );
      },
    );
  }

  /// Katalog produk: pencarian, filter kategori, tombol jasa, dan grid produk.
  Widget _buildCatalog() {
    final products = _filteredProducts;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari nama / SKU',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int?>(
                      value: _selectedCategoryId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Semua', overflow: TextOverflow.ellipsis),
                        ),
                        ..._categories.map((cat) {
                          return DropdownMenuItem<int?>(
                            value: cat.id,
                            child: Text(
                              cat.name ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.build),
                  label: const Text('Tambah Jasa'),
                  onPressed: _isProcessingPayment ? null : _showAddServiceDialog,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: products.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Produk tidak ditemukan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisExtent: 240,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(products[index]);
                  },
                ),
        ),
      ],
    );
  }

  /// Bar ringkas keranjang di bawah layar (khusus HP).
  Widget _buildCartBar(CartProvider cart) {
    final count = cart.items.fold<int>(0, (sum, item) => sum + item.quantity);

    return SafeArea(
      top: false,
      child: Material(
        color: Colors.white,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart, color: Color(0xFF1F4E79)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count item',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatRupiah(cart.total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1F4E79),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _showCartSheet,
                child: const Text('Lihat Keranjang'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Keranjang sebagai bottom sheet (khusus HP).
  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (sheetContext) {
        final height = MediaQuery.of(sheetContext).size.height * 0.85;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SizedBox(
            height: height,
            child: Consumer<CartProvider>(
              builder: (context, cart, _) =>
                  _buildCartPanel(cart, sheetContext: sheetContext),
            ),
          ),
        );
      },
    );
  }

  /// Panel keranjang: dipakai di sisi kanan (layar lebar) dan di bottom sheet.
  Widget _buildCartPanel(CartProvider cart, {BuildContext? sheetContext}) {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF1F4E79),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart, color: Colors.white),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Keranjang',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (sheetContext != null)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(sheetContext),
                        tooltip: 'Tutup',
                      ),
                  ],
                ),
              ),
              Expanded(
                child: cart.items.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.remove_shopping_cart,
                                size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'Keranjang kosong',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: cart.items.length,
                        itemBuilder: (context, index) {
                          return _buildCartItem(cart.items[index], cart);
                        },
                      ),
              ),
              ConstrainedBox(
                constraints:
                    BoxConstraints(maxHeight: constraints.maxHeight * 0.6),
                child: Container(
                  color: Colors.white,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSummaryRow(
                            'Subtotal', formatRupiah(cart.itemSubtotal), false),
                        _buildSummaryRow(
                            'Diskon', '-${formatRupiah(cart.discount)}', false),
                        const Divider(),
                        _buildSummaryRow(
                            'Total', formatRupiah(cart.total), true),
                        const SizedBox(height: 12),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Uang Diterima',
                            prefixText: 'Rp ',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final parsed = int.tryParse(
                              value.replaceAll('.', ''),
                            );
                            if (parsed != null) {
                              cart.setCashReceived(parsed);
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kembalian: ${cart.change != null ? formatRupiah(cart.change!) : 'Uang kurang'}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                cart.change != null ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: cart.items.isEmpty ||
                                    _isProcessingPayment ||
                                    cart.change == null
                                ? null
                                : () {
                                    if (sheetContext != null) {
                                      Navigator.pop(sheetContext);
                                    }
                                    _openCheckout();
                                  },
                            child: const Text('Bayar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final isLowStock = product.isLowStock;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.grey[200],
              child: product.photoPath != null && product.photoPath!.isNotEmpty
                  ? Image.file(
                      File(product.photoPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                    )
                  : const Icon(Icons.image_not_supported, size: 40),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  formatRupiah(product.sellingPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F4E79),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (product.stock == 0 && product.isGoods)
                  const Text(
                    'Habis',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else if (isLowStock)
                  Text(
                    'Stok menipis (${product.stock})',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (product.stock <= 0 && product.isGoods) ||
                            _isProcessingPayment
                        ? null
                        : () => _addToCart(product),
                    child: const Text('Pilih'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, CartProvider cart) {
    final index = cart.items.indexOf(item);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  color: Colors.grey[200],
                  child: item.product.isService
                      ? const Icon(Icons.build, size: 20)
                      : (item.product.photoPath != null &&
                              item.product.photoPath!.isNotEmpty
                          ? Image.file(
                              File(item.product.photoPath!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image, size: 20),
                            )
                          : const Icon(Icons.image, size: 20)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${formatRupiah(item.product.sellingPrice)} x ${item.quantity}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () => cart.removeItem(index),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 22),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () => cart.setQuantity(index, item.quantity - 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    item.quantity.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 22),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () => cart.setQuantity(index, item.quantity + 1),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatRupiah(item.subtotal),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? const Color(0xFF1F4E79) : Colors.grey[700],
          ),
        ),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? const Color(0xFF1F4E79) : Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

/// Dialog input jasa manual: nama jasa dan harga.
class _ServiceDialog extends StatefulWidget {
  const _ServiceDialog();

  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final price =
        int.parse(_priceController.text.replaceAll('.', '').trim());
    Navigator.pop(context, {
      'name': _nameController.text.trim(),
      'price': price,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Jasa'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nama Jasa Perbaikan *',
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Nama jasa harus diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Harga (Rp) *',
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                onFieldSubmitted: (_) => _submit(),
                validator: (v) {
                  final val =
                      int.tryParse((v ?? '').replaceAll('.', '').trim());
                  if (val == null || val <= 0) {
                    return 'Harga tidak valid';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Tambah'),
        ),
      ],
    );
  }
}