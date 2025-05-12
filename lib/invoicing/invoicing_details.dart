import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../delivery_order/delivery_order_cubit.dart';
import '../localization.dart';
import '../networking/odoo_service.dart';
import '../sales_order/sales_order_cubit.dart';
import '../testttt.dart';
import 'edit_reversed_invoice.dart';
import 'invoicing_cubit.dart';
import 'invoicing_list.dart';
import 'invoicing_status.dart';

class InvoicingDetailsPage extends StatelessWidget {
  final int pickingId;
  const InvoicingDetailsPage({
    Key? key,
    required this.pickingId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              invoicingdetailsCubit(OdooRpcService())..fetchDetail(pickingId),
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
            AppLocalizations.of(context).invoicesdetails,
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            BlocBuilder<invoicingdetailsCubit, invoicingdetailsState>(
              builder: (context, state) {
                if (state is invoicingdetailsLoaded) {
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
                // Navigation for reversed invoice is handled in the BlocListener
                return Center(
                  child: Text(
                    AppLocalizations.of(context).notAvailable,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            )
          ],
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
                  color: Colors.black
                      .withAlpha(51), // 51 is approximately 0.2 * 255
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
        body: BlocListener<invoicingdetailsCubit, invoicingdetailsState>(
          listener: (context, state) {
            if (state is invoicingdetailsvalidationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      AppLocalizations.of(context).orderValidatedSuccessfully),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
              // Automatically navigate back after success
              Navigator.pop(context);
            } else if (state is NavigateToinvoicingdetailsPage) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => invoicingPage(),
                ),
              );
            } else if (state is invoicingdetailsvalidationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('⚠️ ${state.message}'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else if (state is invoicingdetailsReversalSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      AppLocalizations.of(context).reverse_invoice_success),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );

              // Automatically navigate to the reversed invoice if we have a valid ID
              if (state.reversedInvoiceId != null) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditReversedInvoicePage(
                      invoiceId: state.reversedInvoiceId!,
                    ),
                  ),
                );
              }
            } else if (state is invoicingdetailsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('⚠️ ${state.message}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          child: BlocBuilder<invoicingdetailsCubit, invoicingdetailsState>(
            builder: (context, state) {
              if (state is invoicingdetailsLoading) {
                return _buildLoadingState(context);
              } else if (state is invoicingdetailsError) {
                return _buildErrorState(context, state.message);
              } else if (state is invoicingdetailsLoaded) {
                return _buildContent(state, context);
              }
              return _buildLoadingState(context); // Default to loading state
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

  Widget _buildContent(invoicingdetailsLoaded state, BuildContext context) {
    final notPaid = state.picking['amount_residual_signed']?.toDouble() ?? 0.0;
    final total = state.picking['amount_total']?.toDouble() ?? 0.0;
    final payments = state.picking['payment_ids'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _OrderHeaderCard(detail: state.detail, picking: state.picking),
          const SizedBox(height: 16),
          _ProductListSection(moves: state.detail['moves']),
          const SizedBox(height: 24),
          PaymentSection(
            saleOrderId: pickingId,
            detail: state.picking,
            notPaid:
                state.picking['payment_state'] == 'not_paid' ? total : notPaid,
            total: total,
            payments: payments,
          ),
        ],
      ),
    );
  }
}

class PaymentSection extends StatefulWidget {
  final int saleOrderId;
  final Map<String, dynamic> detail;
  final double notPaid;
  final double total;
  final List<dynamic> payments;

  const PaymentSection({
    super.key,
    required this.saleOrderId,
    required this.detail,
    required this.notPaid,
    required this.total,
    required this.payments,
  });

  @override
  _PaymentSectionState createState() => _PaymentSectionState();
}

class _PaymentSectionState extends State<PaymentSection> {
  final _formKey = GlobalKey<FormState>();
  final _reverseFormKey = GlobalKey<FormState>();
  double _paymentAmount = 0.0;
  bool _isProcessing = false;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _paymentAmount = widget.notPaid;
    _amountController.text = _paymentAmount.toStringAsFixed(2);

