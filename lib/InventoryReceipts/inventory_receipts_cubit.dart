import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../networking/odoo_service.dart'; // Your Odoo RPC service
import 'inventory_receipts_status.dart'; // Contains InventoryReceiptsState classes

class InventoryReceiptsCubit extends Cubit<InventoryReceiptsState> {

  InventoryReceiptsCubit() : super(InventoryReceiptsInitial());
  static InventoryReceiptsCubit get(context) => BlocProvider.of(context);
  final OdooRpcService odooService = OdooRpcService();
  List<Map<String, dynamic>> allOrders = [];
  int currentLength = 5; // Start with last 5 orders
  Future<void> fetchInventoryReceiptss() async {
    try {
      emit(InventoryReceiptsLoading()); // Notify UI that loading is in progress

      // Fetch orders from Odoo
      final orders = await odooService.fetchRecords(
        'stock.picking', // Model name
        [
          ['picking_type_id.code', '=', 'incoming'] // Filter for outgoing deliveries
        ],
        [
          'id',
          'name',
          'state',
          'partner_id', // Include partner_id (customer)
          'origin', // Include origin (reference)
          'scheduled_date', // Include scheduled date
          'move_ids_without_package', // Include moves for detailed information
        ],
      );

      // Reverse the list to show the most recent orders first and limit to 50 for performance
      allOrders = List<Map<String, dynamic>>.from(orders.reversed.take(50));
      List<Map<String, dynamic>> initialOrders = await _fetchMoveDetails(
          allOrders.take(5).toList());

      emit(InventoryReceiptsLoaded(initialOrders));
    } catch (e) {
      // Notify UI of the error
      emit(InventoryReceiptsError("Failed to fetch delivery orders: $e"));
    }
  }
  Future<List<Map<String, dynamic>>> _fetchMoveDetails(List<Map<String, dynamic>> orders) async {
    List<Map<String, dynamic>> enrichedOrders = [];

    for (var order in orders) {
      // Fetch move details for the order
      final moves = await odooService.fetchMoves(order['move_ids_without_package']);

      // Enrich the order with move details
      enrichedOrders.add({
        'id': order['id'],
        'name': order['name'],
        'state': order['state'],
        'partner_id': order['partner_id'], // Customer information
        'origin': order['origin'], // Reference number
        'scheduled_date': order['scheduled_date'], // Scheduled delivery date
        'moves': moves, // Detailed move information
      });
    }

    return enrichedOrders;
  }
  Future<void> updateDeliveryStatus(int id, String status) async {
    emit(InventoryReceiptsLoading());
    try {
      bool success = false;
      if (status == 'assigned') {
        final response = await odooService.client.callKw({
          'model': 'stock.picking',
          'method': 'action_assign',
          'args': [
            [id]
          ],
          'kwargs': {}
        });
        success = response == true;
      } else if (status == 'done') {
        final response = await odooService.client.callKw({
          'model': 'stock.picking',
          'method': 'button_validate',
          'args': [
            [id]
          ],
          'kwargs': {}
        });
        success = response == true;
      } else {
        success = await odooService
            .updateRecord("stock.picking", id, {'state': status});
      }
      if (success) {
        await fetchInventoryReceiptss();
      } else {
        emit(InventoryReceiptsError("Failed to update delivery order."));
      }
    } catch (e) {
      emit(InventoryReceiptsError("Error updating order: $e"));
    }
  }
  void loadMore() async {
    if (state is InventoryReceiptsLoaded && currentLength < allOrders.length) {
      int newLength = currentLength + 5;
      List<Map<String, dynamic>> newOrders = await _fetchMoveDetails(
          allOrders.skip(currentLength).take(5).toList());
      currentLength = newLength;
      emit(InventoryReceiptsLoaded(
          [...((state as InventoryReceiptsLoaded).orders), ...newOrders]));
    }
  }
  void filterOrders(String query) {
    // If the query is "all", return all orders.
    if (query.toLowerCase() == 'all') {
      emit(InventoryReceiptsLoaded(allOrders));
      return;
    }

    try {
      final queryLower = query.toLowerCase();
      final filtered = allOrders.where((order) {
        final orderState = order['state']?.toString().toLowerCase() ?? '';
        final orderName = order['name']?.toString().toLowerCase() ?? '';
        final orderOrigin = order['origin']?.toString().toLowerCase() ?? '';

        // Check if any field contains the query text.
        return orderState.contains(queryLower) ||
            orderName.contains(queryLower) ||
            orderOrigin.contains(queryLower);
      }).toList();

      emit(InventoryReceiptsLoaded(filtered));
    } catch (e) {
      emit(InventoryReceiptsError("Error filtering orders: $e"));
    }
  }
  Future<void> validateOrder(int pickingId,
      {required bool createBackorder, dynamic fallbackOrder}) async {
    emit(InventoryReceiptsLoading());
    try {
      // Try to find the order in the cached list, or use fallbackOrder if not found.
      final orderFound = allOrders.firstWhere(
            (o) => o['id'] == pickingId,
        orElse: () => fallbackOrder,
      );
      if (orderFound == null) {
        throw Exception("Order not found");
      }

      // Get moves from detailed moves if available; otherwise, fallback.
      List<dynamic> moves = (orderFound['moves_details'] is List &&
          orderFound['moves_details'].isNotEmpty)
          ? orderFound['moves_details']
          : orderFound['move_ids_without_package'];

      bool allDelivered = true;
      for (var move in moves) {
        if (move is Map) {
          double demanded =
              double.tryParse(move['product_uom_qty'].toString()) ?? 0.0;
          double delivered =
              double.tryParse(move['quantity_done']?.toString() ?? "0") ?? 0.0;
          if (delivered < demanded) {
            allDelivered = false;
            break;
          }
        } else {
          allDelivered = false;
          break;
        }
      }

      if (allDelivered) {
        // Validate normally.
        final response = await odooService.client.callKw({
          'model': 'stock.picking',
          'method': 'button_validate',
          'args': [
            [pickingId]
          ],
          'kwargs': {}
        });
        if (response != true) {
          throw Exception("Validation failed");
        }
        print("Order validated normally.");
      } else {
        // Partial picking scenario.
        if (createBackorder) {
          // Trigger partial picking with backorder creation.
          final response = await odooService.client.callKw({
            'model': 'stock.picking',
            'method': 'button_validate',
            'args': [
              [pickingId]
            ],
            'kwargs': {}
          });
          if (response is Map &&
              response['res_model'] == 'stock.backorder.confirmation') {
            final backorderResponse = await odooService.client.callKw({
              'model': 'stock.backorder.confirmation',
              'method': 'process',
              'args': [
                [response['res_id']]
              ],
              'kwargs': {}
            });
            if (backorderResponse != true) {
              throw Exception("Backorder processing failed");
            }
            print("Order validated with partial picking (backorder created).");
          } else if (response != true) {
            throw Exception("Partial picking validation failed");
          } else {
            print(
                "Order validated with partial picking without backorder wizard.");
          }
        } else {
          // Adjust demand: For each move, set product_uom_qty equal to quantity_done.
          for (var move in moves) {
            if (move is Map) {
              final moveId = move['id'];
              final delivered = move['quantity_done'] ?? 0;
              final updateResponse = await odooService.updateRecord(
                'stock.move',
                moveId,
                {'product_uom_qty': delivered},
              );
              if (updateResponse != true) {
                throw Exception("Failed to adjust demand for move $moveId");
              }
            }
          }
          // Then validate the picking normally.
          final response = await odooService.client.callKw({
            'model': 'stock.picking',
            'method': 'button_validate',
            'args': [
              [pickingId]
            ],
            'kwargs': {}
          });
          if (response != true) {
            throw Exception("Validation after demand adjustment failed");
          }
          print("Order validated by adjusting demand successfully.");
        }
      }
      // Refresh orders after validation.
      await fetchInventoryReceiptss();
      emit(InventoryReceiptsSuccess(pickingId));
    } catch (e) {
      emit(InventoryReceiptsError("Error validating order: $e"));
    }
  }
}
class InventoryReceiptsDetailCubit extends Cubit<InventoryReceiptsDetailState> {
  final OdooRpcService odooService;
  static InventoryReceiptsDetailCubit get(context) => BlocProvider.of(context);

