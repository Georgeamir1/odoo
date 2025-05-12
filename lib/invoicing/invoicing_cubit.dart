import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo/invoicing/invoicing_status.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../networking/odoo_service.dart';

class invoicingCubit extends Cubit<invoicingState> {
  static invoicingCubit get(BuildContext context) =>
      BlocProvider.of<invoicingCubit>(context);
  final odooService = OdooRpcService();

  List<Map<String, dynamic>> allOrders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  int currentDisplayLength = 5;

  invoicingCubit() : super(invoicingInitial());

  Future<void> fetchinvoicing() async {
    try {
      emit(invoicingLoading());
      final prefs = await SharedPreferences.getInstance();
      final orders = await odooService.fetchRecords(
        'account.move',
        [
          ["user_id", "=", "${prefs.getString('username')}"],
        ],
        [
          'status_in_payment',
          'amount_total',
          'state',
          'partner_id',
          'create_date',
          'name',
        ],
      );

      allOrders = List<Map<String, dynamic>>.from(orders);
      filteredOrders = allOrders;
      currentDisplayLength = 5;

      emit(invoicingLoaded(
        filteredOrders.take(currentDisplayLength).toList(),
        hasReachedMax: currentDisplayLength >= filteredOrders.length,
      ));
    } catch (e) {
      emit(invoicingError("Failed to fetch delivery orders: ${e.toString()}"));
    }
  }

  void loadMore() {
    if (state is invoicingLoaded && !(state as invoicingLoaded).hasReachedMax) {
      final newLength = currentDisplayLength + 5;
      final hasReachedMax = newLength >= filteredOrders.length;
      print(1);
      emit(invoicingLoaded(
        filteredOrders.take(newLength).toList(),
        hasReachedMax: hasReachedMax,
      ));
      currentDisplayLength = newLength;
    }
  }

  void filterOrders(String query) {
    try {
      if (query.toLowerCase() == 'all') {
        filteredOrders = allOrders;
      } else {
        final queryLower = query.toLowerCase();
        filteredOrders = allOrders.where((order) {
          return (order['state']?.toString().toLowerCase() ?? '')
                  .contains(queryLower) ||
              (order['name']?.toString().toLowerCase() ?? '')
                  .contains(queryLower) ||
              (order['origin']?.toString().toLowerCase() ?? '')
                  .contains(queryLower);
        }).toList();
      }

      currentDisplayLength = 5;
      emit(invoicingLoaded(
        filteredOrders.take(currentDisplayLength).toList(),
        hasReachedMax: currentDisplayLength >= filteredOrders.length,
      ));
    } catch (e) {
      emit(invoicingError("Error filtering orders: ${e.toString()}"));
    }
  }

/*
  Future<void> createInventoryReceipt(Map<String, dynamic> orderData) async {
    try {
      emit(invoicingLoading());
      final saleOrderId =
          await odooService.createRecord("sale.order", orderData);

      if (saleOrderId != null) {
        emit(invoicingSuccess(saleOrderId));
        await fetchinvoicing(); // Refresh the list
      } else {
        emit(invoicingError("Failed to create sale order"));
      }
    } catch (e) {
      emit(invoicingError("Order creation failed: ${e.toString()}"));
    }
  }
*/
}

class invoicingdetailsCubit extends Cubit<invoicingdetailsState> {
  final OdooRpcService odooService;
  static invoicingdetailsCubit get(context) => BlocProvider.of(context);

  invoicingdetailsCubit(this.odooService) : super(invoicingdetailsLoading());
  List<dynamic> allOrders = []; // Original unfiltered orders list

  Future<void> fetchDetail(int pickingId) async {
    emit(invoicingdetailsLoading());
    try {
      // 1) Fetch picking record
      final result = await odooService.fetchRecords(
        'account.move',
        [
          ["id", "=", pickingId]
        ],
        [],
      );

      if (result.isEmpty) {
        emit(invoicingdetailsError('No details found for this order.'));
        return;
      }

      final picking = result.first;

      // 2) Fetch move details
      final moves = await odooService.fetchRecords(
        'account.move.line',
        [
          ["move_id", "=", pickingId]
        ],
        [
          "name",
          "quantity",
          "product_id",
          "price_total",
          "product_uom_id",
          "price_unit",
          "tax_ids",
          "price_subtotal",
          "l10n_gcc_invoice_tax_amount",
        ],
      );
      // 3) Create a combined map of picking + moves
      final detail = {
        'id': pickingId,
        'name': picking['name'],
        'amount_untaxed': picking['amount_untaxed'],
        'partner_id': picking['partner_id'],
        'date_order': picking['date_order'],
        'pricelist_id': picking['pricelist_id'],
        'payment_term_id': picking['invoice_payment_term_id'],
        'moves': moves,
        'date': picking['date'],
      };

      emit(invoicingdetailsLoaded(detail, picking));
    } catch (e) {
      emit(invoicingdetailsError('Failed to fetch delivery order details: $e'));
    }
  }

