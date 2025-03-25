import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo/sales_order/sales_order_cubit.dart';
import 'package:odoo/sales_order/sales_order_status.dart';

import '../InventoryReceipts/new_inventory_receipt.dart';
import '../localization.dart';

class newdeliveryorderScreen extends StatefulWidget {
  const newdeliveryorderScreen({Key? key}) : super(key: key);

  @override
  State<newdeliveryorderScreen> createState() => _newdeliveryorderState();
}

class _newdeliveryorderState extends State<newdeliveryorderScreen> {
  final _expirationDateController = TextEditingController();
  final _dateController = TextEditingController();
  var customerId;
  var paymentTermId;
  var paymentTermName;
  var payment_term;

  List<OrderLine> _orderLines = [OrderLine()];

  @override
  void dispose() {
    _expirationDateController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  double _calculateTotalPrice() {
    return _orderLines.fold(0, (total, line) {
      return total + line.totalPrice;
    });
  }

  double _calculateTotalPriceWithTaxes() {
    return _orderLines.fold(0, (total, line) {
      return total + line.totalPriceWithTax;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => PartnersCubit()..getPartners()),
        BlocProvider(create: (context) => ProductsCubit()..getProducts()),
        BlocProvider(create: (context) => PaymentTermCubit()..getPaymentTerm()),
        BlocProvider(create: (context) => TaxesCubit()..getTaxes()),
        BlocProvider(create: (context) => SaleOrderCubit()),
      ],
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize:
              Size.fromHeight(70.0), // Increased height for a premium feel
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFF714B67),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: AppBar(
              title: Text(
                AppLocalizations.of(context).deliveryOrder,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20, // Increased font size
                  fontWeight: FontWeight.bold, // Bold for better readability
                  letterSpacing: 1.2, // Spacing for a premium look
                ),
              ),
              centerTitle: true, // Center title for better alignment
              backgroundColor:
                  Colors.transparent, // Transparent to show gradient
              elevation: 0, // No extra shadow
              iconTheme: IconThemeData(color: Colors.white), // White icon color
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCustomerSelection(),
              const SizedBox(height: 16),
              _buildPaymentTermsSelection(),
              const SizedBox(height: 16),
              _buildOrderLinesSection(),
              const SizedBox(height: 16),
              _buildTotalPriceSection(),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerSelection() {
    return BlocBuilder<PartnersCubit, PartnersState>(
      builder: (context, state) {
        if (state is PartnersLoadingState) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is PartnersErrorState) {
          return Center(child: Text("${state.error}"));
        } else if (state is PartnersLoadedState) {
          return _buildDropdown(
            title: AppLocalizations.of(context).customer,
            value: state.selectedCustomer,
            items: state.partners
                .map((customer) => customer['name'] as String)
                .toList(),
            onChanged: (value) {
              final selectedCustomer = state.partners.firstWhere(
                (customer) => customer['name'] == value,
                orElse: () => {},
              );

              if (selectedCustomer.isNotEmpty) {
                customerId = selectedCustomer['id'].toString();
                final customerName = selectedCustomer['name'];

                PartnersCubit.get(context)
                    .setSelectedCustomer(customerId, customerName);
              }
            },
          );
        } else {
          return const Center(child: Text("No customers found"));
        }
      },
    );
  }

