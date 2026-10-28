/// Layar laporan penjualan dan stok dengan filter tanggal dan ekspor CSV.
library reports_screen;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../providers/transaction_provider.dart';
import '../core/utils/money.dart';
import '../core/utils/date_utils.dart';
import '../services/csv_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  String? _exportStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TransactionProvider>().loadTransactions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final transactions = provider.transactions;

          // Filter tanggal.
          var filtered = transactions;
          if (_startDate != null) {
            filtered = filtered.where((t) {
              final date = parseDbDateTime(t['transaction_date']);
              return !date.isBefore(startOfDay(_startDate!));
            }).toList();
          }
          if (_endDate != null) {
            filtered = filtered.where((t) {
              final date = parseDbDateTime(t['transaction_date']);
              return !date.isAfter(endOfDay(_endDate!));
            }).toList();
          }

          // Hanya transaksi selesai untuk omzet.
          final completed = filtered
              .where(
                (t) => (t['status'] as String) == 'completed',
              )
              .toList();

          final totalRevenue = completed.fold<int>(
            0,
            (sum, t) => sum + (t['total'] as int),
          );
          final totalTransactions = completed.length;
          final totalCancelled = filtered
              .where(
                (t) => (t['status'] as String) == 'cancelled',
              )
              .length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter tanggal.
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          label: 'Dari',
                          date: _startDate,
                          onTap: () => _pickDate(context, true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDateField(
                          label: 'Sampai',
                          date: _endDate,
                          onTap: () => _pickDate(context, false),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Ringkasan laporan.
                const Text(
                  'Ringkasan Penjualan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F4E79),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSummary(
                  revenue: totalRevenue,
                  count: totalTransactions,
                  cancelled: totalCancelled,
                ),
                const SizedBox(height: 24),

                // Daftar transaksi dalam laporan.
                const Text(
                  'Detail Transaksi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F4E79),
                  ),
                ),
                const SizedBox(height: 8),
                if (filtered.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Tidak ada data transaksi.'),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final t = filtered[index];
                      final isCancelled =
                          (t['status'] as String) == 'cancelled';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          t['transaction_number'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          formatDateTime(
                              parseDbDateTime(t['transaction_date'])),
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatRupiah(t['total'] ?? 0),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCancelled ? Colors.grey : Colors.black,
                              ),
                            ),
                            Text(
                              isCancelled ? 'Dibatalkan' : 'Selesai',
                              style: TextStyle(
                                fontSize: 11,
                                color: isCancelled ? Colors.grey : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),

                // Ekspor CSV.
                const Text(
                  'Ekspor Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F4E79),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.file_download),
                    label: const Text('Ekspor ke CSV'),
                    onPressed: _isLoading ? null : () => _exportCsv(filtered),
                  ),
                ),
                if (_exportStatus != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _exportStatus!,
                      style: TextStyle(
                        color: _exportStatus!.contains('berhasil')
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today, size: 20),
        ),
        child: Text(
          date != null ? formatShortDate(date) : 'Pilih',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// Ringkasan: layar lebar 3 kartu sejajar, HP Omzet penuh lalu 2 kartu.
  Widget _buildSummary({
    required int revenue,
    required int count,
    required int cancelled,
  }) {
    final omzet = _buildReportCard(
        'Omzet', formatRupiah(revenue), Icons.monetization_on, Colors.green);
    final transaksi = _buildReportCard(
        'Transaksi', count.toString(), Icons.receipt, Colors.blue);
    final dibatalkan = _buildReportCard(
        'Dibatalkan', cancelled.toString(), Icons.cancel, Colors.red);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return Row(
            children: [
              Expanded(child: omzet),
              const SizedBox(width: 12),
              Expanded(child: transaksi),
              const SizedBox(width: 12),
              Expanded(child: dibatalkan),
            ],
          );
        }
        return Column(
          children: [
            SizedBox(width: double.infinity, child: omzet),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: transaksi),
                const SizedBox(width: 12),
                Expanded(child: dibatalkan),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _exportCsv(List<Map<String, dynamic>> transactions) async {
    setState(() {
      _isLoading = true;
      _exportStatus = null;
    });

    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan File CSV',
        fileName: 'laporan_${DateTime.now().millisecondsSinceEpoch}.csv',
        allowedExtensions: ['csv'],
      );

      if (result == null) {
        setState(() => _isLoading = false);
        return;
      }

      final csvService = CsvService();
      final exportResult = await csvService.exportTransactions(
        transactions: transactions,
        outputDir: result,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _exportStatus = exportResult.success
            ? 'CSV berhasil disimpan di ${exportResult.filePath}'
            : exportResult.error;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _exportStatus = 'Gagal ekspor: $e';
      });
    }
  }

  Widget _buildReportCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: SizedBox(
        height: 96,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(icon, color: color, size: 20),
                ],
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}