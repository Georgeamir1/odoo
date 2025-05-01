import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo/sales_order/sales_order_cubit.dart';
import 'package:odoo/sales_order/sales_order_list.dart';
import 'package:odoo/sales_order/sales_order_status.dart';
import '../localization.dart';
import '../networking/odoo_service.dart';
import 'delivery_order_ui.dart';

class newdeliveryorderScreen extends StatefulWidget {
  const newdeliveryorderScreen({Key? key}) : super(key: key);

  @override
  State<newdeliveryorderScreen> createState() => _newdeliveryorderScreenState();
}

class _newdeliveryorderScreenState extends State<newdeliveryorderScreen> {
  final _expirationDateController = TextEditingController();
  final _dateController = TextEditingController();
  var customerId;
  var payment_term_id;
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
      _orderLines[index].unitPrice = priceResult.isNotEmpty
          ? priceResult[0]["fixed_price"] ?? // Use pricelist price if available
              _orderLines[index]
                  .selectedProductWithoutPricelist ?? // Fallback to default price
              0.0 // Final fallback if both are null
          : _orderLines[index].selectedProductWithoutPricelist ?? 0.0;
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
        BlocProvider(create: (_) => PartnersCubit()..getCustomers()),
        BlocProvider(create: (_) => ProductsCubit()..getProducts()),
        BlocProvider(create: (_) => SaleOrderCubit()),
      ],
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            AppLocalizations.of(context).deliveryOrder,
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
/*
                        _buildTotalPriceSection(),
*/
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
                // Capture new values before setState
                final newCustomerId = selected['id'].toString();
                final newCustomerName = selected['name'];

                final newPricelist = selected['property_product_pricelist'][0];
                final oldPricelist = pricelist; // Store current pricelist

                setState(() {
                  customerId = newCustomerId;
                  payment_term_id =
                      selected['property_supplier_payment_term_id']
                              is List<dynamic>
                          ? selected['property_supplier_payment_term_id'][0]
                          : 1;
                  print("payment_term_id is : ${payment_term_id}");
                  pricelist = newPricelist;

                  // Clear order lines only if pricelist changed
                  if (oldPricelist != newPricelist) {
                    _orderLines = [OrderLine()]; // Reset to one empty line
                  }
                });

                PartnersCubit.get(context)
                    .setSelectedCustomer(newCustomerId, newCustomerName);
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
        Text(
          AppLocalizations.of(context).order,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF714B67),
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _orderLines.length,
          itemBuilder: (context, index) {
            return _buildOrderLine(index);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
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
      ],
    );
  }

  Widget _buildOrderLine(int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        _orderLines[index].selectedProductWithoutPricelist =
                            selected['list_price'];
                        print(
                            _orderLines[index].selectedProductWithoutPricelist);
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
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context).product,
                            labelStyle:
                                const TextStyle(color: Color(0xFF714B67)),
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
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).quantity,
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
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => setState(() =>
                          _orderLines[index].quantity = double.tryParse(val)),
                    ),
                  ),
                ),
                Container(
                  height: 55,
                  margin: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFE0E0E0))),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        '${_orderLines[index].unitPrice?.toStringAsFixed(2) ?? "0.00"}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
/*
            const SizedBox(height: 16),
*/
/*
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
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
                        '${_orderLines[index].totalPrice.toStringAsFixed(2)}',
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
                        '${_orderLines[index].totalPriceWithTax.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
*/
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => setState(() => _orderLines.removeAt(index)),
                ),
              ],
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
                  '${_calculateTotalPrice().toStringAsFixed(2)}',
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
                  '${_calculateTotalPriceWithTaxes().toStringAsFixed(2)}',
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
    return Builder(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
/*
            color: Colors.white,
*/
              /*   boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],*/
              ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                  child: Text(
                    AppLocalizations.of(context).cancel,
                    style: const TextStyle(color: Color(0xFF714B67)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFF714B67)),
                    ),
                  )),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF714B67),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  try {
                    if (customerId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)
                              .select_customer_and_lines),
                          backgroundColor: Colors.red[700],
                        ),
                      );
                      return;
                    }
                    final moves = _orderLines.map((line) {
                      print(line.productId);
                      return [
                        0, // Create new record
                        0, // Reserved by Odoo
                        {
                          "product_id": line.productId ?? 0,
                          "name": line.selectedProduct ?? "Product",
                          "product_uom_qty": line.quantity ?? 1.0,
                          "product_uom": 1, // Verify UoM ID
                          "location_id": 8, // Source location
                          "location_dest_id": 5, // Destination location
                        }
                      ];
                    }).toList();
                    final orderData = {
                      "partner_id": int.parse(customerId.toString()),
                      "picking_type_id": 2, // Incoming shipments type
                      "location_id": 8,
                      "location_dest_id": 5,
                      "move_ids_without_package": moves,
                    };
                    await BlocProvider.of<SaleOrderCubit>(context)
                        .createInventoryReceipt(orderData);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            AppLocalizations.of(context).created_successfully),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DeliveryOrderPage(),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red[700],
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
      },
    );
  }
}

class OrderLine {
  String? selectedProduct;
  double? selectedProductWithoutPricelist;
  String? selectedProductTAX;
  int? productId;
  int? unit_id;
  String? productname;
  int? PriceProductId;
  double? StocQuantitiy;
  double? quantity;
  int? unitId;
  double? unitPrice;
  int? taxId;
  int? payment_term_id;
  double? taxAmount = 0.0;

  double get totalPrice => (quantity ?? 0) * (unitPrice ?? 0);
  double get tax => totalPrice * (taxAmount ?? 0) / 100;
  double get totalPriceWithTax => totalPrice + tax;
}
