import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../localization.dart';
import '../networking/odoo_service.dart';
import 'invoicing_cubit.dart';
import 'invoicing_status.dart';
import 'invoicing_list.dart';

// Map to store product quantities for stock returns
Map<int, double> productQuantities = {};

class EditReversedInvoicePage extends StatelessWidget {
  final int invoiceId;

  const EditReversedInvoicePage({
    Key? key,
    required this.invoiceId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              invoicingdetailsCubit(OdooRpcService())..fetchDetail(invoiceId),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            AppLocalizations.of(context).edit_reversed_invoice,
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
                  color: Colors.black.withAlpha(51),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
        body: BlocConsumer<invoicingdetailsCubit, invoicingdetailsState>(
          listener: (context, state) {
            if (state is invoicingUpdateSuccess) {
              _showSnackBar(
                context,
                AppLocalizations.of(context).update_success,
                Colors.green,
              );
              BlocProvider.of<invoicingdetailsCubit>(context)
                  .fetchDetail(invoiceId);
            } else if (state is invoicingPostSuccess) {
              _showSnackBar(
                context,
                AppLocalizations.of(context).post_success,
                Colors.green,
              );
              // No navigation here - we'll handle it after stock return creation
            } else if (state is invoicingReturnSuccess) {
              _showSnackBar(
                context,
                "Stock return created successfully",
                Colors.green,
              );
              // Automatically navigate back after success
              Future.delayed(const Duration(seconds: 1), () {
                Navigator.pop(context);
              });
            } else if (state is NavigateToinvoicingdetailsPage) {
              // Automatically navigate to invoicing page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => invoicingPage(),
                ),
              );
            } else if (state is invoicingdetailsError) {
              _showSnackBar(
                context,
                state.message,
                Colors.red,
              );
            }
          },
          builder: (context, state) {
            if (state is invoicingdetailsLoading) {
              return _buildLoadingState(context);
            } else if (state is invoicingdetailsError) {
              return _buildErrorState(context, state.message);
            } else if (state is invoicingdetailsLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  await BlocProvider.of<invoicingdetailsCubit>(context)
                      .fetchDetail(invoiceId);
                },
                child: _buildContent(state, context),
              );
            }
            // Improved loading state to avoid blank white screen
            return _buildLoadingState(context);
          },
        ),
        bottomNavigationBar:
            BlocBuilder<invoicingdetailsCubit, invoicingdetailsState>(
          builder: (context, state) {
            if (state is invoicingdetailsLoaded) {
              return _buildBottomButtons(context, state);
            }
            return const SizedBox.shrink(); // No bottom bar for other states
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/images/loading3.json',
                width: 120, height: 120),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).loadingOrderDetails,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF714B67),
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Please wait while we prepare your invoice...",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context).errorLoadingOrder,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withAlpha(100)),
                ),
                child: Text(
                  message,
                  style: TextStyle(color: Colors.red.shade700),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  BlocProvider.of<invoicingdetailsCubit>(context)
                      .fetchDetail(invoiceId);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF714B67),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(invoicingdetailsLoaded state, BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InvoiceHeaderCard(detail: state.detail, picking: state.picking),
          const SizedBox(height: 16),
          _InvoiceLinesList(
            moves: state.detail['moves'],
            invoiceId: invoiceId,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(
      BuildContext context, invoicingdetailsLoaded state) {
    final cubit = BlocProvider.of<invoicingdetailsCubit>(context);
    final isPosted = state.picking['state'] == 'posted';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26), // Equivalent to opacity 0.1
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.save, color: Colors.white),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          backgroundColor: isPosted ? Colors.grey : Color(0xFF714B67),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: isPosted
            ? null
            : () async {
                _showLoadingOverlay(context, 'Saving and processing...');

                try {
                  // First save any changes to quantities
                  await cubit.saveInvoiceChanges(invoiceId);

                  // Then post the invoice
                  await cubit.postInvoice(invoiceId);
                  final deliveryOrderId =
                      await cubit.fetchDeliveryOrderIdFromInvoice(invoiceId);

                  if (deliveryOrderId != null) {
                    await cubit.createStockReturn(
                        deliveryOrderId, productQuantities);
                  } else {
                    print('No delivery order found for invoice ID: $invoiceId');
                  }

                  // Close lo ading overlay
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  // Close loading overlay on error
                  if (context.mounted) {
                    Navigator.pop(context);
                    _showSnackBar(
                      context,
                      "Error: ${e.toString()}",
                      Colors.red,
                    );
                  }
                }
              },
        label: Text(
          AppLocalizations.of(context).save_and_post,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLoadingOverlay(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InvoiceHeaderCard extends StatelessWidget {
  final Map<String, dynamic> detail;
  final Map<String, dynamic> picking;

  const _InvoiceHeaderCard({required this.detail, required this.picking});

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
                Expanded(
                  child: Text(
                    detail['partner_id'] == false
                        ? AppLocalizations.of(context).unknown_customer
                        : detail['partner_id'][1],
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold, color: Color(0xFF714B67)),
                  ),
                ),
                _buildStatusChip(picking['state']),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.timelapse, AppLocalizations.of(context).date,
                "${DateTime.parse(detail['date']).day} / ${DateTime.parse(detail['date']).month} / ${DateTime.parse(detail['date']).year}"),
            _buildInfoRow(
                Icons.description,
                AppLocalizations.of(context).sourceDocument,
                "${detail['name'] ?? AppLocalizations.of(context).notAvailable}"),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final statusConfig = _getStatusConfig(status);
    return Chip(
      label: Text(status.toUpperCase()),
      backgroundColor: statusConfig.color.withAlpha(51),
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
      case 'posted':
        return _StatusConfig(Colors.green, Icons.check_circle);
      case 'canceled':
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

class _InvoiceLinesList extends StatelessWidget {
  final List<dynamic> moves;
  final int invoiceId;

  const _InvoiceLinesList({required this.moves, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    final productLines = moves
        .where((move) =>
            move['display_type'] == 'product' || move['display_type'] == null)
        .where(
            (move) => move['product_id'] != false && move['product_id'] != null)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '${AppLocalizations.of(context).products} (${productLines.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
          ),
        ),
        const SizedBox(height: 12),
        ...productLines
            .map((move) => _InvoiceLineItem(
                  move: move,
                  invoiceId: invoiceId,
                ))
            .toList(),
      ],
    );
  }
}