    // Initialize date controller with current date
    final now = DateTime.now();
    _dateController.text =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _showReverseInvoiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).reverse_invoice),
        content: Form(
          key: _reverseFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reason field
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context).reverse_invoice_reason,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a reason for reversal';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date field
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).reverse_invoice_date,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        _dateController.text =
                            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                      }
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a date';
                  }
                  // Simple date validation
                  final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                  if (!dateRegex.hasMatch(value)) {
                    return 'Please enter a valid date (YYYY-MM-DD)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF714B67),
            ),
            onPressed: () {
              if (_reverseFormKey.currentState!.validate()) {
                Navigator.pop(context);
                _processReverseInvoice();
              }
            },
            child: Text(AppLocalizations.of(context).reverse_invoice),
          ),
        ],
      ),
    );
  }

  Future<void> _processReverseInvoice() async {
    if (!mounted) return;

    setState(() => _isProcessing = true);

    try {
      // Create the reverse invoice - navigation will be handled by the BlocListener
      await BlocProvider.of<invoicingdetailsCubit>(context)
          .createReverseInvoice(
        widget.saleOrderId,
        _reasonController.text,
        _dateController.text,
      );

      if (mounted) {
        _reasonController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "❌ ${AppLocalizations.of(context).reverse_invoice_error}: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    setState(() => _isProcessing = true);

    try {
      final odoo = OdooRpcService();

      // 1. Ensure invoice is posted
      final invoice = await odoo.callKw({
        "model": "account.move",
        "method": "read",
        "args": [
          [widget.saleOrderId]
        ],
        "kwargs": {
          "fields": ["state"]
        }
      });
      final state = invoice.first['state'];
      if (state == 'draft') {
        await odoo.callKw({
          "model": "account.move",
          "method": "action_post",
          "args": [widget.saleOrderId],
          "kwargs": {
            "context": {
              "validate_analytic": true,
            }
          },
        });
      }

      // 2. Create payment wizard
      final registerId = await odoo.callKw({
        "model": "account.payment.register",
        "method": "create",
        "args": [
          {
            "journal_id": 7,
            "amount": _paymentAmount,
          }
        ],
        "kwargs": {
          "context": {
            "active_model": "account.move",
            "payment_type": "inbound",
            "active_ids": [widget.saleOrderId],
            "journal_id": 7,
            "payment_method_line_id": 1,
            "amount": _paymentAmount,
            "date": widget.detail['date'] ?? DateTime.now().toString(),
            "communication": widget.detail['name'] ?? "Invoice Payment",
            "dont_redirect_to_payments": true,
          }
        }
      });

      if (registerId == null) {
        throw Exception("Failed to create payment wizard");
      }

      // 3. Process payment
      await odoo.callKw({
        "model": "account.payment.register",
        "method": "action_create_payments",
        "args": [
          [registerId]
        ],
        "kwargs": {
          "context": {
            "active_model": "account.move",
            "active_ids": [widget.saleOrderId],
            "force_reconcile": true,
            "dont_redirect_to_payments": true,
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "✅ Payment of \$${_paymentAmount.toStringAsFixed(2)} processed successfully!"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Refresh the data and navigate back after success
        await BlocProvider.of<invoicingdetailsCubit>(context)
            .fetchDetail(widget.saleOrderId);

        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Payment error: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF714B67),
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Summary
                  _buildPaymentSummaryRow('Total Amount', widget.total),
                  _buildPaymentSummaryRow(
                    'Amount Due',
                    widget.notPaid,
                    isDue: true,
                  ),
                  const SizedBox(height: 16),

                  // Payment Amount Input
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Payment Amount',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          setState(() {
                            _paymentAmount = widget.notPaid;
                            _amountController.text =
                                _paymentAmount.toStringAsFixed(2);
                          });
                        },
                      ),
                    ),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter payment amount';
                      }
                      final amount = double.tryParse(value) ?? 0;

                      if (amount > widget.notPaid * 1.1) {
                        return 'Amount cannot exceed 110% of remaining balance';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _paymentAmount = double.tryParse(value) ?? 0;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Quick Payment Buttons
                  if (widget.notPaid > 0) ...[
                    Text(
                      'Quick Payment:',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickPaymentButton(0.25),
                        _buildQuickPaymentButton(0.5),
                        _buildQuickPaymentButton(0.75),
                        _buildQuickPaymentButton(1.0),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Process Payment Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF714B67),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: widget.detail['payment_state'] == 'not_paid' ||
                              widget.detail['payment_state'] == 'partial'
                          ? _processPayment
                          : null,
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              widget.detail['payment_state'] == 'paid'
                                  ? 'Fully Paid'
                                  : 'Process Payment',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  // Reverse Invoice Button
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFF714B67)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.undo, color: Color(0xFF714B67)),
                      onPressed: widget.detail['state'] == 'posted'
                          ? _showReverseInvoiceDialog
                          : null,
                      label: Text(
                        AppLocalizations.of(context).reverse_invoice,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF714B67),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummaryRow(String label, double value,
      {bool isDue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDue ? Colors.red : const Color(0xFF714B67),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPaymentButton(double percentage) {
    final amount = (widget.notPaid * percentage).toStringAsFixed(2);
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () {
        setState(() {
          _paymentAmount = widget.notPaid * percentage;
          _amountController.text = _paymentAmount.toStringAsFixed(2);
        });
      },
      child: Text('${(percentage * 100).toInt()}% (\$$amount)'),
    );
  }
}

class _OrderHeaderCard extends StatelessWidget {
  final Map<String, dynamic> detail;
  final Map<String, dynamic> picking;

  const _OrderHeaderCard({required this.detail, required this.picking});

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
            _buildInfoRow(
              Icons.category,
              AppLocalizations.of(context).payment_terms,
              detail['payment_term_id'] == false
                  ? AppLocalizations.of(context).Immediate
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
      backgroundColor:
          statusConfig.color.withAlpha(51), // 51 is approximately 0.2 * 255
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

class _ProductListSection extends StatelessWidget {
  final List<dynamic> moves;

  const _ProductListSection({required this.moves});

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
        ...productLines.map((move) => _ProductListItem(move: move)).toList(),
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
        (move['product_id'] is List && move['product_id'].length > 1)
            ? move['product_id'][1]
            : AppLocalizations.of(context).unknownProduct;

    final priceUnit = (move['price_unit'] is num ? move['price_unit'] : 0.0)
        .toStringAsFixed(2);

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
                    AppLocalizations.of(context).tax,
                    "${move['l10n_gcc_invoice_tax_amount']}",
                    isBold: true,
                    color: const Color(0xFF714B67),
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
