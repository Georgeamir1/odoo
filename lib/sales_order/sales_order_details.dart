import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:odoo/InventoryReceipts/widgets.dart';
import 'package:odoo/delivery_order/delivery_order_ui.dart';
import 'package:odoo/sales_order/sales_order_cubit.dart';
import 'package:odoo/sales_order/sales_order_list.dart';
import 'package:odoo/sales_order/sales_order_status.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../delivery_order/delivery_order_cubit.dart';
import '../delivery_order/delivery_order_status.dart';
import '../invoicing/invoicing_cubit.dart';
import '../invoicing/invoicing_details.dart';
import '../localization.dart';
import '../networking/odoo_service.dart';
import '../testttt.dart';

class SaleOrderdetailsPage extends StatelessWidget {
  final int pickingId;
  const SaleOrderdetailsPage({
    Key? key,
    required this.pickingId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              SaleOrderdetailsCubit(OdooRpcService())..fetchDetail(pickingId),
        ),
        BlocProvider(
          create: (context) => TaxesCubit(),
        ),
        BlocProvider<DeliveryOrderDetailCubit>(
          create: (context) =>
              DeliveryOrderDetailCubit(OdooRpcService())..GetCompanyName(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            AppLocalizations.of(context).salesOrderDetails,
            style: const TextStyle(color: Colors.white),
          ),
          /*   actions: [
            BlocBuilder<SaleOrderdetailsCubit, SaleOrderdetailsState>(
              builder: (context, state) {
                if (state is SaleOrderdetailsLoaded) {
                  return IconButton(
                    icon: const Icon(Icons.print, color: Colors.white),

                    onPressed: () async {
                      await DeliveryOrderDetailCubit.get(context)
                          .GetCompanyName();
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      final orderData = {
                        'company_name':
                            DeliveryOrderDetailCubit.get(context).CompanyName1,
                        'user_name': prefs.getString('username'),
                        'customer_name':
                            state.picking['partner_id'][1] ?? 'N/A',
                        'username': 'Seller Name',
                        'items': state.detail['moves']
                                ?.map((move) => {
                                      'name': move['name'] ?? 'Unknown',
                                      'quantity': move['product_uom_qty'] ?? 0,
                                      'price': move['price_unit'] ?? 0,
                                    })
                                .toList() ??
                            [],
                        'total_before_vat': state.picking['amount_untaxed'],
                        'vat_amount': state.picking['amount_tax'],
                        'total_with_vat': state.picking['amount_total'],
                      };

                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          insetPadding: const EdgeInsets.all(16),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 500),
                            child: InVoicePrintScreen(orderData: orderData),
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            )
          ],*/
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
        body: BlocListener<SaleOrderdetailsCubit, SaleOrderdetailsState>(
          listener: (context, state) {
            if (state is SaleOrderdetailsvalidationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      AppLocalizations.of(context).orderValidatedSuccessfully),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is NavigateToSaleOrderdetailsPage) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SaleOrderPage(),
                ),
              );
            } else if (state is SaleOrderdetailsvalidationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('⚠️ ${state.message}'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          },
          child: BlocBuilder<SaleOrderdetailsCubit, SaleOrderdetailsState>(
            builder: (context, state) {
              print(pickingId);
              if (state is SaleOrderdetailsLoading) {
                return _buildLoadingState(context);
              } else if (state is SaleOrderdetailsError) {
                return _buildErrorState(context, state.message);
              } else if (state is SaleOrderdetailsLoaded) {
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

  Widget _buildContent(SaleOrderdetailsLoaded state, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _OrderHeaderCard(detail: state.detail),
          const SizedBox(height: 16),
          _ProductListSection(moves: state.detail['moves']),
          const SizedBox(height: 24),
          Text(
              "${state.detail['state'] ?? AppLocalizations.of(context).notAvailable}"),
          ViewInvoicesButton(saleOrderId: state.detail['invoice_ids']),
          CreateInvoiceButton(saleOrderId: pickingId)
        ],
      ),
    );
  }
}

class InvoicesListSheet extends StatelessWidget {
  final List<dynamic> saleOrderIds;

  const InvoicesListSheet({super.key, required this.saleOrderIds});

  Future<List<Map<String, dynamic>>> _fetchInvoices() async {
    final odoo = OdooRpcService();
    final result = await odoo.callKw({
      "model": "account.move",
      "method": "search_read",
      "args": [
        [
          ["id", "=", saleOrderIds],
          ["move_type", "=", "out_invoice"]
        ],
        ["name", "invoice_date", "amount_total", "state"]
      ],
      "kwargs": {"limit": 20},
      "context": {}
    });

    return (result as List).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('فواتير الطلب'),
        leading: const CloseButton(),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchInvoices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final invoices = snapshot.data ?? [];

          if (invoices.isEmpty) {
            return const Center(child: Text('لا توجد فواتير لهذا الطلب.'));
          }

          return ListView.separated(
            itemCount: invoices.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InvoicingDetailsPage(
                        pickingId: invoice['id'],
                      ),
                    ),
                  );
                },
                child: ListTile(
                  leading: const Icon(Icons.receipt),
                  title: Text(invoice['name'] ?? ''),
                  subtitle: Text('التاريخ: ${invoice['invoice_date'] ?? '—'}'),
                  trailing: Text('${invoice['amount_total'] ?? 0} د.أ'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ViewInvoicesButton extends StatelessWidget {
  final List<dynamic> saleOrderId;

  const ViewInvoicesButton({super.key, required this.saleOrderId});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.receipt),
      label: const Text("عرض الفواتير"),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => FractionallySizedBox(
            heightFactor: 0.85,
            child: InvoicesListSheet(
              saleOrderIds: saleOrderId,
            ),
          ),
        );
      },
    );
  }
}

