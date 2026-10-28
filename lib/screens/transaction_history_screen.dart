/// Layar riwayat transaksi dengan pencarian dan filter tanggal.
library transaction_history_screen;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../core/utils/money.dart';
import '../core/utils/date_utils.dart';
import '../widgets/sidebar.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TransactionProvider>().loadTransactions();
      }
    });
  }
  String _statusFilter = 'all'; // all, completed, cancelled
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final transactions = provider.transactions;

          final filtered = transactions.where((t) {
            final number =
                (t['transaction_number'] as String? ?? '').toString();
            if (_searchQuery.isNotEmpty &&
                number.isNotEmpty &&
                !number.toLowerCase().contains(_searchQuery.toLowerCase())) {
              return false;
            }
            final status = (t['status'] ?? '').toString();
            if (_statusFilter != 'all' && status != _statusFilter) {
              return false;
            }
            if (_startDate != null) {
              final date = parseDbDateTime(t['transaction_date']);
              if (date.isBefore(startOfDay(_startDate!))) return false;
            }
            if (_endDate != null) {
              final date = parseDbDateTime(t['transaction_date']);
              if (date.isAfter(endOfDay(_endDate!))) return false;
            }
            return true;
          }).toList();

          return Column(
            children: [
              // Filter.
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Cari nomor transaksi...',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (v) => setState(() => _searchQuery = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _statusFilter,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'all', child: Text('Semua')),
                              DropdownMenuItem(
                                  value: 'completed', child: Text('Selesai')),
                              DropdownMenuItem(
                                  value: 'cancelled',
                                  child: Text('Dibatalkan')),
                            ],
                            onChanged: (v) =>
                                setState(() => _statusFilter = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(context, true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Dari Tanggal',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(_startDate != null
                                  ? formatShortDate(_startDate!)
                                  : 'Pilih'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(context, false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Sampai Tanggal',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(_endDate != null
                                  ? formatShortDate(_endDate!)
                                  : 'Pilih'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Daftar transaksi.
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('Tidak ada transaksi.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final t = filtered[index];
                          return _buildTransactionRow(context, t, provider);
                        },
                      ),
              ),
            ],
          );
        },
      ),
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

  Widget _buildTransactionRow(
    BuildContext context,
    Map<String, dynamic> t,
    TransactionProvider provider,
  ) {
    final status = (t['status'] ?? '').toString();
    final isCancelled = status == 'cancelled';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCancelled ? Colors.grey : const Color(0xFF1F4E79),
          child: Text(
            ((t['transaction_number'] as String?) ?? '').isNotEmpty
                ? (t['transaction_number'] as String).substring(0, 2)
                : '??',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ),
        title: Text(
          t['transaction_number'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatDateTime(parseDbDateTime(t['transaction_date'])),
              style: const TextStyle(fontSize: 12),
            ),
            if (isCancelled)
              Text(
                'Dibatalkan: ${t['cancellation_reason'] ?? ''}',
                style: const TextStyle(color: Colors.red, fontSize: 11),
              ),
          ],
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isCancelled
                    ? Colors.grey[200]
                    : const Color(0xFF1F4E79).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isCancelled ? 'Batal' : 'Selesai',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isCancelled ? Colors.grey : const Color(0xFF1F4E79),
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          final id = t['id'] as int;
          Navigator.pushNamed(context, '/transaction_detail', arguments: id);
        },
      ),
    );
  }
}
