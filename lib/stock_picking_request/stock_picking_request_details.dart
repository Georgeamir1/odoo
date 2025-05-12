import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../localization.dart';
import '../networking/odoo_service.dart';
import 'add_stock_picking_line.dart';
import 'stock_picking_request_cubit.dart';
import 'stock_picking_request_status.dart';
import 'stock_picking_request_ui.dart';

class StockPickingRequestDetailPage extends StatelessWidget {
  final int pickingId;
  const StockPickingRequestDetailPage({
    Key? key,
    required this.pickingId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StockPickingRequestCubit()..fetchDetail(pickingId),
      child: BlocConsumer<StockPickingRequestCubit, StockPickingRequestState>(
        listener: (context, state) {
          if (state is ValidationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).validationSuccess),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is ValidationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is NoBackOrderValidationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)
                    .validationWithoutBackorderSuccess),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is NoBackOrderValidationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is NavigateToStockPickingRequestPage) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const StockPickingRequestPage(),
              ),
            );
          }
        },
        builder: (context, state) {
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
                  iconTheme: const IconThemeData(color: Colors.white),
                  title: Text(
                    AppLocalizations.of(context).Transefer_Requests,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
              ),
            ),
            body: _buildBody(context, state),
            /*  bottomNavigationBar: state is StockPickingRequestDetailLoaded
                ? _buildBottomBar(context, state)
                : null,*/
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, StockPickingRequestState state) {
    if (state is StockPickingRequestDetailLoading) {
      return Center(
        child: Lottie.asset(
          'assets/images/loading.json',
          width: 200,
          height: 200,
          fit: BoxFit.fill,
        ),
      );
    } else if (state is StockPickingRequestDetailError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<StockPickingRequestCubit>().fetchDetail(pickingId);
              },
              child: Text(AppLocalizations.of(context).tryAgain),
            ),
          ],
        ),
      );
    } else if (state is StockPickingRequestDetailLoaded) {
      return _buildDetailContent(context, state);
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildDetailContent(
      BuildContext context, StockPickingRequestDetailLoaded state) {
    final detail = state.detail;
    final name = detail['name'] ?? '';

    final requestState = detail['state'] ?? '';
    final approved_by = detail['approved_by'] != false
        ? detail['approved_by'][1] ?? ''
        : AppLocalizations.of(context).notapproved;
    final requested_by = detail['create_uid'][1] ?? '';
    final create_date = detail['create_date'] != false
        ? DateTime.parse(detail['create_date'])
        : null;
    final closed_date = detail['closed_date'] != false
        ? DateTime.parse(detail['closed_date'])
        : null;
    final warehouse = detail['warehouse'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      _buildStatusChip(context, requestState),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    AppLocalizations.of(context).requested_by,
                    requested_by,
                  ),
                  const SizedBox(height: 8),
                  if (warehouse != null &&
                      warehouse != false &&
                      warehouse.toString().isNotEmpty) ...[
                    _buildInfoRow(
                      AppLocalizations.of(context).warehouse,
                      warehouse,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (create_date != null) ...[
                    _buildInfoRow(
                      AppLocalizations.of(context).create_date,
                      _formatDate(create_date),
                    ),
                    const SizedBox(height: 8),
                    /*    _buildInfoRow(
                        AppLocalizations.of(context).approved_by, approved_by),*/
                    const SizedBox(height: 8),
                    if (closed_date != null) ...[
                      _buildInfoRow(
                        AppLocalizations.of(context).closed_date,
                        _formatDate(closed_date),
                      ),
                    ]
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: detail['product_lines'].length,
            itemBuilder: (context, index) {
              final move = detail['product_lines'][index];
              final productId = move['product_id'];
              final productName = productId is List && productId.length > 1
                  ? productId[1]
                  : 'Unknown Product';
              final demandedQty = move['quantity'] ?? 0.0;
              // Handle case where quantity_done might not be available in the model
              final moveId = move['id'];
              final moveState = move['state'];

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          /*  if (moveState != 'done' &&
                              moveState != 'cancel' &&
                              requestState != 'done' &&
                              requestState != 'cancel')
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteConfirmation(
                                    context, moveId, productName);
                              },
                              tooltip: 'Remove Line',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),*/
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${AppLocalizations.of(context).demand}: $demandedQty',
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildBottomBar(
      BuildContext context, StockPickingRequestDetailLoaded state) {
    final detail = state.detail;
    final requestState = detail['state'] ?? '';

    if (requestState == 'done' || requestState == 'cancel') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (requestState == 'draft' || requestState == 'confirmed') ...[
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  context
                      .read<StockPickingRequestCubit>()
                      .updateRequestStatus(pickingId, 'assigned');
                },
                child: Text(AppLocalizations.of(context).checkAvailability),
              ),
            ),
          ] else if (requestState == 'assigned') ...[
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  _showValidationOptions(context);
                },
                child: Text(AppLocalizations.of(context).validate),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showValidationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context).validationOptions,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(AppLocalizations.of(context).validateWithBackorder),
                subtitle: Text(AppLocalizations.of(context)
                    .validateWithBackorderDescription),
                onTap: () {
                  Navigator.pop(context);
                  context
                      .read<StockPickingRequestCubit>()
                      .validateRequest(pickingId);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: Text(AppLocalizations.of(context)
                    .validateWithoutBackorderOption),
                subtitle: Text(AppLocalizations.of(context)
                    .validateWithoutBackorderDescription),
                onTap: () {
                  Navigator.pop(context);
                  context
                      .read<StockPickingRequestCubit>()
                      .validateWithoutBackorder(pickingId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, String state) {
    Color chipColor;
    String statusText;

    switch (state) {
      case 'draft':
        chipColor = Colors.grey;
        statusText = AppLocalizations.of(context).draft;
        break;
      case 'waiting':
        chipColor = Colors.orange;
        statusText = AppLocalizations.of(context).waiting;
        break;
      case 'confirmed':
        chipColor = Colors.blue;
        statusText = AppLocalizations.of(context).confirmed;
        break;
      case 'assigned':
        chipColor = Colors.green;
        statusText = AppLocalizations.of(context).ready;
        break;
      case 'done':
        chipColor = Colors.purple;
        statusText = AppLocalizations.of(context).done;
        break;
      case 'cancel':
        chipColor = Colors.red;
        statusText = AppLocalizations.of(context).cancelled;
        break;
      default:
        chipColor = Colors.grey;
        statusText = state;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

/*
  void _showDeleteConfirmation(
      BuildContext context, int moveId, String productName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).confirmDeletion),
        content: Text(AppLocalizations.of(context)
            .confirmRemoveProduct
            .replaceAll('%s', productName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context
                  .read<StockPickingRequestCubit>()
                  .removeProductLine(pickingId, moveId);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(AppLocalizations.of(context).productLineRemoved),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context).remove),
          ),
        ],
      ),
    );
  }
*/
}
