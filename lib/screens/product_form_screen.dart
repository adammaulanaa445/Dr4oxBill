/// Layar form tambah/edit produk dan jasa.
library product_form_screen;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../core/utils/money.dart';
import '../services/file_service.dart';
import '../services/image_service.dart';
import '../widgets/sidebar.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product; // null untuk tambah baru.

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _itemType = 'goods';
  int? _selectedCategoryId;
  List<Category> _categories = [];
  String? _photoPath;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.product != null;
    if (_isEditing) {
      final p = widget.product!;
      _nameController.text = p.name;
      _skuController.text = p.sku;
      _priceController.text = p.sellingPrice.toString();
      _costController.text = p.costPrice.toString();
      _stockController.text = p.stock.toString();
      _minStockController.text = p.minStock.toString();
      _descriptionController.text = p.description ?? '';
      _itemType = p.itemType;
      _selectedCategoryId = p.categoryId;
      _photoPath = p.photoPath;
    } else {
      _minStockController.text = '0';
      _stockController.text = '0';
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    await context.read<CategoryProvider>().loadCategories();
    if (!mounted) return;
    setState(() {
      _categories = context.read<CategoryProvider>().categories;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      final validation = await ImageService.validateImage(
        File(result.files.single.path!),
      );
      if (!validation.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validation.error ?? 'Gambar tidak valid.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      setState(() {
        _photoPath = result.files.single.path!;
      });
    }
  }

  Future<void> _savePhotoToAppDir() async {
    if (_photoPath == null) return;
    final result = await FileService.saveProductPhoto(_photoPath!);
    if (result.success) {
      setState(() {
        _photoPath = result.path;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Gagal menyimpan foto.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _savePhotoToAppDir();

      final now = DateTime.now();
      final product = Product(
        id: widget.product?.id,
        name: _nameController.text.trim(),
        sku: _skuController.text.trim(),
        categoryId: _selectedCategoryId,
        itemType: _itemType,
        costPrice: int.tryParse(_costController.text.replaceAll('.', '')) ?? 0,
        sellingPrice:
            int.tryParse(_priceController.text.replaceAll('.', '')) ?? 0,
        stock: int.tryParse(_stockController.text) ?? 0,
        minStock: int.tryParse(_minStockController.text) ?? 0,
        photoPath: _photoPath,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isActive: true,
        createdAt: widget.product?.createdAt ?? now,
        updatedAt: now,
      );

      final provider = context.read<ProductProvider>();
      if (_isEditing) {
        final res = await provider.updateProduct(product);
        if (!res.success) {
          throw Exception(res.error ?? 'Gagal memperbarui produk.');
        }
      } else {
        final res = await provider.createProduct(product);
        if (!res.success) {
          throw Exception(res.error ?? 'Gagal menambah produk.');
        }
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan produk: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Produk' : 'Tambah Produk'),
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, child) {
          _categories = categoryProvider.categories;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Produk *',
                      prefixIcon: Icon(Icons.label),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Nama harus diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _skuController,
                    decoration: const InputDecoration(
                      labelText: 'SKU (Kode Produk) *',
                      prefixIcon: Icon(Icons.code),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'SKU harus diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Tanpa Kategori'),
                      ),
                      ..._categories.map((cat) {
                        return DropdownMenuItem<int?>(
                          value: cat.id,
                          child: Text(cat.name ?? ''),
                        );
                      }).toList(),
                    ],
                    onChanged: (v) => setState(() => _selectedCategoryId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _itemType,
                    decoration: const InputDecoration(
                      labelText: 'Jenis Item *',
                      prefixIcon: Icon(Icons.inventory),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'goods',
                        child: Text('Barang Fisik'),
                      ),
                      DropdownMenuItem(
                        value: 'service',
                        child: Text('Jasa'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _itemType = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Harga Jual (Rp) *',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final val = int.tryParse(v?.replaceAll('.', '') ?? '');
                      if (val == null || val < 0) {
                        return 'Harga jual tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _costController,
                    decoration: const InputDecoration(
                      labelText: 'Harga Beli / Modal (Rp)',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  if (_itemType == 'goods') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stok Awal *',
                        prefixIcon: Icon(Icons.inventory_2),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final val = int.tryParse(v ?? '');
                        if (val == null || val < 0) {
                          return 'Stok tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _minStockController,
                      decoration: const InputDecoration(
                        labelText: 'Batas Minimum Stok',
                        prefixIcon: Icon(Icons.warning),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Pilih Foto'),
                          onPressed: _pickPhoto,
                        ),
                      ),
                      if (_photoPath != null) ...[
                        const SizedBox(width: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          label: const Text('Hapus',
                              style: TextStyle(color: Colors.red)),
                          onPressed: () => setState(() => _photoPath = null),
                        ),
                      ],
                    ],
                  ),
                  if (_photoPath != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Foto: ${_photoPath!.split('/').last}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isEditing
                              ? 'Simpan Perubahan'
                              : 'Simpan Produk'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