class _InvoiceLineItem extends StatefulWidget {
  final dynamic move;
  final int invoiceId;

  const _InvoiceLineItem({required this.move, required this.invoiceId});

  @override
  _InvoiceLineItemState createState() => _InvoiceLineItemState();
}

class _InvoiceLineItemState extends State<_InvoiceLineItem> {
  late TextEditingController _quantityController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final quantity = widget.move['quantity'] ?? 1.0;
    _quantityController = TextEditingController(text: quantity.toString());

    // Initialize the product quantity in the global map
    if (widget.move['product_id'] is List &&
        widget.move['product_id'].length > 1) {
      final productId = widget.move['product_id'][0];
      productQuantities[productId] = quantity;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _saveQuantity() {
    if (!mounted) return;

    final newQuantity = double.tryParse(_quantityController.text) ?? 0.0;
    if (newQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).invalidQuantity),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show saving indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 16),
            Text("Updating quantity..."),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );

    // Use the cubit to update the quantity
    BlocProvider.of<invoicingdetailsCubit>(context).updateInvoiceLineQuantity(
      widget.invoiceId,
      widget.move['id'],
      newQuantity,
    );

    setState(() {
      _isEditing = false;
      widget.move['quantity'] = newQuantity;

      // Store the quantity in the global map for stock returns
      if (widget.move['product_id'] is List &&
          widget.move['product_id'].length > 1) {
        final productId = widget.move['product_id'][0];
        productQuantities[productId] = newQuantity;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final productName = (widget.move['product_id'] is List &&
            widget.move['product_id'].length > 1)
        ? widget.move['product_id'][1]
        : AppLocalizations.of(context).unknownProduct;

    final priceUnit =
        (widget.move['price_unit'] is num ? widget.move['price_unit'] : 0.0)
            .toStringAsFixed(2);

    final priceSubtotal = (widget.move['price_subtotal'] is num
            ? widget.move['price_subtotal']
            : 0.0)
        .toStringAsFixed(2);

    final quantity = widget.move['quantity'] ?? 0.0; // Ensure correct quantity

    return BlocListener<invoicingdetailsCubit, invoicingdetailsState>(
        listenWhen: (previous, current) {
          // Only listen for update success events
          return current is invoicingUpdateSuccess;
        },
        listener: (context, state) {
          if (state is invoicingUpdateSuccess) {
            // Update was successful, we could update the UI if needed
          }
        },
        child: Card(
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

                // Quantity Editor
                Row(
                  children: [
                    Icon(Icons.format_list_numbered,
                        size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      "${AppLocalizations.of(context).quantity}: ",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Expanded(
                      child: _isEditing
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _quantityController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check,
                                      color: Colors.green),
                                  onPressed: _saveQuantity,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = false;
                                      _quantityController.text = quantity
                                          .toString(); // Reset to correct value
                                    });
                                  },
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  quantity
                                      .toString(), // Display correct quantity
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Color(0xFF714B67)),
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = true;
                                    });
                                  },
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Price Info
                Row(
                  children: [
                    Icon(Icons.attach_money,
                        size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      "${AppLocalizations.of(context).unit_price}: ",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      "\$$priceUnit",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Subtotal
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context).subtotal,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        '\$$priceSubtotal',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF714B67),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
