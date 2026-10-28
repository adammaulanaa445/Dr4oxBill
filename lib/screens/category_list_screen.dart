/// Layar daftar kategori produk dengan CRUD.
library category_list_screen;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/category_provider.dart';
import '../models/category.dart';
import '../widgets/sidebar.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final _nameController = TextEditingController();
  Category? _editingCategory;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showForm(context),
            tooltip: 'Tambah Kategori',
          ),
        ],
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          final categories = provider.categories;
          if (categories.isEmpty) {
            return const Center(child: Text('Belum ada kategori.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(cat.name ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () {
                          _nameController.text = cat.name ?? '';
                          _editingCategory = cat;
                          _showForm(context, category: cat);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.red, size: 18),
                        onPressed: () =>
                            _deleteCategory(context, provider, cat),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showForm(BuildContext context, {Category? category}) {
    _editingCategory = category;
    _nameController.text = category?.name ?? '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(category == null ? 'Tambah Kategori' : 'Edit Kategori'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Nama Kategori *'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => _saveCategory(context),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCategory(BuildContext context) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final provider = context.read<CategoryProvider>();
    final now = DateTime.now();

    if (_editingCategory != null) {
      final cat = _editingCategory!.copyWith(name: name, updatedAt: now);
      final res = await provider.updateCategory(cat);
      if (!mounted) return;
      if (!res.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.error ?? 'Gagal memperbarui kategori.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      final cat = Category(
        id: null,
        name: name,
        createdAt: now,
        updatedAt: now,
      );
      final res = await provider.createCategory(cat);
      if (!mounted) return;
      if (!res.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.error ?? 'Gagal menambah kategori.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
    _nameController.clear();
    _editingCategory = null;
  }

  Future<void> _deleteCategory(
    BuildContext context,
    CategoryProvider provider,
    Category category,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Hapus Kategori?'),
            content: Text('Anda yakin ingin menghapus "${category.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final result = await provider.deleteCategory(category.id!);
    if (!mounted) return;
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori berhasil dihapus.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Gagal menghapus kategori.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
