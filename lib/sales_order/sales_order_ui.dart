import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo/sales_order/sales_order_cubit.dart';
import 'package:odoo/sales_order/sales_order_status.dart';
import 'package:shimmer/main.dart';

import '../localization.dart';

class QuotationScreen extends StatefulWidget {
  const QuotationScreen({Key? key}) : super(key: key);

  @override
  State<QuotationScreen> createState() => _QuotationScreenState();
}

class _QuotationScreenState extends State<QuotationScreen> {
  final _expirationDateController = TextEditingController();
  final _dateController = TextEditingController();
  var customerId;
  var pricelist;
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
        BlocProvider(create: (context) => PricelistCubit()),
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
                AppLocalizations.of(context).order,
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
              /* _buildPaymentTermsSelection(),
              const SizedBox(height: 16),*/
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
          final customers = state.partners;
          if (customers.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context).no_customers_found),
            );
          }

          return Autocomplete<String>(
            displayStringForOption: (option) => option,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return customers.map((c) => c['name'] as String).toList();
              }
              return customers
                  .map((c) => c['name'] as String)
                  .where((name) => name
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()))
                  .toList();
            },
            onSelected: (String selection) {
              final selectedCustomer = customers.firstWhere(
                (customer) => customer['name'] == selection,
                orElse: () => {},
              );

              if (selectedCustomer.isNotEmpty) {
                customerId = selectedCustomer['id'].toString();
                pricelist = selectedCustomer['property_product_pricelist'][0];
                print(pricelist);
                final customerName = selectedCustomer['name'];
                PartnersCubit.get(context)
                    .setSelectedCustomer(customerId, customerName);
              }
            },
            fieldViewBuilder:
                (context, textEditingController, focusNode, onFieldSubmitted) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).customer,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText:
                          "${AppLocalizations.of(context).select} ${AppLocalizations.of(context).customer}",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: textEditingController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                textEditingController.clear();
                                PartnersCubit.get(context)
                                    .setSelectedCustomer(null, null);
                              },
                            )
                          : null,
                    ),
                  ),
                ],
              );
            },
          );
        } else {
          return Center(
            child: Text(AppLocalizations.of(context).no_customers_found),
          );
        }
      },
    );
  }

  /*Widget _buildPaymentTermsSelection() {
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
                  print(paymentTermId);
                  print(paymentTermId);
                  PaymentTermCubit.get(context)
                      .setSelectedPaymentTerm(customerId, paymentTermName);
                }
              });
        } else {
          return Center(
              child: Text(AppLocalizations.of(context).no_payment_terms_found));
        }
      },
    );
  }*/

  Widget _buildOrderLinesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).order_lines,
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
                    if (state.Products.isEmpty) {
                      return Center(
                          child: Text(
                              AppLocalizations.of(context).no_products_found));
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).product,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Autocomplete<String>(
                          displayStringForOption: (option) => option,
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return state.Products.map(
                                      (product) => product['name'] as String)
                                  .toList();
                            }
                            return state.Products.map(
                                    (product) => product['name'] as String)
                                .where((name) => name.toLowerCase().contains(
                                    textEditingValue.text.toLowerCase()))
                                .toList();
                          },
                          onSelected: (String selection) {
                            setState(() {
                              _orderLines[index].selectedProduct = selection;
                              var selectedProduct = state.Products.firstWhere(
                                (product) => product['name'] == selection,
                              );
                              _orderLines[index].productId =
                                  selectedProduct['product_variant_ids'][0];
                              _orderLines[index].PriceProductId =
                                  selectedProduct['id'];
                              print(_orderLines[index].PriceProductId);

                              // استدعاء PricelistCubit لجلب السعر بناءً على pricelist و product_id
                              if (pricelist != null &&
                                  _orderLines[index].productId != null) {
                                context.read<PricelistCubit>().getProductPrice(
                                      pricelist,
                                      _orderLines[index].PriceProductId!,
                                    );
                              }
                            });
                          },
                          fieldViewBuilder: (context, textEditingController,
                              focusNode, onFieldSubmitted) {
                            // Initialize controller with current value
                            if (_orderLines[index].selectedProduct != null) {
                              textEditingController.text =
                                  _orderLines[index].selectedProduct!;
                            }

                            return TextFormField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText:
                                    "${AppLocalizations.of(context).select} ${AppLocalizations.of(context).product}",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                suffixIcon: textEditingController
                                        .text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          textEditingController.clear();
                                          setState(() {
                                            _orderLines[index].selectedProduct =
                                                null;
                                            _orderLines[index].unitPrice = null;
                                            _orderLines[index].productId = null;
                                            _orderLines[index].StocQuantitiy =
                                                null;
                                          });
                                        },
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        if (_orderLines[index].StocQuantitiy != null)
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              '${AppLocalizations.of(context).available_quantity}: ${_orderLines[index].StocQuantitiy?.toString() ?? ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF714B67),
                              ),
                            ),
                          ),
                      ],
                    );
                  } else {
                    return Center(
                      child:
                          Text(AppLocalizations.of(context).no_products_found),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: AppLocalizations.of(context).quantity,
                      keyboardType: TextInputType.number,
                      onChanged: (val) =>
                          _orderLines[index].quantity = double.tryParse(val),
                      enabled: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: BlocBuilder<PricelistCubit, ProductsState>(
                      builder: (context, state) {
                        if (state is ProductPriceLoadedState) {
                          _orderLines[index].unitPrice = state.price;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                label: AppLocalizations.of(context).unit_price,
                                keyboardType: TextInputType.number,
                                onChanged: (val) => _orderLines[index]
                                    .unitPrice = double.tryParse(val),
                                controller: TextEditingController(
                                    text: _orderLines[index]
                                            .unitPrice
                                            ?.toString() ??
                                        ''),
                                enabled: false,
                              ),
                              SizedBox(
                                height: 4,
                              ),
                              Text(
                                "",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green),
                              ),
                            ],
                          );
                        } else if (state is ProductsErrorState) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                label: AppLocalizations.of(context).unit_price,
                                keyboardType: TextInputType.number,
                                onChanged: (val) => _orderLines[index]
                                    .unitPrice = double.tryParse(val),
                                controller: TextEditingController(
                                    text: _orderLines[index]
                                            .unitPrice
                                            ?.toString() ??
                                        ''),
                                enabled: false,
                              ),
                              SizedBox(
                                height: 4,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text("Error loading price",
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                label: AppLocalizations.of(context).unit_price,
                                keyboardType: TextInputType.number,
                                onChanged: (val) => _orderLines[index]
                                    .unitPrice = double.tryParse(val),
                                controller: TextEditingController(
                                    text: _orderLines[index]
                                            .unitPrice
                                            ?.toString() ??
                                        ''),
                                enabled: false,
                              ),
                              SizedBox(
                                height: 4,
                              ),
                              Text("Fetching price..."),
                            ],
                          );
                        }
                      },
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
                        _orderLines[index].selectedTax = value;
                        var selectedTax = state.taxes.firstWhere(
                          (tax) => tax['name'] == value,
                        );
                        _orderLines[index].taxAmount = selectedTax['amount'];
                        _orderLines[index].taxId =
                            selectedTax['id']; // Store tax ID
                        // Store tax ID
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
                    '${AppLocalizations.of(context).taxes} \$${_orderLines[index].tax.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    '${AppLocalizations.of(context).total_price_with_tax} \$${_orderLines[index].totalPriceWithTax.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF714B67), // Odoo purple
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
    return Container(
      width: double.infinity,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppLocalizations.of(context).total_price} \$${_calculateTotalPrice().toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '${AppLocalizations.of(context).total_price_with_tax} \$${_calculateTotalPriceWithTaxes().toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00A09D), // Odoo teal
                ),
              ),
            ],
          ),
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
              return ElevatedButton(
                onPressed: () async {
                  if (customerId == null || paymentTermId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            "${AppLocalizations.of(context).Please_select_a_customer_and_payment_term}"),
                      ),
                    );
                    return;
                  }

                  try {
                    final orderData = {
                      "partner_id": int.tryParse(customerId.toString()) ?? 0,
                      "payment_term_id": 1,
                      "order_line": _orderLines.map((line) {
                        if (line.productId == null ||
                            line.quantity == null ||
                            line.unitPrice == null) {
                          throw Exception("Invalid order line data");
                        }
                        return [
                          0,
                          0,
                          {
                            "product_id": line.productId,
                            "product_uom_qty": line.quantity,
                            "price_unit": line.unitPrice,
                            "tax_id": [line.taxId],
                          }
                        ];
                      }).toList(),
                    };

                    final cubit = SaleOrderCubit.get(context);
                    cubit.createAndConfirmSaleOrder(orderData);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const MyHomePage(title: "home")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: ${e.toString()}")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF714B67)),
                child:
                    const Text('Save', style: TextStyle(color: Colors.white)),
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
              borderRadius: BorderRadius.circular(12),
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
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
    TextEditingController? controller,
  }) {
    return TextField(
      enabled: enabled,
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class OrderLine {
  String? selectedProduct;
  int? productId; // Added to store product ID
  int? PriceProductId; // Added to store product ID
  double? StocQuantitiy; // Added to store product ID
  double? quantity;
  int? unitId;
  double? unitPrice;
  String? selectedTax;
  int? taxId; // Added to store tax ID
  int? paymentTermId; // Added to store tax ID
  double? taxAmount;

  OrderLine({
    this.selectedProduct,
    this.productId,
    this.selectedTax,
    this.quantity,
    this.unitId,
    this.taxId,
    this.paymentTermId,
    this.unitPrice,
    this.taxAmount,
  });

  // Calculate the total price for the line (quantity * unit price)
  double get totalPrice {
    return (quantity ?? 0) * (unitPrice ?? 0);
  }

  // Calculate the tax for the line (total price * tax rate)
  double get tax {
    return totalPrice * (taxAmount ?? 0) / 100;
  }

  // Calculate the total price including tax
  double get totalPriceWithTax {
    return totalPrice + tax;
  }
}