  Future<invoicingdetailsState> createReverseInvoice(
      int invoiceId, String reason, String date) async {
    emit(invoicingdetailsLoading());
    try {
      // First, get available journals to use the correct journal_id
      final journals = await odooService.fetchRecords(
        'account.journal',
        [
          [
            'type',
            'in',
            ['sale', 'purchase']
          ]
        ],
        ['id', 'name', 'type'],
      );

      // Find a suitable journal (prefer sale journal)
      int journalId = 1; // Default fallback
      for (var journal in journals) {
        if (journal['type'] == 'sale') {
          journalId = journal['id'];
          break;
        } else if (journal['type'] == 'purchase') {
          journalId = journal['id'];
        }
      }
      print("Journal ID: $journalId");
      // 1. Create a reversal wizard with context
      final reversalId = await odooService.callKw({
        "model": "account.move.reversal",
        "method": "create",
        "args": [
          {
            "move_ids": [invoiceId],
            "date": "$date",
            "reason": "$reason",
            "journal_id": journalId,
          }
        ],
        "kwargs": {
          /*"context": {
            "active_model": "account.move",
            "active_ids": [invoiceId],
          }*/
        }
      });

      if (reversalId == null) {
        throw Exception("Failed to create reversal entry");
      }

      // 2. Execute the reversal to generate the credit note
      final result = await odooService.callKw({
        "model": "account.move.reversal",
        "method": "refund_moves",
        "args": [
          [reversalId]
        ],
        "kwargs": {
          "context": {
            "active_model": "account.move",
            "active_ids": [invoiceId],
          }
        }
      });

      if (result == null) {
        throw Exception("Failed to execute reversal");
      }

      print("Reversal result: $result");

      // 3. Get the ID of the reversed invoice
      int? reversedInvoiceId;

      // Try to extract the reversed invoice ID from the result
      if (result is Map) {
        if (result.containsKey('res_id')) {
          reversedInvoiceId = result['res_id'];
        } else if (result.containsKey('domain')) {
          // Sometimes Odoo returns a domain with the created IDs
          final domain = result['domain'];
          if (domain is List && domain.isNotEmpty) {
            for (var condition in domain) {
              if (condition is List &&
                  condition.length >= 3 &&
                  condition[0] == 'id' &&
                  condition[1] == 'in') {
                final ids = condition[2];
                if (ids is List && ids.isNotEmpty) {
                  reversedInvoiceId = ids.first;
                  break;
                }
              }
            }
          }
        }
      }

      // If we still don't have the ID, try to search for the reversed invoice
      if (reversedInvoiceId == null) {
        final reversedInvoices =
            await odooService.fetchRecords('account.move', [
          ['reversed_entry_id', '=', invoiceId]
        ], [
          'id'
        ]);

        if (reversedInvoices.isNotEmpty) {
          reversedInvoiceId = reversedInvoices.first['id'];
        }
      }

      print("Reversed invoice ID: $reversedInvoiceId");

      // Make sure we have a valid reversed invoice ID
      if (reversedInvoiceId == null) {
        // Try one more time with a different approach
        try {
          final result = await odooService.callKw({
            "model": "account.move",
            "method": "search_read",
            "args": [
              [
                ["reversed_entry_id", "=", invoiceId]
              ]
            ],
            "kwargs": {
              "fields": ["id", "name", "state"]
            }
          });

          if (result is List && result.isNotEmpty) {
            reversedInvoiceId = result.first['id'];
            print(
                "Found reversed invoice ID using search_read: $reversedInvoiceId");
          }
        } catch (e) {
          print("Error in final attempt to find reversed invoice: $e");
        }
      }

      // 4. Refresh the invoice details
      await fetchDetail(invoiceId);

      final successState = invoicingdetailsReversalSuccess(reversedInvoiceId);
      emit(successState);
      return successState;
    } catch (e) {
      final state = invoicingdetailsError('Failed to reverse invoice: $e');
      emit(state);
      return state;
    }
  }

  // Update invoice line quantities
  Future<void> updateInvoiceLineQuantity(
      int invoiceId, int lineId, double quantity) async {
    try {
      emit(invoicingdetailsLoading());

      final success = await odooService.updateRecord(
        'account.move.line',
        lineId,
        {'quantity': quantity},
      );

      if (!success) {
        throw Exception("Failed to update invoice line quantity");
      }

      // Refresh the invoice details to see the updated values
      await fetchDetail(invoiceId);
      emit(invoicingUpdateSuccess(invoiceId));
    } catch (e) {
      emit(invoicingdetailsError('Failed to update invoice line: $e'));
    }
  }

  // Save invoice changes
  Future<void> saveInvoiceChanges(int invoiceId) async {
    emit(invoicingdetailsLoading());
    try {
      // Refresh the invoice details to see the updated values
      await fetchDetail(invoiceId);
      emit(invoicingUpdateSuccess(invoiceId));
    } catch (e) {
      emit(invoicingdetailsError('Failed to save invoice changes: $e'));
    }
  }

