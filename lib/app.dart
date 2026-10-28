/// Konfigurasi aplikasi Dr4oxBill: tema, routing, dan inisialisasi.
library app;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/database/app_database.dart';
import 'core/constants/app_constants.dart';
import 'providers/app_provider.dart';
import 'providers/category_provider.dart';
import 'providers/product_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/setting_provider.dart';
import 'providers/cart_provider.dart';
import 'models/product.dart';
import 'models/category.dart';
import 'screens/dashboard_screen.dart';
import 'screens/pos_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/product_form_screen.dart';
import 'screens/category_list_screen.dart';
import 'screens/category_form_screen.dart';
import 'screens/stock_management_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'screens/transaction_detail_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/backup_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/logo_widget.dart';
import 'widgets/sidebar.dart';

/// Rute layanan aplikasi.
enum AppRoute {
  dashboard,
  pos,
  productList,
  productForm,
  categoryList,
  categoryForm,
  stockManagement,
  transactionHistory,
  transactionDetail,
  settings,
  backup,
  reports,
}

class Dr4oxBillApp extends StatelessWidget {
  const Dr4oxBillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => SettingProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: appName,
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const SplashScreen(),
        routes: {
          '/home': (_) => const Dr4oxBillHome(),
        },
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  static ThemeData _buildTheme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1F4E79), // Biru tua profesional
        brightness: Brightness.light,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      cardTheme: base.cardTheme.copyWith(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        elevation: 0,
        color: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1F4E79)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF1F4E79),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1F4E79),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1F4E79),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          side: const BorderSide(color: Color(0xFF1F4E79)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF1F4E79), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/product_form':
        final product = settings.arguments as Product?;
        return MaterialPageRoute(
          builder: (_) => ProductFormScreen(product: product),
        );
      case '/category_form':
        final category = settings.arguments as Category?;
        return MaterialPageRoute(
          builder: (_) => CategoryFormScreen(category: category),
        );
      case '/transaction_detail':
        final id = settings.arguments as int?;
        return MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(transactionId: id ?? 0),
        );
      default:
        return null;
    }
  }
}

class Dr4oxBillHome extends StatefulWidget {
  const Dr4oxBillHome({super.key});

  @override
  State<Dr4oxBillHome> createState() => _Dr4oxBillHomeState();
}

class _Dr4oxBillHomeState extends State<Dr4oxBillHome> {
  AppRoute _currentRoute = AppRoute.dashboard;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    try {
      final db = AppDatabase();
      await db.database; // Buka koneksi, akan membuat database jika belum ada.
      if (!mounted) return;
      context.read<SettingProvider>().loadSettings();
      context.read<CategoryProvider>().loadCategories();
      context.read<ProductProvider>().loadProducts();
       context.read<TransactionProvider>().loadTransactions();
    } catch (e) {
      debugPrint('Database init error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Deteksi apakah layar lebar (desktop/tablet landscape) atau sempit (mobile portrait).
    final isWideScreen = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      key: _scaffoldKey,
      appBar: isWideScreen
          ? null
          : AppBar(
              automaticallyImplyLeading: true,
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: const AppLogoSmall(),
              centerTitle: false,
            ),
      drawer: isWideScreen
          ? null
          : SidebarDrawer(
              currentRoute: _currentRoute,
              onRouteSelected: (route) {
                setState(() {
                  _currentRoute = route;
                });
                _scaffoldKey.currentState?.closeDrawer();
              },
            ),
      body: isWideScreen
          ? _buildDesktopBody()
          : _buildMobileBody(),
    );
  }

  Widget _buildDesktopBody() {
    return Row(
      children: [
        // Sidebar navigasi (hanya desktop).
        Sidebar(
          currentRoute: _currentRoute,
          onRouteSelected: (route) {
            setState(() {
              _currentRoute = route;
            });
          },
        ),
        // Konten utama.
        Expanded(
          child: _buildBody(),
        ),
      ],
    );
  }

  Widget _buildMobileBody() {
    return _buildBody();
  }

  Widget _buildBody() {
    switch (_currentRoute) {
      case AppRoute.dashboard:
        return const DashboardScreen();
      case AppRoute.pos:
        return const PosScreen();
      case AppRoute.productList:
        return const ProductListScreen();
      case AppRoute.categoryList:
        return const CategoryListScreen();
      case AppRoute.stockManagement:
        return const StockManagementScreen();
      case AppRoute.transactionHistory:
        return const TransactionHistoryScreen();
      case AppRoute.settings:
        return const SettingsScreen();
      case AppRoute.backup:
        return const BackupScreen();
      case AppRoute.reports:
        return const ReportsScreen();
      case AppRoute.productForm:
      case AppRoute.categoryForm:
      case AppRoute.transactionDetail:
        // Di-handle oleh routing terpisah.
        return const Center(child: Text('Gunakan navigasi yang sesuai.'));
    }
  }
}

/// Drawer navigasi untuk layar sempit (mobile).
/// Memakai widget Sidebar yang sama dengan desktop supaya tampilan konsisten.
class SidebarDrawer extends StatelessWidget {
  final AppRoute currentRoute;
  final ValueChanged<AppRoute> onRouteSelected;

  const SidebarDrawer({
    super.key,
    required this.currentRoute,
    required this.onRouteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 260,
      backgroundColor: const Color(0xFF1F4E79),
      child: Sidebar(
        currentRoute: currentRoute,
        onRouteSelected: onRouteSelected,
      ),
    );
  }
}