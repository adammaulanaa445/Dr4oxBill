/// Layar form tambah/edit kategori (digunakan oleh routing).
library category_form_screen;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/category_provider.dart';
import '../models/category.dart';
import '../core/constants/app_constants.dart';

class CategoryFormScreen extends StatefulWidget {
  final Category? category;

  const CategoryFormScreen({super.key, this.category});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final provider = context.read<CategoryProvider>();
      final now = DateTime.now();

      if (widget.category != null) {
        final cat = widget.category!.copyWith(
          name: _nameController.text.trim(),
          updatedAt: now,
        );
        final res = await provider.updateCategory(cat);
        if (!res.success) {
          throw Exception(res.error ?? 'Gagal memperbarui kategori.');
        }
      } else {
        final cat = Category(
          id: null,
          name: _nameController.text.trim(),
          createdAt: now,
          updatedAt: now,
        );
        final res = await provider.createCategory(cat);
        if (!res.success) {
          throw Exception(res.error ?? 'Gagal menambah kategori.');
        }
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan kategori: $e'),
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
        title:
            Text(widget.category == null ? 'Tambah Kategori' : 'Edit Kategori'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kategori *',
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nama harus diisi' : null,
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
                      : const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
