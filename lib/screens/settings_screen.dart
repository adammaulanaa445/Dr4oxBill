/// Layar pengaturan aplikasi dan profil bengkel.
library settings_screen;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/setting_provider.dart';
import '../core/constants/app_constants.dart';
import '../widgets/sidebar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _thankYouController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await context.read<SettingProvider>().loadSettings();
    if (!mounted) return;
    final provider = context.read<SettingProvider>();
    _businessNameController.text =
        provider.get('business_name', defaultValue: defaultBusinessName);
    _businessAddressController.text =
        provider.get('business_address', defaultValue: '');
    _businessPhoneController.text =
        provider.get('business_phone', defaultValue: '');
    _thankYouController.text = provider.get('thank_you_message',
        defaultValue: 'Terima kasih telah berkunjung ke Dr4ox Motor');
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final provider = context.read<SettingProvider>();

    await provider.saveSetting(
        'business_name', _businessNameController.text.trim());
    await provider.saveSetting(
        'business_address', _businessAddressController.text.trim());
    await provider.saveSetting(
        'business_phone', _businessPhoneController.text.trim());
    await provider.saveSetting(
        'thank_you_message', _thankYouController.text.trim());

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pengaturan disimpan.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    _thankYouController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profil Bengkel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F4E79),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _businessNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Bengkel',
                hintText: defaultBusinessName,
                prefixIcon: Icon(Icons.store),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _businessAddressController,
              decoration: const InputDecoration(
                labelText: 'Alamat',
                hintText: 'Contoh: Jl. Raya No. 123',
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _businessPhoneController,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon',
                hintText: 'Contoh: 08123456789',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            const Text(
              'Preferensi Struk',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F4E79),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _thankYouController,
              decoration: const InputDecoration(
                labelText: 'Pesan Terima Kasih',
                hintText: 'Terima kasih telah berkunjung',
                prefixIcon: Icon(Icons.message),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            const Text(
              'Informasi Aplikasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F4E79),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nama Aplikasi:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(appName),
                    const SizedBox(height: 12),
                    const Text('Versi:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('1.0.0'),
                    const SizedBox(height: 12),
                    const Text('Database:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('SQLite lokal (Windows %APPDATA%)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveSettings,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan Pengaturan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
