import 'package:flutter/material.dart';
import '../InventoryReceipts/inventory_receipts_ui.dart';
import '../delivery_order/delivery_order_ui.dart';
import '../localization.dart';
import '../login/login_ui.dart';
import '../networking/odoo_service.dart';
import '../sales_order/sales_order_list.dart';

class HomePage extends StatelessWidget {
  final Function(String) changeLanguage;
  const HomePage({Key? key, required this.changeLanguage}) : super(key: key);

  Widget _buildOptionCard({
    required BuildContext context,
    required String titleKey,
    required IconData icon,
    required VoidCallback onTap,
    required Color backgroundColor,
    Color iconColor = const Color(0xFF714B67),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: iconColor,
            ),
            const SizedBox(height: 16),
            Text(
              titleKey,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF714B67),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF714B67),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            iconTheme: IconThemeData(color: Colors.white),
            title: Text(
              AppLocalizations.of(context).homeTitle,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () {
                    OdooRpcService().logout();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage(
                                title: 'login page',
                              )),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _buildOptionCard(
                  context: context,
                  titleKey: AppLocalizations.of(context).order,
                  icon: Icons.receipt_long,
                  backgroundColor: const Color(0xFFF3E5F5),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SaleOrderPage()),
                    );
                  },
                ),
                _buildOptionCard(
                  context: context,
                  titleKey: AppLocalizations.of(context).deliveryOrder,
                  icon: Icons.local_shipping,
                  backgroundColor: const Color(0xFFE8F5E9),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DeliveryOrderPage()),
                    );
                  },
                ),
                _buildOptionCard(
                  context: context,
                  titleKey: AppLocalizations.of(context).inventoryReceipts,
                  icon: Icons.receipt,
                  backgroundColor: const Color(0xFFE8F5E9),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => InventoryReceiptsPage()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
