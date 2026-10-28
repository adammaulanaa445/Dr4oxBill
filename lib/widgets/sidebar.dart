/// Sidebar navigasi aplikasi Dr4oxBill.
library sidebar;

import 'package:flutter/material.dart';

import '../app.dart';
import '../core/constants/app_constants.dart';

const Color _sidebarBg = Color(0xFF1F4E79);
const Color _headerBg = Color(0xFF163A5C);

class Sidebar extends StatelessWidget {
  final AppRoute currentRoute;
  final ValueChanged<AppRoute> onRouteSelected;

  const Sidebar({
    super.key,
    required this.currentRoute,
    required this.onRouteSelected,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // Material eksplisit supaya warna tidak tertimpa Drawer/tema.
    return Material(
      color: _sidebarBg,
      child: SizedBox(
        width: 260,
        child: Column(
          children: [
            // Header aplikasi dengan logo.
            Container(
              width: double.infinity,
              color: _headerBg,
              padding: EdgeInsets.fromLTRB(20, 24 + topInset, 20, 20),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset(
                      'assets/images/dr4ox.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.two_wheeler,
                        color: _sidebarBg,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Dr4oxBill',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'POS Dr4ox Motor',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Menu navigasi.
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildMenuItem(
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    route: AppRoute.dashboard,
                  ),
                  _buildMenuItem(
                    icon: Icons.point_of_sale,
                    title: 'Kasir',
                    route: AppRoute.pos,
                  ),
                  _buildMenuItem(
                    icon: Icons.inventory,
                    title: 'Produk & Jasa',
                    route: AppRoute.productList,
                  ),
                  _buildMenuItem(
                    icon: Icons.category,
                    title: 'Kategori',
                    route: AppRoute.categoryList,
                  ),
                  _buildMenuItem(
                    icon: Icons.inventory_2,
                    title: 'Stok',
                    route: AppRoute.stockManagement,
                  ),
                  _buildMenuItem(
                    icon: Icons.history,
                    title: 'Riwayat Transaksi',
                    route: AppRoute.transactionHistory,
                  ),
                  _buildMenuItem(
                    icon: Icons.bar_chart,
                    title: 'Laporan',
                    route: AppRoute.reports,
                  ),
                  _buildMenuItem(
                    icon: Icons.settings,
                    title: 'Pengaturan',
                    route: AppRoute.settings,
                  ),
                  _buildMenuItem(
                    icon: Icons.backup,
                    title: 'Backup & Restore',
                    route: AppRoute.backup,
                  ),
                ],
              ),
            ),
            // Footer.
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
              child: Text(
                'v$appVersion',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required AppRoute route,
  }) {
    final isActive = currentRoute == route;
    final color = isActive ? Colors.white : Colors.white70;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: Colors.transparent,
        selectedTileColor: Colors.white.withOpacity(0.16),
        selected: isActive,
        iconColor: color,
        textColor: color,
        selectedColor: Colors.white,
        hoverColor: const Color(0xFF2E5E8C),
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: () {
          if (!isActive) {
            onRouteSelected(route);
          }
        },
      ),
    );
  }
}