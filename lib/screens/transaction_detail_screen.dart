
/// Layar detail transaksi dengan opsi cetak ulang struk dan pembatalan.
library transaction_detail_screen;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../providers/setting_provider.dart';
import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../core/utils/money.dart';
import '../core/utils/date_utils.dart';
import '../core/constants/app_constants.dart';
import '../services/pdf_service.dart';
import '../services/file_service.dart';

class TransactionDetailScreen extends StatefulWidget {
  final int transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends State<TransactionDetailScreen> {
  bool _isLoading = true;
  String? _error;
  Transaction? _transaction;
  List<TransactionItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final provider = context.read<TransactionProvider>();
    final result =
        await provider.getTransactionDetail(widget.transactionId);

    if (!mounted) return;

    if (result.success && result.data != null) {
      final data = result.data!;
      final txMap = data['transaction'] as Map<String, dynamic>;
      final itemsList = data['items'] as List<Map<String, dynamic>>;

      setState(() {
        _transaction = Transaction.fromMap(txMap);
        _items = itemsList
            .map((item) => TransactionItem.fromMap(item))
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result.error ?? 'Gagal memuat detail.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Transaksi')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Transaksi')),
        body: Center(child: Text(_error!)),
      );
    }

    final transaction = _transaction!;
    final isCancelled = transaction.isCancelled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            transaction.transactionNumber,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isCancelled
                                ? Colors.grey[200]
                                : Colors.green[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isCancelled
                                ? 'DIBATALKAN'
                                : 'SELESAI',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isCancelled
                                  ? Colors.grey
                                  : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatDateTime(
                        transaction.transactionDate,
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const Divider(),
                    Text(
                      'Metode: ${transaction.paymentMethod}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total: ${formatRupiah(transaction.total)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isCancelled) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Alasan pembatalan: '
                        '${transaction.cancellationReason ?? '-'}',
                        style: const TextStyle(color: Colors.red),
                      ),
                      if (transaction.cancelledAt != null)
                        Text(
                          'Dibatalkan pada: '
                          '${formatDateTime(transaction.cancelledAt!)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Item',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F4E79),
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];

                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.inventory,
                      size: 20,
                    ),
                  ),
                  title: Text(item.name),
                  subtitle: Text(
                    '${item.sku} • ${item.itemType}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.quantity} x '
                        '${formatRupiah(item.unitPrice)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        formatRupiah(item.subtotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  formatRupiah(transaction.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Uang Diterima'),
                Text(formatRupiah(transaction.cashReceived)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kembalian'),
                Text(formatRupiah(transaction.changeAmount)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (!isCancelled)
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.print),
                      label: const Text('Cetak Ulang Struk'),
                      onPressed: _reprintReceipt,
                    ),
                  ),
                if (!isCancelled) const SizedBox(width: 8),
                if (!isCancelled)
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.cancel,
                        color: Colors.white,
                      ),
                      label: const Text('Batalkan Transaksi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => _cancelTransaction(context),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Generate ulang struk PDF dari transaksi yang sudah ada.
  Future<void> _reprintReceipt() async {
    if (_transaction == null) return;

    final transaction = _transaction!;
    final settingProvider = context.read<SettingProvider>();

    final businessName = settingProvider.get(
      'business_name',
      defaultValue: defaultBusinessName,
    );

    final businessAddress = settingProvider.get(
      'business_address',
      defaultValue: '',
    );

    final businessPhone = settingProvider.get(
      'business_phone',
      defaultValue: '',
    );

    final thankYouMessage = settingProvider.get(
      'thank_you_message',
      defaultValue: 'Terima kasih telah berkunjung ke Dr4ox Motor',
    );

    final receiptItems = _items.map((item) {
      return ReceiptItem(
        name: item.name,
        quantity: item.quantity,
        subtotal: item.subtotal,
      );
    }).toList();

    try {
      final docsDir = await FileService.getDocumentsDir();

      final pdfService = PdfService();

      final result = await pdfService.generateReceipt(
        transactionNumber: transaction.transactionNumber,
        transactionDate: transaction.transactionDate,
        subtotal: transaction.subtotal,
        discount: transaction.discount,
        total: transaction.total,
        cashReceived: transaction.cashReceived,
        changeAmount: transaction.changeAmount,
        paymentMethod: transaction.paymentMethod,
        items: receiptItems,
        outputDir: docsDir,
        businessName: businessName,
        businessAddress: businessAddress,
        businessPhone: businessPhone,
        thankYouMessage: thankYouMessage,
      );

      if (!mounted) return;

      if (result.success && result.filePath != null) {
        // Flutter Web: jangan membuka dialog cetak platform lain.
        if (kIsWeb) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Struk berhasil dibuat. Gunakan Save as PDF '
                'pada dialog cetak browser jika tersedia.',
              ),
            ),
          );
          return;
        }

        // Android/Windows dan platform selain Web.
        final shouldPrint = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Struk PDF'),
            content: Text(
              'Struk berhasil dibuat:\n'
              '${result.filePath}\n\n'
              'Apakah ingin mencetak struk sekarang?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('Nanti'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Cetak'),
              ),
            ],
          ),
        );

        if (shouldPrint == true && mounted) {
          await pdfService.printPdf(result.filePath!);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal membuat struk: '
              '${result.error ?? 'Terjadi kesalahan.'}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal cetak ulang struk: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelTransaction(
    BuildContext context,
  ) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: const Text('Batalkan Transaksi?'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Masukkan alasan pembatalan:',
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Alasan *',
                        ),
                        autofocus: true,
                        onChanged: (_) {
                          setDialogState(() {});
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext, false);
                      },
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed:
                          reasonController.text.trim().isEmpty
                              ? null
                              : () {
                                  Navigator.pop(dialogContext, true);
                                },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Batalkan'),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false;

    if (!confirmed) {
      reasonController.dispose();
      return;
    }

    final reason = reasonController.text.trim();
    reasonController.dispose();

    final provider = context.read<TransactionProvider>();

    final result = await provider.cancelTransaction(
      transactionId: widget.transactionId,
      reason: reason,
    );

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil dibatalkan.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.error ?? 'Gagal membatalkan transaksi.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