class CreateInvoiceButton extends StatelessWidget {
  final int saleOrderId;

  const CreateInvoiceButton({super.key, required this.saleOrderId});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.receipt_long),
      label: const Text("إنشاء فاتورة مبدئية"),
      onPressed: () async {
        final odoo = OdooRpcService();

        final result = await odoo.callKw({
          "model": "sale.advance.payment.inv",
          "method": "create",
          "args": [
            {
              "advance_payment_method": "delivered",
              "deduct_down_payments": true,
              "consolidated_billing": true,
              "sale_order_ids": [saleOrderId]
            }
          ],
          'kwargs': {},
          "context": {
            "active_ids": [saleOrderId],
            "active_model": "sale.order"
          }
        });

        final result2 = await odoo.callKw({
          "model": "sale.advance.payment.inv",
          "method": "create_invoices",
          "args": [
            [result]
          ],
          'kwargs': {},
          "context": {}
        });

        await odoo.callKw({
          "model": "account.move",
          "method": "action_post",
          "args": [result2['res_id']],
          "kwargs": {},
          "context": {
            "validate_analytic": true,
            "disable_abnormal_invoice_detection": false
          }
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result2 != null
                  ? 'تم إنشاء الفاتورة بنجاح 🎉'
                  : 'فشل إنشاء الفاتورة'),
            ),
          );
        }
      },
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
                  detail['partner_id'] == false
                      ? AppLocalizations.of(context).unknown_customer
                      : detail['partner_id'][1],
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold, color: Color(0xFF714B67)),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.calendar_today,
                AppLocalizations.of(context).date, detail['date_order']),
            _buildInfoRow(
                Icons.timelapse,
                AppLocalizations.of(context).pricelist,
                "${detail['pricelist_id'] ?? AppLocalizations.of(context).notAvailable}"),
            _buildInfoRow(
                Icons.description,
                AppLocalizations.of(context).sourceDocument,
                "${detail['name'] ?? AppLocalizations.of(context).notAvailable}"),
            if (detail['payment_term_id'] != null)
              _buildInfoRow(
                Icons.category,
                AppLocalizations.of(context).operationType,
                detail['payment_term_id'] == false
                    ? AppLocalizations.of(context).immediate
                    : detail['payment_term_id'][1],
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
        move['name']?.toString() ?? AppLocalizations.of(context).unknownProduct;
    final quantity = move['product_uom_qty']?.toString() ?? '0';
    final quantityDelivered = move['qty_delivered']?.toString() ?? '0';
    final quantityInvoiced = move['qty_invoiced']?.toString() ?? '0';
    final unit = move['product_uom'] is List && move['product_uom'].length > 1
        ? move['product_uom'][1]?.toString() ?? ''
        : '';
    final priceUnit = (move['price_unit'] is num ? move['price_unit'] : 0.0)
        .toStringAsFixed(2);
    final tax =
        (move['price_tax'] is num ? move['price_tax'] : 0.0).toStringAsFixed(2);
    final priceTax =
        (move['price_tax'] is num ? move['price_tax'] : 0.0).toStringAsFixed(2);
    final discount =
        (move['discount'] is num ? move['discount'] : 0.0).toStringAsFixed(2);
    final priceSubtotal =
        (move['price_total'] is num ? move['price_total'] : 0.0)
            .toStringAsFixed(2);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
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
            // Product Name Row
            Row(
              children: [
                const Icon(Icons.shopping_bag, color: Color(0xFF714B67)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    productName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Main Details Grid
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildDetailItem(
                  context,
                  Icons.scale,
                  AppLocalizations.of(context).quantity,
                  '$quantity $unit',
                ),
                _buildDetailItem(
                  context,
                  Icons.local_shipping,
                  AppLocalizations.of(context).Delivered,
                  quantityDelivered,
                  Colors.green,
                ),
                _buildDetailItem(
                  context,
                  Icons.receipt,
                  AppLocalizations.of(context).invoiced,
                  quantityInvoiced,
                  Colors.blue,
                ),
                _buildDetailItem(
                  context,
                  Icons.attach_money,
                  AppLocalizations.of(context).unit_price,
                  '\$$priceUnit',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pricing Details Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildPricingRow(
                    context,
                    AppLocalizations.of(context).discount,
                    '$discount%',
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildPricingRow(
                    context,
                    AppLocalizations.of(context).tax,
                    tax == 'None' ? tax : '$tax (\$$priceTax)',
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildPricingRow(
                    context,
                    AppLocalizations.of(context).subtotal,
                    '\$$priceSubtotal',
                    isBold: true,
                    color: const Color(0xFF714B67),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    IconData icon,
    String title,
    String value, [
    Color? color,
  ]) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? Colors.grey.shade600),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color ?? Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPricingRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: color ?? Colors.grey.shade800,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
