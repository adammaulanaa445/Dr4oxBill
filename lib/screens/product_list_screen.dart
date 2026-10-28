/// Layar daftar produk dan jasa dengan CRUD.
library product_list_screen;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../models/product.dart';
import '../core/utils/money.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk & Jasa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/product_form');
              if (result == true && context.mounted) {
                context.read<ProductProvider>().loadProducts();
              }
            },
            tooltip: 'Tambah Produk',
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          final products = productProvider.products;

          final filtered = products.where((p) {
            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              return p.name.toLowerCase().contains(q) ||
                  p.sku.toLowerCase().contains(q);
            }
            return true;
          }).toList();

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau SKU...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('Produk tidak ditemukan.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final product = filtered[index];
                          return _buildProductRow(
                              context, product, productProvider);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductRow(
    BuildContext context,
    Product product,
    ProductProvider provider,
  ) {
    final isLowStock = product.isLowStock;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          color: Colors.grey[200],
          child: product.photoPath != null && product.photoPath!.isNotEmpty
              ? Image.file(
                  File(product.photoPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image, size: 20),
                )
              : const Icon(Icons.image, size: 20),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${product.sku} • ${product.itemType} • ${formatRupiah(product.sellingPrice)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isLowStock)
              const Text(
                'Stok Menipis',
                style: TextStyle(color: Colors.orange, fontSize: 10),
              ),
            Text(
              product.isActive ? 'Aktif' : 'Nonaktif',
              style: TextStyle(
                color: product.isActive ? Colors.green : Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      '/product_form',
                      arguments: product,
                    );
                    if (result == true && context.mounted) {
                      context.read<ProductProvider>().loadProducts();
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    product.isActive ? Icons.block : Icons.check_circle,
                    color: product.isActive ? Colors.orange : Colors.green,
                    size: 18,
                  ),
                  onPressed: () => _toggleActive(context, product, provider),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActive(
    BuildContext context,
    Product product,
    ProductProvider provider,
  ) async {
    final action = product.isActive ? 'nonaktifkan' : 'aktifkan';
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(
              '${action[0].toUpperCase()}${action.substring(1)} Produk?',
            ),
            content: Text('Anda yakin ingin ${action} "${product.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(product.isActive ? 'Nonaktifkan' : 'Aktifkan'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    if (product.isActive) {
      await provider.deactivateProduct(product.id!);
    } else {
      await provider.activateProduct(product.id!);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Produk berhasil di${action}.'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
