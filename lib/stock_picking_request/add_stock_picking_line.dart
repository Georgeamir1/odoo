import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../InventoryReceipts/new_inventory_receipt.dart';
import '../localization.dart';
import '../networking/odoo_service.dart';
import '../sales_order/sales_order_cubit.dart';
import '../sales_order/sales_order_status.dart';
import 'stock_picking_request_cubit.dart';

class AddStockPickingLine extends StatefulWidget {
  const AddStockPickingLine({
    Key? key,
  }) : super(key: key);

  @override
  State<AddStockPickingLine> createState() => _AddStockPickingLineState();
}

class _AddStockPickingLineState extends State<AddStockPickingLine> {
  final OdooRpcService odooService = OdooRpcService();
  bool isSubmitting = false;
  String? submitError;
  List<OrderLine> _orderLines = [OrderLine()];

  bool get isFormValid {
    for (final line in _orderLines) {
      if (line.productMap != null && line.quantityController.text.isNotEmpty) {
        final quantity = double.tryParse(line.quantityController.text) ?? 0;
        if (quantity > 0) return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductsCubit()..getProducts(),
      child: Scaffold(
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
                AppLocalizations.of(context).addProductLine,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
        ),
        body: BlocBuilder<ProductsCubit, ProductsState>(
          builder: (context, state) {
            if (state is ProductsLoadingState) {
              return Center(
                child: Lottie.asset(
                  'assets/images/loading.json',
                  width: 200,
                  height: 200,
                  fit: BoxFit.fill,
                ),
              );
            }
            if (state is ProductsErrorState) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      state.error,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<ProductsCubit>().getProducts(),
                      child: Text(AppLocalizations.of(context).tryAgain),
                    ),
                  ],
                ),
              );
            }
            if (state is ProductsLoadedState) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderLinesSection(context, state),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            }
            return Container();
          },
        ),
        bottomNavigationBar: Container(
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
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF714B67),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: isFormValid && !isSubmitting ? addProductLine : null,
            child: Text(AppLocalizations.of(context).addProductLine),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderLinesSection(
      BuildContext context, ProductsLoadedState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _orderLines.length,
          itemBuilder: (context, index) =>
              _buildOrderLine(context, state, index),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.add_circle, color: Color(0xFF00A09D)),
              label: Text(
                AppLocalizations.of(context).add_line,
                style: const TextStyle(
                  color: Color(0xFF00A09D),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => setState(() => _orderLines.add(OrderLine())),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderLine(
      BuildContext context, ProductsLoadedState state, int index) {
    final line = _orderLines[index];
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      children: [
                        Flexible(
                          flex: 4,
                          child: Autocomplete<String>(
                            displayStringForOption: (o) => o,
                            optionsBuilder: (textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return state.Products.map(
                                    (e) => e['name'] as String);
                              }
                              return state.Products.map(
                                      (e) => e['name'] as String)
                                  .where((name) => name.toLowerCase().contains(
                                      textEditingValue.text.toLowerCase()));
                            },
                            onSelected: (selection) {
                              final selected = state.Products.firstWhere(
                                  (e) => e['name'] == selection);
                              setState(() {
                                line.selectedProduct = selection;
                                line.productMap = selected;
                              });
                            },
                            fieldViewBuilder:
                                (context, controller, focusNode, _) {
                              if (line.selectedProduct != null) {
                                controller.text = line.selectedProduct!;
                              }
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(context).product,
                                  labelStyle:
                                      const TextStyle(color: Color(0xFF714B67)),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  prefixIcon: const Icon(
                                      Icons.inventory_2_outlined,
                                      color: Color(0xFF714B67)),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          flex: 2,
                          child: Column(
                            children: [
                              TextField(
                                controller: line.quantityController,
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(context).quantity,
                                  labelStyle:
                                      const TextStyle(color: Color(0xFF714B67)),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              if (line.productMap != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '${AppLocalizations.of(context).available_quantity}: ${line.productMap!['qty_available'] ?? 0}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => setState(() => _orderLines.removeAt(index)),
        ),
      ],
    );
  }

  Future<void> addProductLine() async {
    setState(() => isSubmitting = true);
    final List<String> errors = [];
    final List<Map<String, dynamic>> lineIds = [];

    for (int i = 0; i < _orderLines.length; i++) {
      final line = _orderLines[i];
      final product = line.productMap;
      final quantity = double.tryParse(line.quantityController.text) ?? 0;

      if (product == null) {
        errors.add(
            '${AppLocalizations.of(context).line} ${i + 1}: ${AppLocalizations.of(context).noProductSelected}');
        continue;
      }

      if (quantity <= 0) {
        errors.add(
            '${AppLocalizations.of(context).line} ${i + 1}: ${AppLocalizations.of(context).invalidQuantity}');
        continue;
      }

      lineIds.add({
        'product_id': product['id'],
        'quantity': quantity,
      });
    }

    if (errors.isNotEmpty) {
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errors.join('\n')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await odooService.client.callKw({
        "model": "psi.stock.picking.request",
        "method": "create",
        "args": [
          {
            "line_ids": lineIds.map((line) => [0, 0, line]).toList(),
          }
        ],
        "kwargs": {}
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).done),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class OrderLine {
  String? selectedProduct;
  Map<String, dynamic>? productMap;
  TextEditingController quantityController = TextEditingController(text: '1.0');
}