  InventoryReceiptsDetailCubit(this.odooService) : super(InventoryReceiptsDetailLoading());
  List<dynamic> allOrders = []; // Original unfiltered orders list

  /// Fetches delivery orders from Odoo and enriches each order with move details.

  Future<void> fetchDetail(int pickingId) async {
    emit(InventoryReceiptsDetailLoading());
    try {
      // 1) Fetch picking record
      final result = await odooService.fetchRecords(
        'stock.picking',
        [
          ['id', '=', pickingId]
        ],
        [
          'name',
          'state',
          'scheduled_date',
          'date_deadline',
          'origin',
          'picking_type_id',
          'move_ids_without_package',
          'products_availability',

        ],
      );

      if (result.isEmpty) {
        emit(InventoryReceiptsDetailError('No details found for this order.'));
        return;
      }

      final picking = result.first;

      // 2) Fetch move details
      final moves = await odooService.fetchMoves(picking['move_ids_without_package']);

      // 3) Create a combined map of picking + moves
      final detail = {
        'id': pickingId,
        'name': picking['name'],
        'state': picking['state'],
        'scheduled_date': picking['scheduled_date'],
        'date_deadline': picking['date_deadline'],
        'origin': picking['origin'],
        'picking_type_id': picking['picking_type_id'],
        'moves': moves,
      };

      emit(InventoryReceiptsDetailLoaded(detail,picking));
    } catch (e) {
      emit(InventoryReceiptsDetailError('Failed to fetch delivery order details: $e'));
    }
  }
  Future<void> validateOrder(int pickingId) async {
    try {
      print('⏳ Validating order ID: $pickingId');
      final result = await odooService.callKw({
        'model': 'stock.picking',
        'method': 'button_validate',
        'args': [[pickingId]],
        'kwargs': {},
      });

      print('🔵 Validation Response:');
      print('Type: ${result.runtimeType}');
      print('Raw data: $result');

      if (result == true) {
        print('✅ Validation successful - no backorder needed');
        emit(InventoryReceiptsvalidationSuccess());
        await fetchDetail(pickingId);
        emit(NavigateToInventoryReceiptsPage());  // Emit navigation state
      } else if (result is Map<String, dynamic>) {
        print('⚠️ Backorder wizard detected');
        final wizardId = result['res_id'];
        print('🔧 Backorder Wizard ID: $wizardId');
        // Handle backorder wizard here
      } else {
        print('❌ Unexpected response format');
        emit(InventoryReceiptsvalidationError('Unexpected validation response: $result'));
      }
    } catch (e, stackTrace) {
      print('‼️ Validation Error:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      emit(InventoryReceiptsvalidationError('Error validating order: $e'));
    }
  }
  Future<void> validate_without_backOrder(int pickingId) async {
    try {
      final result = await odooService.callKw({
        "model": "stock.picking",
        "method": "button_validate",
        'args': [
          [pickingId]
        ],
        'kwargs': {
          "context": {
            "skip_backorder": true,
            "picking_ids_not_to_backorder": [pickingId]
          }
        },
      });

      print("🔵 رد الخادم: $result");

      if (result == true) {
        print("✅ تم الإلغاء بنجاح دون إنشاء باك أوردر");
        emit(NoBackOrderValidationSuccess());
        // إعادة تحميل البيانات لتحديث الواجهة
        await fetchDetail(pickingId); // تأكد من تعريف originalPickingId
        emit(NavigateToInventoryReceiptsPage());  // Emit navigation state

      } else {
        print("❌ فشل الإلغاء - الرد غير متوقع: $result");
        emit(NoBackOrderValidationError('فشل الإلغاء: $result'));
      }
    } catch (e, stackTrace) {
      print("‼️ خطأ أثناء الإلغاء:");
      print("التفاصيل: $e");
      print("مسار الخطأ: $stackTrace");
      emit(NoBackOrderValidationError('خطأ تقني: $e'));
    }
  }
  Future<void> validate_With_BackOrder(int backorderConfirmationId) async {
    try {
      print('⏳ Validating WITH backorder, Wizard ID: $backorderConfirmationId');
      final result = await odooService.callKw({
        "model": "stock.picking",
        "method": "button_validate",
        'args': [
          [backorderConfirmationId] // يجب أن يكون ID الويزارد صحيحًا
        ],
        'kwargs': {
          "context": {
            "skip_backorder": true,
          }
        },
      });

      print('🔵 With Backorder Response:');
      print('Type: ${result.runtimeType}');
      print('Raw data: $result');

      if (result == true) {
        print('✅ Backorder created successfully');
        emit(BackOrderValidationSuccess());
        emit(NavigateToInventoryReceiptsPage());  // Emit navigation state

      } else {
        print('❌ Backorder creation failed');
        emit(BackOrderValidationError('Backorder validation failed. Response: $result'));
      }
    } catch (e, stackTrace) {
      print('‼️ With Backorder Error:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      emit(BackOrderValidationError('Error validating with backorder: $e'));
    }
  }
}