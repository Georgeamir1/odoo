import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odoo/InventoryReceipts/inventory_receipts_details.dart';

import '../InventoryReceipts/inventory_receipts_cubit.dart';
import '../localization.dart';

Widget buildOrderList(
    BuildContext context, List<dynamic> orders, Function loadMore) {
  final ScrollController _scrollController = ScrollController();

  _scrollController.addListener(() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent) {
      loadMore();
    }
  });

  return ListView.builder(
    controller: _scrollController,
    itemCount: orders.length,
    itemBuilder: (context, index) {
      final order = orders[index];
      return buildOrderCard(context, order);
    },
  );
}

Widget buildOrderCard(BuildContext context, dynamic order) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    child: InkWell(
      onTap: () => showDetails(context, order),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Customer Name and Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    getCustomerName(order) ??
                        AppLocalizations.of(context).unknown_customer,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey.shade800,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: getStatusColor(order['state']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    getStatusname(context, order['state']), // Pass context here
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: getStatusColor(order['state']),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Order Details
            _buildDetailRow(
                FeatherIcons.box,
                AppLocalizations.of(context).reference,
                "${order['origin'] ?? 'N/A'}"),
            const SizedBox(height: 8),
            _buildDetailRow(
                FeatherIcons.calendar,
                AppLocalizations.of(context).scheduled,
                _formatDate(order['scheduled_date'])),
            const SizedBox(height: 8),
            _buildDetailRow(
                FeatherIcons.truck,
                AppLocalizations.of(context).items,
                '${order['move_ids_without_package']?.length ?? 0}'),
            const SizedBox(height: 12),
            // Progress Bar
            LinearProgressIndicator(
              value: _getOrderProgress(order['state']),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                getStatusColor(order['state']),
              ),
              minHeight: 6,
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildDetailRow(IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(icon, size: 16, color: Colors.blueGrey.shade400),
      const SizedBox(width: 8),
      Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      SizedBox(
        width: 8,
      ),
      Expanded(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            overflow: TextOverflow.ellipsis,
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.blueGrey.shade800,
            ),
          ),
        ),
      ),
    ],
  );
}

Color getStatusColor(String state) {
  switch (state) {
    case 'draft':
      return OdooColors.draft;
    case 'assigned':
      return OdooColors.ready;
    case 'done':
      return OdooColors.success;
    case 'confirmed':
      return OdooColors.warning;
    case 'cancel':
      return OdooColors.error;
    default:
      return Colors.grey;
  }
}

String getStatusname(BuildContext context, String state) {
  switch (state) {
    case 'draft':
      return AppLocalizations.of(context).draft;
    case 'assigned':
      return AppLocalizations.of(context).ready;
    case 'done':
      return AppLocalizations.of(context).done;
    case 'confirmed':
      return AppLocalizations.of(context).waiting;
    case 'cancel':
      return AppLocalizations.of(context).canceled;
    default:
      return AppLocalizations.of(context).unknown; // Add this translation key
  }
}

double _getOrderProgress(String state) {
  switch (state) {
    case 'draft':
      return 0.2;
    case 'assigned':
      return 0.5;
    case 'done':
      return 1.0;
    case 'confirmed':
      return 0.7;
    case 'cancel':
      return 0.0;
    default:
      return 0.0;
  }
}

String _formatDate(String? date) {
  if (date == null) return 'N/A';
  // Add your date formatting logic here
  return date;
}

List<Widget> buildSlidableActions(BuildContext context, dynamic order) {
  return [
    if (order['state'] == 'assigned')
      SlidableAction(
        icon: Icons.check,
        backgroundColor: OdooColors.success,
        onPressed: (_) => updateStatus(context, order['id'], 'done'),
      ),
    if (order['state'] == 'draft')
      SlidableAction(
        icon: Icons.play_arrow,
        backgroundColor: OdooColors.warning,
        onPressed: (_) => updateStatus(context, order['id'], 'assigned'),
      ),
  ];
}

Widget buildStatusIndicator(String state) {
  final colorIcon = getStatusColorAndIcon(state);
  return CircleAvatar(
    backgroundColor: colorIcon['color'],
    child: Icon(colorIcon['icon'], size: 20, color: Colors.white),
  );
}

void showDetails(BuildContext context, dynamic order) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => InventoryReceiptsDetailPage(
        pickingId: order['id'],
      ),
    ),
  );
}

Map<String, dynamic> getStatusColorAndIcon(String state) {
  switch (state) {
    case 'draft':
      return {'color': OdooColors.draft, 'icon': Icons.access_time};
    case 'assigned':
      return {'color': OdooColors.ready, 'icon': Icons.local_shipping};
    case 'done':
      return {'color': OdooColors.success, 'icon': Icons.check_circle};
    case 'cancel':
      return {'color': OdooColors.error, 'icon': Icons.cancel};
    case 'confirmed':
      return {'color': OdooColors.warning, 'icon': Icons.access_time};
    default:
      return {'color': Colors.grey, 'icon': Icons.error};
  }
}

class OdooColors {
  static const draft = Color(0xFF9C9C9C);
  static const ready = Color(0xFF2196F3);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFF44336);
}

void updateStatus(BuildContext context, int id, String status) {
  InventoryReceiptsCubit.get(context).updateDeliveryStatus(id, status);
}

Widget buildFilterMenu(BuildContext context) {
  return PopupMenuButton<String>(
    color: Colors.white,
    onSelected: (value) => filterByStatus(context, value),
    itemBuilder: (context) => [
      PopupMenuItem(
          value: 'all', child: Text(AppLocalizations.of(context).all)),
      PopupMenuItem(
          value: 'cancel', child: Text(AppLocalizations.of(context).cancel)),
      PopupMenuItem(
          value: 'assigned', child: Text(AppLocalizations.of(context).ready)),
      PopupMenuItem(
          value: 'confirmed',
          child: Text(AppLocalizations.of(context).waiting)),
      PopupMenuItem(
          value: 'done', child: Text(AppLocalizations.of(context).done)),
    ],
  );
}

void filterByStatus(BuildContext context, String status) {
  final cubit = InventoryReceiptsCubit.get(context);
  if (status == 'all') {
    cubit.fetchInventoryReceiptss();
  } else {
    cubit.filterOrders(status);
  }
}

void filterDeliveryOrderByStatus(BuildContext context, String status) {
  final cubit = InventoryReceiptsCubit.get(context);
  if (status == 'all') {
    cubit.fetchInventoryReceiptss();
  } else {
    cubit.filterOrders(status);
  }
}

String getCustomerName(dynamic order) {
  // Check if 'partner_id' exists and is a List
  if (order['partner_id'] is List && order['partner_id'].length > 1) {
    // Safely access the second element (customer name)
    return order['partner_id'][1]?.toString() ?? 'Unknown Customer';
  } else {
    // Fallback if 'partner_id' is null or invalid
    return 'Unknown Customer';
  }
}
