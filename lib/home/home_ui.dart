import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../InventoryReceipts/inventory_receipts_ui.dart';
import '../cash_receipt/cash_receipt_list.dart';
import '../delivery_order/delivery_order_ui.dart';
import '../invoicing/invoicing_list.dart';
import '../localization.dart';
import '../locale_cubit.dart';
import '../login/login_ui.dart';
import '../networking/odoo_service.dart';
import '../sales_order/sales_order_list.dart';
import '../stock_picking_request/stock_picking_request_ui.dart';
import '../warehouse_stock/warehouse_stock_ui.dart';

class HomePage extends StatefulWidget {
  final Function(String) changeLanguage;
  const HomePage({Key? key, required this.changeLanguage}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? username;
  bool _showLanguageOptions = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final service = OdooRpcService();
    final user = await service.getCurrentUser();

    if (user != null && user.containsKey('name')) {
      setState(() {
        username = user['name'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primaryColor = const Color(0xFF714B67);

    return Scaffold(
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child:
              SafeArea(child: _buildAppBar(context, isArabic, primaryColor))),
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      drawer: _buildDrawer(context, isArabic, primaryColor),
      body: Column(
        children: [
          Expanded(
            child: _buildHomeContent(context, isArabic, primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isArabic, Color primaryColor) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(FeatherIcons.menu, color: primaryColor),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).welcomeText,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    username ?? AppLocalizations.of(context).homeTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _showLanguageOptions ? FeatherIcons.x : FeatherIcons.globe,
                  color: primaryColor,
                ),
                onPressed: () {
                  setState(() {
                    _showLanguageOptions = !_showLanguageOptions;
                  });
                },
              ),
              if (_showLanguageOptions) ...[
                TextButton(
                  onPressed: () {
                    context.read<LocaleCubit>().switchToEnglish();
                    setState(() {
                      _showLanguageOptions = false;
                    });
                  },
                  child: Text(
                    'EN',
                    style: TextStyle(
                      color: !isArabic ? primaryColor : Colors.grey,
                      fontWeight:
                          !isArabic ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.read<LocaleCubit>().switchToArabic();
                    setState(() {
                      _showLanguageOptions = false;
                    });
                  },
                  child: Text(
                    'AR',
                    style: TextStyle(
                      color: isArabic ? primaryColor : Colors.grey,
                      fontWeight:
                          isArabic ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(
      BuildContext context, bool isArabic, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(context, primaryColor),
          /*    const SizedBox(height: 24),
          _buildQuickActions(context, primaryColor),*/
          const SizedBox(height: 24),
          _buildMainMenuSection(context, primaryColor),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FeatherIcons.activity, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'Odoo Management System',
                      textStyle: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      speed: const Duration(milliseconds: 100),
                    ),
                  ],
                  totalRepeatCount: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Manage your business operations efficiently',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).quickActions,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickActionCard(
                context,
                FeatherIcons.shoppingBag,
                "    ${AppLocalizations.of(context).new_order}${AppLocalizations.of(context).order}",
                Colors.purple.shade100,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SaleOrderPage()),
                ),
              ),
              _buildQuickActionCard(
                context,
                FeatherIcons.truck,
                AppLocalizations.of(context).deliveryOrder,
                Colors.green.shade100,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DeliveryOrderPage()),
                ),
              ),
              _buildQuickActionCard(
                context,
                FeatherIcons.fileText,
                AppLocalizations.of(context).invoices,
                Colors.blue.shade100,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => invoicingPage()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF714B67), size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainMenuSection(BuildContext context, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildMainMenuCard(
              icon: FeatherIcons.shoppingBag,
              title: AppLocalizations.of(context).order,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SaleOrderPage()),
              ),
            ),
            _buildMainMenuCard(
              icon: FeatherIcons.truck,
              title: AppLocalizations.of(context).deliveryOrder,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DeliveryOrderPage()),
              ),
            ),
            _buildMainMenuCard(
              icon: FeatherIcons.fileText,
              title: AppLocalizations.of(context).invoices,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => invoicingPage()),
              ),
            ),
            _buildMainMenuCard(
              icon: FeatherIcons.package,
              title: AppLocalizations.of(context).inventoryReceipts,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => InventoryReceiptsPage()),
              ),
            ),
            _buildMainMenuCard(
              icon: FeatherIcons.refreshCw,
              title: AppLocalizations.of(context).stockPickingRequests,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const StockPickingRequestPage()),
              ),
            ),
            _buildMainMenuCard(
              icon: FeatherIcons.database,
              title: AppLocalizations.of(context).warehouse_stock,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const WarehouseStockPage()),
              ),
            ),
            _buildMainMenuCard(
              icon: FeatherIcons.creditCard,
              title: AppLocalizations.of(context).cash_receipts,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CashReceiptListPage()),
              ),
            ),
          ],
        ),
      ],
    );
  }

/*  Widget _buildMainMenuCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF714B67), size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }*/

  Widget _buildDrawer(BuildContext context, bool isArabic, Color primaryColor) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 32,
                  child: Icon(
                    FeatherIcons.user,
                    color: Color(0xFF714B67),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  username ?? AppLocalizations.of(context).homeTitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Odoo Management System',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            FeatherIcons.home,
            AppLocalizations.of(context).homeTitle,
            () => Navigator.pop(context),
          ),
          _buildDrawerItem(
            context,
            FeatherIcons.shoppingBag,
            AppLocalizations.of(context).order,
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SaleOrderPage()),
              );
            },
          ),
          _buildDrawerItem(
            context,
            FeatherIcons.truck,
            AppLocalizations.of(context).deliveryOrder,
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DeliveryOrderPage()),
              );
            },
          ),
          _buildDrawerItem(
            context,
            FeatherIcons.fileText,
            AppLocalizations.of(context).invoices,
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => invoicingPage()),
              );
            },
          ),
          _buildDrawerItem(
            context,
            FeatherIcons.package,
            AppLocalizations.of(context).inventoryReceipts,
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => InventoryReceiptsPage()),
              );
            },
          ),
          _buildDrawerItem(
            context,
            FeatherIcons.refreshCw,
            AppLocalizations.of(context).stockPickingRequests,
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const StockPickingRequestPage()),
              );
            },
          ),
          _buildDrawerItem(
            context,
            FeatherIcons.database,
            AppLocalizations.of(context).warehouse_stock,
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const WarehouseStockPage()),
              );
            },
          ),
          /*    _buildDrawerItem(
            context,
            FeatherIcons.creditCard,
            AppLocalizations.of(context).cash_receipts,
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CashReceiptsScreen()),
              );
            },
          ),*/
          const Divider(),
          _buildDrawerItem(
            context,
            FeatherIcons.globe,
            'Language',
            () {
              Navigator.pop(context);
              setState(() {
                _showLanguageOptions = true;
              });
            },
          ),
          _buildDrawerItem(
            context,
            FeatherIcons.logOut,
            AppLocalizations.of(context).logout,
            () {
              OdooRpcService().logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(title: 'login page'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF714B67)),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildMainMenuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(15),
      color: Colors.white,
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap, // Add navigation logic
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF714B67).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Color(0xFF714B67), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
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
