import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:odoo/delivery_order/delivery_order_ui.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../InventoryReceipts/widgets.dart';
import '../delivery_order/delivery_order_cubit.dart';
import '../delivery_order/delivery_order_status.dart';
import '../networking/odoo_service.dart';
import '../testttt.dart';
import '../localization.dart';

class DeliveryOrderDetailPage extends StatelessWidget {
  final int pickingId;
  const DeliveryOrderDetailPage({
    Key? key,
    required this.pickingId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DeliveryOrderDetailCubit(OdooRpcService())..fetchDetail(pickingId),
      child: WillPopScope(
        onWillPop: () async {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DeliveryOrderPage(),
            ),
          );
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              AppLocalizations.of(context).deliveryOrderDetails,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            elevation: 4,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF714B67), Color(0xFF543D48)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
            ),
          ),
          body:
              BlocListener<DeliveryOrderDetailCubit, DeliveryOrderDetailState>(
            listener: (context, state) {
              if (state is DeliveryOrdervalidationSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)
                        .orderValidatedSuccessfully),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
                Navigator.pop(context);
              } else if (state is NavigateToDeliveryOrderPage) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DeliveryOrderPage(),
                  ),
                );
              } else if (state is DeliveryOrdervalidationError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('⚠️ ${state.message}'),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            child:
                BlocBuilder<DeliveryOrderDetailCubit, DeliveryOrderDetailState>(
              builder: (context, state) {
                if (state is DeliveryOrderDetailLoading) {
                  return _buildLoadingState(context);
                } else if (state is DeliveryOrderDetailError) {
                  return _buildErrorState(context, state.message);
                } else if (state is DeliveryOrderDetailLoaded) {
                  return _buildContent(state, context);
                }
                return const SizedBox.shrink();
              },
            ),
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
          Lottie.asset(
            'assets/images/loading.json',
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context).loadingOrderDetails,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 60),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).errorLoadingOrder,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF714B67),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => context
                  .read<DeliveryOrderDetailCubit>()
                  .fetchDetail(pickingId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(DeliveryOrderDetailLoaded state, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OrderHeaderCard(detail: state.detail),
          const SizedBox(height: 20),
          _ProductListSection(moves: state.detail['moves'], state: state),
          const SizedBox(height: 24),
          _ActionSection(picking: state.picking, pickingId: pickingId),
          const SizedBox(height: 20),
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
    final statusConfig = _getStatusConfig(detail['state']);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    detail['name'] ?? AppLocalizations.of(context).notAvailable,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D2D34),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Chip(
                  backgroundColor: statusConfig.color.withOpacity(0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: statusConfig.color, width: 1),
                  ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusConfig.icon,
                          size: 16, color: statusConfig.color),
                      const SizedBox(width: 6),
                      Text(
                        getStatusname(context, detail['state']),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: statusConfig.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            _buildInfoRow(
              Icons.calendar_today_outlined,
              AppLocalizations.of(context).scheduledDate,
              detail['scheduled_date'] == false ||
                      detail['scheduled_date'] == null
                  ? '--/--/--'
                  : detail['scheduled_date'],
            ),
            _buildInfoRow(
              Icons.hourglass_bottom_rounded,
              AppLocalizations.of(context).deadline,
              detail['date_deadline'] == false ||
                      detail['date_deadline'] == null
                  ? '--/--/--'
                  : detail['date_deadline'],
            ),
            _buildInfoRow(
              Icons.description_outlined,
              AppLocalizations.of(context).sourceDocument,
              detail['origin'] == false || detail['origin'] == null
                  ? AppLocalizations.of(context).notAvailable
                  : detail['origin'],
            ),
            if (detail['picking_type_id'] != null ||
                detail['picking_type_id'] != false)
              _buildInfoRow(
                Icons.inventory_2_outlined,
                AppLocalizations.of(context).operationType,
                detail['picking_type_id'][1]?.toString() ?? '',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
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
        return _StatusConfig(Colors.blueGrey, Icons.edit_document);
      case 'assigned':
        return _StatusConfig(Colors.blue, Icons.assignment_turned_in);
      case 'done':
        return _StatusConfig(Colors.green, Icons.check_circle);
      case 'cancel':
        return _StatusConfig(Colors.red, Icons.cancel);
      case 'confirmed':
        return _StatusConfig(Colors.orange, Icons.assignment_ind);
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
  final DeliveryOrderDetailLoaded state;

  const _ProductListSection({required this.moves, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            '${AppLocalizations.of(context).products} (${moves.length})',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        ...moves
            .map((move) => _ProductListItem(move: move, state: state))
            .toList(),
      ],
    );
  }
}

class _ProductListItem extends StatelessWidget {
  final dynamic move;
  final DeliveryOrderDetailLoaded state;
  final _quantityController = TextEditingController();

  _ProductListItem({required this.move, required this.state}) {
    _quantityController.text = (move['quantity'] ?? '').toString();
  }

  @override
  Widget build(BuildContext context) {
    final productName =
        move['product_id']?[1] ?? AppLocalizations.of(context).unknownProduct;
    final demandedQty = move['product_uom_qty'] ?? move['product_qty'];
    final uom = move['product_uom']?[1] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF714B67).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory, color: Color(0xFF714B67)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${AppLocalizations.of(context).unit}: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        uom,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context).demand,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '$demandedQty',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          onFieldSubmitted: (value) async {
                            final quantity =
                                double.tryParse(_quantityController.text) ??
                                    0.0;
                            final demand =
                                double.tryParse(demandedQty.toString()) ?? 0.0;
                            await context
                                .read<DeliveryOrderDetailCubit>()
                                .updateMoveQuantityOrDemand(
                                  move['id'],
                                  quantity,
                                  demand,
                                );
                            FocusScope.of(context).unfocus();
                            context
                                .read<DeliveryOrderDetailCubit>()
                                .fetchDetail(state.detail['id']);
                          },
                          enabled: state.detail['state'] != 'done',
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context).quantity,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                          ),
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
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

    return Column(
      children: [
        if (picking['state']?.toString() == 'assigned')
          if (isAvailable)
            _buildActionButton(
              context,
              AppLocalizations.of(context).validateOrder,
              Icons.check_circle,
              const Color(0xFF714B67),
              () => _validateOrder(context),
            ),
        if (picking['state']?.toString() == 'assigned' && !isAvailable) ...[
          _buildActionButton(
            context,
            AppLocalizations.of(context).createBackorder,
            Icons.reply_all,
            Colors.blue,
            () => context
                .read<DeliveryOrderDetailCubit>()
                .validate_With_BackOrder(pickingId),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            AppLocalizations.of(context).validateWithoutBackorder,
            Icons.warning_amber_rounded,
            Colors.orange,
            () => context
                .read<DeliveryOrderDetailCubit>()
                .validate_without_backOrder(pickingId),
            isOutlined: true,
          ),
        ],
      ],
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
      height: 48,
      child: isOutlined
          ? OutlinedButton.icon(
              icon: Icon(icon, color: color, size: 20),
              label: Text(text),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onPressed,
            )
          : ElevatedButton.icon(
              icon: Icon(
                icon,
                size: 20,
                color: Colors.white,
              ),
              label: Text(
                text,
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
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
      await context.read<DeliveryOrderDetailCubit>().validateOrder(pickingId);
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