  // Post invoice (action_post)
  Future<void> postInvoice(int invoiceId) async {
    emit(invoicingdetailsLoading());
    try {
      await odooService.callKw({
        "model": "account.move",
        "method": "action_post",
        "args": [invoiceId],
        "kwargs": {
          "context": {
            "validate_analytic": true,
          }
        },
      });

      // Refresh the invoice details
      await fetchDetail(invoiceId);
      emit(invoicingPostSuccess(invoiceId));
    } catch (e) {
      emit(invoicingdetailsError('Failed to post invoice: $e'));
    }
  }

  // Create stock return from delivery order
  Future<void> createStockReturn(
      int pickingId, Map<int, double> productQuantities) async {
    emit(invoicingdetailsLoading());
    try {
      // Get move lines for the picking
      final moveLines = await odooService.fetchRecords('stock.move', [
        ["picking_id", "=", pickingId]
      ], [
        "id",
        "product_id",
        "product_uom_qty"
      ]);

      if (moveLines.isEmpty) {
        throw Exception("No move lines found for this delivery order");
      }

      // Prepare product return moves
      List<Map<String, dynamic>> productReturns = [];
      for (var move in moveLines) {
        final productId = move['product_id'][0];
        // Use the specific quantity for this product, or the product_uom_qty as fallback
        final quantity =
            productQuantities[productId] ?? move['product_uom_qty'];

        productReturns.add({
          "product_id": productId,
          "quantity": quantity,
          "move_id": move['id']
        });
      }

      // Step 1: Create the return wizard
      final returnWizardId = await odooService.callKw({
        "model": "stock.return.picking",
        "method": "create",
        "args": [
          {
            "picking_id": pickingId,
            "product_return_moves":
                productReturns.map((item) => [0, 0, item]).toList()
          }
        ],
        "kwargs": {}
      });

      if (returnWizardId == null) {
        throw Exception("Failed to create return wizard");
      }

      // Step 2: Generate the return picking
      final result = await odooService.callKw({
        "model": "stock.return.picking",
        "method": "action_create_returns",
        "args": [
          [returnWizardId]
        ],
        "kwargs": {}
      });

      if (result == null) {
        throw Exception("Failed to execute return action");
      }

      // Extract the returned picking ID
      int? returnPickingId;
      if (result is Map && result.containsKey("res_id")) {
        returnPickingId = result["res_id"];
      } else if (result is Map &&
          result.containsKey("result") &&
          result["result"] is Map) {
        final resultData = result["result"];
        if (resultData.containsKey("res_id")) {
          returnPickingId = resultData["res_id"];
        }
      }

      if (returnPickingId == null) {
        throw Exception("No return picking ID found after return creation.");
      }

      print("Return Picking Created: $returnPickingId");

      // Get the current state of the return picking
      final pickingData = await odooService.fetchRecords('stock.picking', [
        ["id", "=", returnPickingId]
      ], [
        "state"
      ]);

      if (pickingData.isEmpty) {
        throw Exception("Return picking not found");
      }

      final pickingState = pickingData[0]['state'];

      // Only validate if the picking is in 'assigned' state
      if (pickingState == 'assigned') {
        // Step 3: Validate the return picking (button_validate)
        final validateResult = await odooService.callKw({
          "model": "stock.picking",
          "method": "button_validate",
          "args": [
            [returnPickingId]
          ],
          "kwargs": {}
        });

        if (validateResult == null) {
          throw Exception("Failed to validate the return picking.");
        }
      } else {
        print(
            "Return picking is in state '$pickingState' - skipping validation");
      }

      // Emit success
      emit(invoicingReturnSuccess(returnPickingId));
      emit(NavigateToinvoicingdetailsPage());
    } catch (e) {
      print("Error creating stock return: $e");
      emit(invoicingdetailsError('Failed to create stock return: $e'));
    }
  }

  Future<int?> fetchDeliveryOrderIdFromInvoice(int invoiceId) async {
    try {
      // Step 1: Get invoice_origin from account.move
      final invoiceResult = await odooService.fetchRecords(
        'account.move',
        [
          ["id", "=", invoiceId]
        ],
        ["invoice_origin"],
      );

      if (invoiceResult.isEmpty ||
          invoiceResult.first['invoice_origin'] == null) {
        return null; // or throw Exception('No invoice origin found.');
      }

      final invoiceOrigin = invoiceResult.first['invoice_origin'];

      // Step 2: Find stock.picking with origin == invoiceOrigin (usually sale order name)
      final pickingResult = await odooService.fetchRecords(
        'stock.picking',
        [
          ["origin", "=", invoiceOrigin]
        ],
        ["id"],
      );

      if (pickingResult.isEmpty) {
        return null; // or throw Exception('No delivery order found for origin: $invoiceOrigin');
      }

      return pickingResult.first['id'] as int;
    } catch (e) {
      rethrow; // Let caller handle error
    }
  }
}
