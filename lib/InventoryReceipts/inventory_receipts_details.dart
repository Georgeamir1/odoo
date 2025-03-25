import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:odoo/InventoryReceipts/widgets.dart';
import 'package:odoo/delivery_order/delivery_order_ui.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import '../delivery_order/delivery_order_cubit.dart';
import '../delivery_order/delivery_order_status.dart';
import '../localization.dart';
import '../networking/odoo_service.dart';
import 'inventory_receipts_cubit.dart';
import 'inventory_receipts_status.dart';
import 'inventory_receipts_ui.dart';

class InventoryReceiptsDetailPage extends StatelessWidget {
  final int pickingId;
  const InventoryReceiptsDetailPage({
    Key? key,
    required this.pickingId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InventoryReceiptsDetailCubit(OdooRpcService())
        ..fetchDetail(pickingId),
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            AppLocalizations.of(context).inventory_receipts_details,
            style: const TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF714B67),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
        body: BlocListener<InventoryReceiptsDetailCubit,
            InventoryReceiptsDetailState>(
          listener: (context, state) {
            if (state is InventoryReceiptsvalidationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      AppLocalizations.of(context).orderValidatedSuccessfully),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is NavigateToInventoryReceiptsPage) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InventoryReceiptsPage(),
                ),
              );
            } else if (state is InventoryReceiptsvalidationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('⚠️ ${state.message}'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          },
          child: BlocBuilder<InventoryReceiptsDetailCubit,
              InventoryReceiptsDetailState>(
            builder: (context, state) {
              if (state is InventoryReceiptsDetailLoading) {
                return _buildLoadingState(context);
              } else if (state is InventoryReceiptsDetailError) {
                return _buildErrorState(context, state.message);
              } else if (state is InventoryReceiptsDetailLoaded) {
                return _buildContent(state, context);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/images/loading.json'),
          const SizedBox(height: 20),
          Text(AppLocalizations.of(context).loadingOrderDetails),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context).errorLoadingOrder,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          Text(
            message,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      InventoryReceiptsDetailLoaded state, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _OrderHeaderCard(detail: state.detail),
          const SizedBox(height: 16),
          _ProductListSection(moves: state.detail['moves']),
          const SizedBox(height: 24),
          _ActionSection(picking: state.picking, pickingId: pickingId),
        ],
      ),
    );
  }
}

class _OrderHeaderCard extends StatelessWidget {
  final Map<String, dynamic> detail;

  const _OrderHeaderCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  detail['name'] ?? AppLocalizations.of(context).notAvailable,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold, color: Color(0xFF714B67)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: getStatusColor(detail['state']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    getStatusname(
                        context, detail['state']), // Pass context here
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: getStatusColor(detail['state']),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
                Icons.calendar_today,
                AppLocalizations.of(context).scheduledDate,
                detail['scheduled_date']),
            _buildInfoRow(
                Icons.timelapse,
                AppLocalizations.of(context).deadline,
                "${detail['date_deadline'] ?? AppLocalizations.of(context).notAvailable}"),
            _buildInfoRow(
                Icons.description,
                AppLocalizations.of(context).sourceDocument,
                "${detail['origin'] ?? AppLocalizations.of(context).notAvailable}"),
            if (detail['picking_type_id'] != null)
              _buildInfoRow(
                Icons.category,
                AppLocalizations.of(context).operationType,
                detail['picking_type_id'][1]?.toString() ?? '',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final statusConfig = _getStatusConfig(status);
    return Chip(
      label: Text(status.toUpperCase()),
      backgroundColor: statusConfig.color.withOpacity(0.2),
      labelStyle: TextStyle(
        color: statusConfig.color,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      shape: StadiumBorder(side: BorderSide(color: statusConfig.color)),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return _StatusConfig(Colors.blue, Icons.edit);
      case 'assigned':
        return _StatusConfig(Colors.orange, Icons.assignment_turned_in);
      case 'done':
        return _StatusConfig(Colors.green, Icons.check_circle);
      case 'cancel':
        return _StatusConfig(Colors.red, Icons.cancel);
      default:
        return _StatusConfig(Colors.grey, Icons.help_outline);
    }
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;

  _StatusConfig(this.color, this.icon);
}

class _ProductListSection extends StatelessWidget {
  final List<dynamic> moves;

  const _ProductListSection({required this.moves});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '${AppLocalizations.of(context).products} (${moves.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
          ),
        ),
        const SizedBox(height: 12),
        ...moves.map((move) => _ProductListItem(move: move)).toList(),
      ],
    );
  }
}

class _ProductListItem extends StatelessWidget {
  final dynamic move;
  const _ProductListItem({required this.move});

  @override
  Widget build(BuildContext context) {
    final productName =
        move['product_id']?[1] ?? AppLocalizations.of(context).unknownProduct;
    final demandedQty = move['product_uom_qty'] ?? move['product_qty'];
    final quantity = move['quantity'];
    final uom = move['product_uom']?[1] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.inventory_2, color: Color(0xFF714B67)),
        ),
        title: Text(productName),
        subtitle: Text('${AppLocalizations.of(context).unit}: $uom'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${AppLocalizations.of(context).demand}: $demandedQty',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              '${AppLocalizations.of(context).quantity}: $quantity',
              style: TextStyle(
                fontSize: 14,
                color: quantity >= demandedQty ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  final Map<String, dynamic> picking;
  final int pickingId;

  const _ActionSection({required this.picking, required this.pickingId});

  @override
  Widget build(BuildContext context) {
    final availability =
        picking['products_availability']?.toString() ?? 'unknown';
    final isAvailable = availability == 'Available' || availability == 'متاح';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          if (picking['state']?.toString() == 'assigned')
            if (isAvailable)
              _buildActionButton(
                context,
                AppLocalizations.of(context).validateOrder,
                Icons.check_circle_outline,
                Colors.green,
                () async {
                  await _validateOrder(context);
                },
              ),
          if (picking['state']?.toString() == 'assigned')
            if (!isAvailable) ...[
              _buildActionButton(
                context,
                AppLocalizations.of(context).createBackorder,
                Icons.reply_all,
                Color(0xFF714B67),
                () {
                  context
                      .read<InventoryReceiptsDetailCubit>()
                      .validate_With_BackOrder(pickingId);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                context,
                AppLocalizations.of(context).validateWithoutBackorder,
                Icons.dangerous,
                Colors.orange,
                isOutlined: true,
                () {
                  context
                      .read<InventoryReceiptsDetailCubit>()
                      .validate_without_backOrder(pickingId);
                  Navigator.pop(context);
                },
              ),
            ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: isOutlined
          ? OutlinedButton.icon(
              icon: Icon(icon, color: color),
              label: Text(text),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onPressed,
            )
          : ElevatedButton.icon(
              icon: Icon(icon, color: Colors.white),
              label: Text(
                text,
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onPressed,
            ),
    );
  }

  Future<void> _validateOrder(BuildContext context) async {
    if (picking['state'] == 'assigned') {
      await context
          .read<InventoryReceiptsDetailCubit>()
          .validateOrder(pickingId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).orderCannotBeValidated),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
