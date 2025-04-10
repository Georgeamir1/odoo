import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo/sales_order/sales_order_cubit.dart';
import 'package:odoo/sales_order/sales_order_list.dart';
import 'package:odoo/sales_order/sales_order_status.dart';
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
          preferredSize: const Size.fromHeight(70.0),
          child: Container(
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
            child: AppBar(
              title: Text(
                AppLocalizations.of(context).order,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
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
                PartnersCubit.get(context)
                    .setSelectedCustomer(customerId, selectedCustomer['name']);
              }
            },
            fieldViewBuilder:
                (context, textEditingController, focusNode, onFieldSubmitted) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).customer,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
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
                              icon: const Icon(Icons.clear),
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

  Widget _buildOrderLinesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).order_lines,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
            icon: const Icon(Icons.add, color: Color(0xFF00A09D)),
            label: Text(
              AppLocalizations.of(context).add_line,
              style: const TextStyle(color: Color(0xFF00A09D)),
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
                          style: const TextStyle(
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
                              final selectedProduct = state.Products.firstWhere(
                                (product) => product['name'] == selection,
                              );

                              if (selectedProduct['taxes_id'] != null &&
                                  selectedProduct['taxes_id'].isNotEmpty) {
                                _orderLines[index].selectedProductTAX =
                                    selectedProduct['taxes_id'][0].toString();
                              } else {
                                _orderLines[index].selectedProductTAX = null;
                              }

                              _orderLines[index].productId =
                                  selectedProduct['product_variant_ids'][0];
                              _orderLines[index].PriceProductId =
                                  selectedProduct['id'];

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
                                            _orderLines[index]
                                                .selectedProductTAX = null;
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
                              const SizedBox(height: 4),
                            ],
                          );
                        } else if (state is ProductsErrorState) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                label: AppLocalizations.of(context).unit_price,
                                keyboardType: TextInputType.number,
                                controller: TextEditingController(
                                    text: _orderLines[index]
                                            .unitPrice
                                            ?.toString() ??
                                        ''),
                                enabled: false,
                              ),
                              const SizedBox(height: 4),
                              const Padding(
                                padding: EdgeInsets.all(8.0),
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
                                controller: TextEditingController(
                                    text: _orderLines[index]
                                            .unitPrice
                                            ?.toString() ??
                                        ''),
                                enabled: false,
                              ),
                              const SizedBox(height: 4),
                              const Text("Fetching price..."),
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
                listener: (context, state) {
                  if (state is TaxesLoadedState) {
                    final currentTaxId = _orderLines[index].selectedProductTAX;
                    if (currentTaxId != null) {
                      final taxExists = state.taxes.any(
                        (tax) => tax['id'].toString() == currentTaxId,
                      );

                      setState(() {
                        if (taxExists) {
                          final selectedTax = state.taxes.firstWhere(
                            (tax) => tax['id'].toString() == currentTaxId,
                          );
                          _orderLines[index].taxAmount =
                              selectedTax['amount']?.toDouble() ?? 0.0;
                          _orderLines[index].taxId = selectedTax['id'];
                        } else {
                          _orderLines[index].taxAmount = 0.0;
                          _orderLines[index].taxId = null;
                        }
                      });
                    }
                  }
                },
                builder: (context, state) {
                  if (state is TaxesLoadingState) {
                    return const CircularProgressIndicator();
                  } else if (state is TaxesErrorState) {
                    return Text("Error: ${state.error}");
                  } else if (state is TaxesLoadedState) {
                    final currentTax = state.taxes.firstWhere(
                      (tax) =>
                          tax['id'].toString() ==
                          _orderLines[index].selectedProductTAX,
                      orElse: () => null,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentTax != null
                              ? "${AppLocalizations.of(context).tax}: ${currentTax['name']} (${currentTax['amount']}%)"
                              : AppLocalizations.of(context).no_tax_applied,
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
                    );
                  } else {
                    return const Text("No tax data");
                  }
                },
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
                    color: Color(0xFF00A09D)),
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
                  if (customerId == null) {
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
                          builder: (context) => const SaleOrderPage()),
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
  String? selectedProductTAX;
  int? productId;
  int? PriceProductId;
  double? StocQuantitiy;
  double? quantity;
  int? unitId;
  double? unitPrice;
  int? taxId;
  int? paymentTermId;
  double? taxAmount = 0.0;

  OrderLine({
    this.selectedProduct,
    this.productId,
    this.quantity,
    this.unitId,
    this.taxId,
    this.paymentTermId,
    this.unitPrice,
    this.taxAmount = 0.0, // Initialize in constructor
  });

  double get totalPrice {
    return (quantity ?? 0) * (unitPrice ?? 0);
  }

  double get tax {
    return totalPrice * (taxAmount ?? 0) / 100;
  }

  double get totalPriceWithTax {
    return totalPrice + tax;
  }
}
