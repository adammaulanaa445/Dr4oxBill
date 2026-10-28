/// Layar manajemen stok — penyesuaian, riwayat, dan peringatan stok menipis.
library stock_management_screen;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../models/product.dart';
import '../core/utils/money.dart';
import '../widgets/sidebar.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  final _adjustmentController = TextEditingController();
  final _reasonController = TextEditingController();
  Product? _selectedProduct;
  String _adjustmentType = 'in'; // 'in' atau 'out'

  @override
  void dispose() {
    _adjustmentController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Stok'),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          final products = provider.activeProducts;
          final lowStock = provider.lowStockProducts;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Peringatan stok menipis.
                if (lowStock.isNotEmpty) ...[
                  const Text(
                    'Peringatan: Stok Menipis',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: lowStock.length,
                      itemBuilder: (context, index) {
                        final p = lowStock[index];
                        return Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 12),
                          child: Card(
                            color: Colors.orange[50],
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Stok: ${p.stock} (min: ${p.minStock})',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Penyesuaian stok.
                const Text(
                  'Penyesuaian Stok',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1F4E79),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Product?>(
                  value: _selectedProduct,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Produk',
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  items: products
                      .where((p) => p.isGoods)
                      .map((p) => DropdownMenuItem<Product?>(
                            value: p,
                            child: Text('${p.name} (${p.sku})'),
                          ))
                      .toList(),
                  onChanged: (p) {
                    setState(() {
                      _selectedProduct = p;
                      _adjustmentController.clear();
                      _reasonController.clear();
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _adjustmentType,
                        decoration: const InputDecoration(
                          labelText: 'Jenis',
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'in', child: Text('Tambah Stok')),
                          DropdownMenuItem(
                              value: 'out', child: Text('Kurangi Stok')),
                          DropdownMenuItem(
                              value: 'adjustment', child: Text('Penyesuaian')),
                        ],
                        onChanged: (v) => setState(() => _adjustmentType = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _adjustmentController,
                        decoration: const InputDecoration(
                          labelText: 'Jumlah',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Alasan Perubahan *',
                  ),
                  maxLines: 2,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedProduct == null ||
                            _adjustmentController.text.trim().isEmpty
                        ? null
                        : () => _adjustStock(context, provider),
                    child: const Text('Simpan Perubahan Stok'),
                  ),
                ),
                const SizedBox(height: 32),

                // Daftar semua produk dan stok.
                const Text(
                  'Daftar Stok Produk',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1F4E79),
                  ),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final p = products[index];
                    return ListTile(
                      title: Text(p.name),
                      subtitle: Text('SKU: ${p.sku} • ${p.itemType}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            p.isGoods ? 'Stok: ${p.stock}' : 'Jasa',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (p.isLowStock)
                            const Text(
                              'MENIPIS',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _adjustStock(
    BuildContext context,
    ProductProvider provider,
  ) async {
    final product = _selectedProduct!;
    final quantity = int.tryParse(_adjustmentController.text) ?? 0;
    final reason = _reasonController.text.trim();

    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah harus lebih dari nol.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final currentStock = product.stock;
    int newStock;

    switch (_adjustmentType) {
      case 'in':
        newStock = currentStock + quantity;
        break;
      case 'out':
        newStock = currentStock - quantity;
        if (newStock < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stok tidak mencukupi.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        break;
      case 'adjustment':
        newStock = quantity;
        break;
      default:
        newStock = currentStock;
    }

    final success = await provider.updateStock(
      productId: product.id!,
      newStock: newStock,
      movementType: _adjustmentType,
      quantityChange: _adjustmentType == 'out'
          ? -quantity
          : (_adjustmentType == 'in' ? quantity : (quantity - currentStock)),
      stockBefore: currentStock,
      reason: reason,
    );

    if (!mounted) return;
    if (success.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stok berhasil diperbarui.'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _selectedProduct = null;
        _adjustmentController.clear();
        _reasonController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success.error ?? 'Gagal memperbarui stok.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
