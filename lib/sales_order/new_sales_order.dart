import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo/sales_order/sales_order_cubit.dart';
import 'package:odoo/sales_order/sales_order_list.dart';
import 'package:odoo/sales_order/sales_order_status.dart';
import '../localization.dart';
import '../networking/odoo_service.dart';

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

  List<OrderLine> _orderLines = [OrderLine()];

  @override
  void dispose() {
    _expirationDateController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  double _calculateTotalPrice() =>
      _orderLines.fold(0, (sum, line) => sum + line.totalPrice);

  double _calculateTotalPriceWithTaxes() =>
      _orderLines.fold(0, (sum, line) => sum + line.totalPriceWithTax);

  Future<void> _fetchPriceAndTax(int index) async {
    final productId = _orderLines[index].PriceProductId;
    final taxId = _orderLines[index].selectedProductTAX;
    if (productId == null || pricelist == null) return;

    final service = OdooRpcService();
    final priceResult = await service.fetchRecords(
      "product.pricelist.item",
      [
        ["pricelist_id", "=", pricelist],
        ["product_tmpl_id", "=", productId]
      ],
      ["fixed_price"],
    );
    final taxResult = taxId != null
        ? await service.fetchRecords("account.tax", [
            ["id", "=", int.parse(taxId)]
          ], [
            "id",
            "amount"
          ])
        : [];

    setState(() {
      _orderLines[index].unitPrice =
          priceResult.isNotEmpty ? priceResult[0]["fixed_price"] ?? 0.0 : 0.0;
      if (taxResult.isNotEmpty) {
        _orderLines[index].taxAmount = taxResult[0]['amount'] ?? 0.0;
        _orderLines[index].taxId = taxResult[0]['id'];
      } else {
        _orderLines[index].taxAmount = 0.0;
        _orderLines[index].taxId = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => PartnersCubit()..getPartners()),
        BlocProvider(create: (_) => ProductsCubit()..getProducts()),
        BlocProvider(create: (_) => SaleOrderCubit()),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context).order,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF714B67),
          elevation: 0,
        ),
        body: Container(
          color: Colors.grey[50],
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderSection(),
                        const SizedBox(height: 24),
                        _buildOrderLinesSection(),
                        const SizedBox(height: 24),
                        _buildTotalPriceSection(),
                      ],
                    ),
                  ),
                ),
                _buildActionButtonsBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).customer,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF714B67),
              ),
            ),
            const SizedBox(height: 12),
            _buildCustomerSelection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSelection() {
    return BlocBuilder<PartnersCubit, PartnersState>(
      builder: (context, state) {
        if (state is PartnersLoadedState) {
          return Autocomplete<String>(
            displayStringForOption: (o) => o,
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text == '')
                return state.partners.map((e) => e['name'] as String);
              return state.partners.map((e) => e['name'] as String).where(
                  (name) => name
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()));
            },
            onSelected: (selection) {
              final selected = state.partners
                  .firstWhere((e) => e['name'] == selection, orElse: () => {});
              if (selected.isNotEmpty) {
                customerId = selected['id'].toString();
                pricelist = selected['property_product_pricelist'][0];
                PartnersCubit.get(context)
                    .setSelectedCustomer(customerId, selected['name']);
              }
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).customer,
                  prefixIcon: const Icon(Icons.person_outline,
                      color: Color(0xFF714B67)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF714B67), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              );
            },
          );
        }
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(color: Color(0xFF714B67)),
          ),
        );
      },
    );
  }

  Widget _buildOrderLinesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context).order,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF714B67),
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add_circle, color: Color(0xFF00A09D)),
              label: Text(
                AppLocalizations.of(context).add_line,
                style: const TextStyle(
                    color: Color(0xFF00A09D), fontWeight: FontWeight.bold),
              ),
              onPressed: () => setState(() => _orderLines.add(OrderLine())),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._orderLines
            .asMap()
            .entries
            .map((entry) => _buildOrderLine(entry.key))
            .toList(),
      ],
    );
  }

  Widget _buildOrderLine(int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
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
                  "Item #${index + 1}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF714B67),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => setState(() => _orderLines.removeAt(index)),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            BlocBuilder<ProductsCubit, ProductsState>(
              builder: (context, state) {
                if (state is ProductsLoadedState) {
                  return Autocomplete<String>(
                    displayStringForOption: (o) => o,
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text == '')
                        return state.Products.map((e) => e['name'] as String);
                      return state.Products.map((e) => e['name'] as String)
                          .where((name) => name
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (selection) async {
                      final selected = state.Products.firstWhere(
                          (e) => e['name'] == selection);
                      setState(() {
                        _orderLines[index].selectedProduct = selection;
                        _orderLines[index].selectedProductTAX =
                            selected['taxes_id'].isNotEmpty
                                ? selected['taxes_id'][0].toString()
                                : null;
                        _orderLines[index].productId =
                            selected['product_variant_ids'][0];
                        _orderLines[index].PriceProductId = selected['id'];
                      });
                      await _fetchPriceAndTax(index);
                    },
                    fieldViewBuilder: (context, controller, focusNode, _) {
                      if (_orderLines[index].selectedProduct != null) {
                        controller.text = _orderLines[index].selectedProduct!;
                      }
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).product,
                          labelStyle: const TextStyle(color: Color(0xFF714B67)),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFF714B67)),
                          ),
                          prefixIcon: const Icon(Icons.inventory_2_outlined,
                              color: Color(0xFF714B67)),
                        ),
                      );
                    },
                  );
                }
                return const CircularProgressIndicator(
                    color: Color(0xFF714B67));
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).quantity,
                labelStyle: const TextStyle(color: Color(0xFF714B67)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF714B67)),
                ),
                prefixIcon: const Icon(Icons.numbers, color: Color(0xFF714B67)),
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) => setState(
                  () => _orderLines[index].quantity = double.tryParse(val)),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context).unit_price,
                        style: const TextStyle(color: Color(0xFF714B67)),
                      ),
                      Text(
                        '\$${_orderLines[index].unitPrice?.toStringAsFixed(2) ?? "0.00"}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context).tax,
                        style: const TextStyle(color: Color(0xFF714B67)),
                      ),
                      Text(
                        '${_orderLines[index].taxAmount?.toStringAsFixed(2) ?? "0.0"}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal',
                        style: TextStyle(color: Color(0xFF714B67)),
                      ),
                      Text(
                        '\$${_orderLines[index].totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total with Tax',
                        style: TextStyle(color: Color(0xFF714B67)),
                      ),
                      Text(
                        '\$${_orderLines[index].totalPriceWithTax.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildTotalPriceSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF714B67),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).total_price,
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  '\$${_calculateTotalPrice().toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).total_price_with_tax,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF714B67),
                  ),
                ),
                Text(
                  '\$${_calculateTotalPriceWithTaxes().toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF714B67),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtonsBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFF714B67)),
              ),
            ),
            child: Text(
              AppLocalizations.of(context).cancel,
              style: const TextStyle(color: Color(0xFF714B67)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF714B67),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              try {
                if (customerId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)
                          .Please_select_a_customer_and_payment_term),
                      backgroundColor: Colors.red[700],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                  return;
                }

                final orderData = {
                  "partner_id": int.tryParse(customerId.toString()) ?? 0,
                  "payment_term_id": 1,
                  "order_line": _orderLines
                      .map((line) => [
                            0,
                            0,
                            {
                              "product_id": line.productId,
                              "product_uom_qty": line.quantity,
                              "price_unit": line.unitPrice,
                              "tax_id": [line.taxId],
                            }
                          ])
                      .toList(),
                };

                await SaleOrderCubit.get(context)
                    .createAndConfirmSaleOrder(orderData);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SaleOrderPage()));
              } catch (e) {
                print('Error: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red[700],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                );
              }
            },
            child: Text(AppLocalizations.of(context).save,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                )),
          ),
        ],
      ),
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
  double? taxAmount = 0.0;

  double get totalPrice => (quantity ?? 0) * (unitPrice ?? 0);
  double get tax => totalPrice * (taxAmount ?? 0) / 100;
  double get totalPriceWithTax => totalPrice + tax;
}
