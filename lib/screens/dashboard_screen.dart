/// Layar Dashboard — ringkasan data transaksi dan stok dari database.
library dashboard_screen;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../providers/transaction_provider.dart';
import '../core/database/app_database.dart';
import '../core/utils/money.dart';
import '../core/utils/date_utils.dart';
import 'transaction_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _todayItemsSold = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTodayItemsSold();
    });
  }

  /// Hitung total kuantitas barang/jasa yang terjual hari ini dari transaction_items.
  Future<void> _loadTodayItemsSold() async {
    try {
      final db = await AppDatabase().database;
      final today = DateTime.now();
      final start = startOfDay(today).toIso8601String();
      final end = endOfDay(today).toIso8601String();

      final result = await db.rawQuery('''
        SELECT COALESCE(SUM(ti.quantity), 0) AS total_qty
        FROM transaction_items ti
        JOIN transactions t ON t.id = ti.transaction_id
        WHERE t.status = 'completed'
          AND t.transaction_date >= ?
          AND t.transaction_date <= ?
      ''', [start, end]);

      if (!mounted) return;
      final totalQty = (result.first['total_qty'] as num?)?.toInt() ?? 0;
      setState(() {
        _todayItemsSold = totalQty;
      });
    } catch (e) {
      debugPrint('Gagal load items sold: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Consumer2<TransactionProvider, ProductProvider>(
        builder: (context, txProvider, productProvider, child) {
          final transactions = txProvider.transactions;

          // Hitung omzet hari ini.
          final today = DateTime.now();
          final todayStart = startOfDay(today);
          final todayEnd = endOfDay(today);

          final todayTransactions = transactions.where((t) {
            final date = parseDbDateTime(t['transaction_date']);
            final status = t['status'] as String;
            return status == 'completed' &&
                date.isAfter(todayStart) &&
                date.isBefore(todayEnd);
          }).toList();

          final todayRevenue = todayTransactions.fold<int>(
            0,
            (sum, t) => sum + (t['total'] as int),
          );

          final todayCount = todayTransactions.length;

          // Produk stok menipis.
          final lowStock = productProvider.lowStockProducts;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Judul.
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F4E79),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ringkasan operasional bengkel Dr4ox Motor',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 24),

                // Ringkasan kartu.
                _buildSummaryCards(
                  todayRevenue: todayRevenue,
                  todayCount: todayCount,
                  todayItemsSold: _todayItemsSold,
                  lowStockCount: lowStock.length,
                ),
                const SizedBox(height: 24),

                // Produk stok menipis.
                _buildLowStockSection(context, lowStock),
                const SizedBox(height: 24),

                // Transaksi terbaru.
                _buildRecentTransactions(context, todayTransactions),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards({
    required int todayRevenue,
    required int todayCount,
    required int todayItemsSold,
    required int lowStockCount,
  }) {
    final cards = <Widget>[
      _buildSummaryCard(
        title: 'Omzet Hari Ini',
        value: formatRupiah(todayRevenue),
        icon: Icons.monetization_on,
        color: Colors.green,
      ),
      _buildSummaryCard(
        title: 'Transaksi',
        value: todayCount.toString(),
        icon: Icons.receipt,
        color: Colors.blue,
      ),
      _buildSummaryCard(
        title: 'Barang Terjual',
        value: todayItemsSold.toString(),
        icon: Icons.shopping_bag,
        color: Colors.orange,
      ),
      _buildSummaryCard(
        title: 'Stok Menipis',
        value: lowStockCount.toString(),
        icon: Icons.warning,
        color: Colors.red,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // HP: 2 kolom. Layar lebar: 4 kolom.
        final columns = constraints.maxWidth >= 700 ? 4 : 2;
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 112,
          ),
          children: cards,
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockSection(BuildContext context, List lowStock) {
    if (lowStock.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Peringatan Stok Menipis',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F4E79),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: lowStock.length,
            itemBuilder: (context, index) {
              final product = lowStock[index];
              return Container(
                width: 180,
                margin: const EdgeInsets.only(right: 12),
                child: Card(
                  color: Colors.orange[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          'Stok: ${product.stock} (min: ${product.minStock})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(BuildContext context, List transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                'Transaksi Terbaru',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F4E79),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () {
                 Navigator.of(context).push(
                   MaterialPageRoute(
                     builder: (_) => const TransactionHistoryScreen(),
                   ),
                 );
               },
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (transactions.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Belum ada transaksi hari ini.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: transactions.asMap().entries.map((entry) {
                final index = entry.key;
                final t = entry.value;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1F4E79).withOpacity(0.1),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Color(0xFF1F4E79),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    t['transaction_number'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    formatDateTime(parseDbDateTime(t['transaction_date'])),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    formatRupiah(t['total'] ?? 0),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}