  Widget _buildPaymentTermsSelection() {
    return BlocBuilder<PaymentTermCubit, PaymentTermState>(
      builder: (context, state) {
        if (state is PaymentTermLoadingState) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is PaymentTermErrorState) {
          return Center(child: Text("${state.error}"));
        } else if (state is PaymentTermLoadedState) {
          return _buildDropdown(
              title: AppLocalizations.of(context).payment_terms,
              value: state.selectedPaymentTerm,
              items: state.paymentTerm
                  .map<String>((type) => type['name'] as String)
                  .toList(),
              onChanged: (value) {
                final selectedpaymentTerm = state.paymentTerm.firstWhere(
                  (customer) => customer['name'] == value,
                  orElse: () => {},
                );
                if (selectedpaymentTerm.isNotEmpty) {
                  paymentTermId = selectedpaymentTerm['id'].toString();
                  paymentTermName = selectedpaymentTerm['name'];

                  PaymentTermCubit.get(context)
                      .setSelectedPaymentTerm(customerId, paymentTermName);
                }
              });
        } else {
          return const Center(child: Text("No payment terms found"));
        }
      },
    );
  }

  Widget _buildOrderLinesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).receipt_lines,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Column(
          children: _orderLines
              .asMap()
              .entries
              .map((entry) => _buildOrderLine(entry.key))
              .toList(),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.add, color: Color(0xFF00A09D)), // Odoo teal
            label: Text(
              AppLocalizations.of(context).add_line,
              style: TextStyle(color: Color(0xFF00A09D)), // Odoo teal
            ),
            onPressed: () => setState(() => _orderLines.add(OrderLine())),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderLine(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BlocBuilder<ProductsCubit, ProductsState>(
                builder: (context, state) {
                  if (state is ProductsLoadingState) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ProductsErrorState) {
                    return Center(child: Text("${state.error}"));
                  } else if (state is ProductsLoadedState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDropdown(
                          title: AppLocalizations.of(context).product,
                          value: state.Products.any((product) =>
                                  product['name'] ==
                                  _orderLines[index].selectedProduct)
                              ? _orderLines[index].selectedProduct
                              : null,
                          items: state.Products.map(
                              (product) => product['name'] as String).toList(),
                          onChanged: (value) => setState(() {
                            var selectedProduct = state.Products.firstWhere(
                              (product) => product['name'] == value,
                            );

                            _orderLines[index].selectedProduct = value;
                            _orderLines[index].unitPrice =
                                selectedProduct['list_price'];
                            _orderLines[index].productId = selectedProduct[
                                'product_variant_ids']; // Store product ID
                            _orderLines[index].productId =
                                selectedProduct['product_variant_ids']
                                    [0]; // Available quantity
                            _orderLines[index].unitId = selectedProduct[
                                    'uom_id'] ??
                                1; // Store UoM ID (defaults to 1 if missing)
                          }),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            '${AppLocalizations.of(context).available_quantity}${_orderLines[index].StocQuantitiy ?? 0}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF714B67),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return const Center(child: Text("No products found"));
                  }
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: AppLocalizations.of(context).quantity,
                      keyboardType: TextInputType.number,
                      onChanged: (val) =>
                          _orderLines[index].quantity = double.tryParse(val),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: AppLocalizations.of(context).unit_price,
                      keyboardType: TextInputType.number,
                      onChanged: (val) =>
                          _orderLines[index].unitPrice = double.tryParse(val),
                      controller: TextEditingController(
                          text: _orderLines[index].unitPrice?.toString() ?? ''),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              BlocConsumer<TaxesCubit, TaxesState>(
                listener: (context, state) {},
                builder: (context, state) {
                  if (state is TaxesLoadingState) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is TaxesErrorState) {
                    return Center(child: Text("${state.error}"));
                  } else if (state is TaxesLoadedState) {
                    return _buildDropdown(
                      title: AppLocalizations.of(context).taxes,
                      value: state.taxes.any((tax) =>
                              tax['name'] == _orderLines[index].selectedTax)
                          ? _orderLines[index].selectedTax
                          : null,
                      onChanged: (value) => setState(() {
                        var selectedTax = state.taxes.firstWhere(
                          (tax) => tax['name'] == value,
                        );

                        _orderLines[index].selectedTax = value;
                        _orderLines[index].taxAmount = selectedTax['amount'];
                        _orderLines[index].taxId =
                            selectedTax['id']; // Store tax ID
                      }),
                      items: state.taxes
                          .map((tax) => tax['name'] as String)
                          .toList(),
                    );
                  } else {
                    return const Center(child: Text("No taxes found"));
                  }
                },
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppLocalizations.of(context).tax}: \$${_orderLines[index].tax.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    '${AppLocalizations.of(context).total_price_with_tax}: \$${_orderLines[index].totalPriceWithTax.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF714B67),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => _orderLines.removeAt(index)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalPriceSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppLocalizations.of(context).total_price}: \$${_calculateTotalPrice().toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '${AppLocalizations.of(context).total_price_with_tax}: \$${_calculateTotalPriceWithTaxes().toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00A09D), // Odoo teal
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: BlocConsumer<SaleOrderCubit, SaleOrderState>(
            listener: (context, state) {
              if (state is SaleOrderSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text("Order created: ${state.saleOrderId}")),
                );
              } else if (state is SaleOrderError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${state.message}")),
                );
              }
            },
            builder: (context, state) {
              bool isLoading = state is SaleOrderLoading; // Check loading state

              return ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (customerId == null || _orderLines.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Please select a customer and add order lines.")),
                          );

                          return;
                        }

                        // Check if all order lines are valid
                        for (var line in _orderLines) {
                          if (line.productId == null ||
                              line.quantity == null ||
                              line.unitId == null) {
                            print(jsonEncode(line.toJson()));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      "Invalid order line: ${jsonEncode(line.toJson())}")),
                            );
                            return;
                          }
                        }

                        try {
                          final cubit = SaleOrderCubit.get(context);
                          cubit.createAndConfirmStockPicking(
                            partnerId: int.parse(customerId.toString()),
                            pickingTypeId: 2, // Change if needed
                            locationId: 5, // Update dynamically if needed
                            locationDestId: 8, // Update dynamically if needed
                            orderLines: _orderLines,
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: ${e.toString()}")),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF714B67)),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(AppLocalizations.of(context).save,
                        style: TextStyle(color: Colors.white)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String title,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    // Ensure the value exists in the items list
    final validValue = items.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: validValue, // Use the validated value
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          hint: Text('${AppLocalizations.of(context).select} $title'),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onChanged: onChanged,
    );
  }
}
