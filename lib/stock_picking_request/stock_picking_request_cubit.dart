import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../networking/odoo_service.dart';
import 'stock_picking_request_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StockPickingRequestCubit extends Cubit<StockPickingRequestState> {
  StockPickingRequestCubit() : super(StockPickingRequestInitial());

  static StockPickingRequestCubit get(context) => BlocProvider.of(context);
  final OdooRpcService odooService = OdooRpcService();
  List<Map<String, dynamic>> allRequests = [];
  int currentLength = 5; // Start with last 5 requests

  Future<void> fetchStockPickingRequests() async {
    try {
      emit(
          StockPickingRequestLoading()); // Notify UI that loading is in progress
      final prefs = await SharedPreferences.getInstance();

      // Fetch stock picking requests from Odoo
      final requests = await odooService.fetchRecords(
        'psi.stock.picking.request', // Model name
        [
          ['create_uid', '=', "${prefs.getString('username')}"]
        ],
        [
          'name',
          'state',
          'create_date',
          'create_uid',
          'warehouse_id',
        ],
      );

      // Reverse the list to show the most recent requests first and limit to 50 for performance
      allRequests = List<Map<String, dynamic>>.from(requests.reversed.take(50));
      List<Map<String, dynamic>> initialRequests =
          await _fetchMoveDetails(allRequests.take(5).toList());

      emit(StockPickingRequestLoaded(initialRequests,
          hasMore: allRequests.length > 5));
    } catch (e) {
      emit(StockPickingRequestError(
          'Failed to fetch stock picking requests: $e'));
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMoveDetails(
      List<Map<String, dynamic>> requests) async {
    final result = <Map<String, dynamic>>[];

    for (var request in requests) {
      final moveIds = request['move_ids_without_package'];
      if (moveIds is List && moveIds.isNotEmpty) {
        final moves = await odooService.fetchRecords(
          'stock.move',
          [
            ['id', 'in', moveIds]
          ],
          [],
        );

        // Add move details to the request
        request['moves'] = moves;
      } else {
        request['moves'] = [];
      }

      result.add(request);
    }

    return result;
  }

  Future<void> loadMore() async {
    if (currentLength >= allRequests.length) {
      return; // No more items to load
    }

    try {
      final currentState = state;
      if (currentState is StockPickingRequestLoaded) {
        final nextBatch = allRequests.skip(currentLength).take(5).toList();
        currentLength += nextBatch.length;

        final detailedRequests = await _fetchMoveDetails(nextBatch);
        final updatedRequests = [
          ...currentState.requests,
          ...detailedRequests,
        ];

        emit(StockPickingRequestLoaded(updatedRequests,
            hasMore: currentLength < allRequests.length));
      }
    } catch (e) {
      emit(StockPickingRequestError('Failed to load more requests: $e'));
    }
  }

  Future<void> updateRequestStatus(int id, String status) async {
    emit(StockPickingRequestLoading());
    try {
      bool success = false;
      if (status == 'assigned') {
        final response = await odooService.client.callKw({
          'model': 'psi.stock.picking.request', // Model name
          'method': 'action_assign',
          'args': [
            [id]
          ],
          'kwargs': {}
        });
        success = response == true;
      } else if (status == 'done') {
        final response = await odooService.client.callKw({
          'model': 'psi.stock.picking.request', // Model name

          'method': 'button_validate',
          'args': [
            [id]
          ],
          'kwargs': {}
        });
        success = response == true;
      } else {
        success = await odooService
            .updateRecord('psi.stock.picking.request', id, {'state': status});
      }
      if (success) {
        await fetchStockPickingRequests();
      } else {
        emit(StockPickingRequestError(
            "Failed to update stock picking request."));
      }
    } catch (e) {
      emit(StockPickingRequestError("Error updating request: $e"));
    }
  }

  Future<void> fetchDetail(int pickingId) async {
    emit(StockPickingRequestDetailLoading());
    try {
      // 1) Fetch picking record
      final result = await odooService.fetchRecords(
        'psi.stock.picking.request', // Model name
        [
          ['id', '=', pickingId]
        ],
        [],
      );
      final result2 = await odooService.fetchRecords(
        'psi.stock.picking.request.line', // Model name
        [
          ['id', '=', result.first['line_ids']]
        ],
        [],
      );
      List<Map<String, dynamic>> allproducts =
          List<Map<String, dynamic>>.from(result2);
      if (result.isEmpty) {
        emit(StockPickingRequestDetailError(
            'No details found for this request.'));
        return;
      }

      final picking = result.first;
      final picking2 = result2.first;

      // 2) Fetch move details with only available fields

      // 3) Create a combined map of picking + moves
      final detail = {
        'id': pickingId,
        'name': picking['name'],
        'state': picking['state'],
        'create_uid': picking['create_uid'],
        'warehouse': picking['warehouse_id'][1],
        'create_date': picking['create_date'],
        'approved_by': picking['approved_by'],
        'closed_date': picking['closed_date'],
        'scheduled_date': picking['scheduled_date'],
        'date_deadline': picking['date_deadline'],
        'origin': picking['origin'],
        'picking_type_id': picking['picking_type_id'],
        'location_id': picking['location_id'],
        'location_dest_id': picking['location_dest_id'],
        'product_lines': allproducts,
      };
      emit(StockPickingRequestDetailLoaded(detail, picking));
    } catch (e) {
      emit(StockPickingRequestDetailError(
          'Failed to fetch stock picking request details: $e'));
    }
  }

  Future<void> validateRequest(int pickingId) async {
    try {
      print('⏳ Validating request ID: $pickingId');
      final result = await odooService.callKw({
        'model': 'psi.stock.picking.request', // Model name

        'method': 'button_validate',
        'args': [
          [pickingId]
        ],
        'kwargs': {},
      });

      if (result == true) {
        print('✅ Request validated successfully');
        emit(ValidationSuccess());
        await fetchDetail(pickingId);
      } else if (result is Map &&
          result['res_model'] == 'stock.backorder.confirmation') {
        print('⚠️ Backorder confirmation required');
        // Handle backorder confirmation
        final backorderWizardId = result['res_id'];
        final backorderResult = await odooService.callKw({
          'model': 'stock.backorder.confirmation',
          'method': 'process',
          'args': [
            [backorderWizardId]
          ],
          'kwargs': {},
        });

        if (backorderResult == true) {
          print('✅ Request validated with backorder');
          emit(ValidationSuccess());
          await fetchDetail(pickingId);
        } else {
          print('❌ Backorder confirmation failed');
          emit(ValidationError('Backorder confirmation failed'));
        }
      } else {
        print('❌ Validation failed: $result');
        emit(ValidationError('Validation failed: $result'));
      }
    } catch (e) {
      print('❌ Error during validation: $e');
      emit(ValidationError('Error during validation: $e'));
    }
  }

  Future<void> validateWithoutBackorder(int pickingId) async {
    try {
      final result = await odooService.callKw({
        "model": 'psi.stock.picking.request', // Model name
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

      print("🔵 Server response: $result");

      if (result == true) {
        print("✅ Validation successful without creating backorder");
        emit(NoBackOrderValidationSuccess());
        await fetchDetail(pickingId);
        emit(NavigateToStockPickingRequestPage());
      } else {
        print("❌ Validation failed - unexpected response: $result");
        emit(NoBackOrderValidationError('Validation failed: $result'));
      }
    } catch (e) {
      print("❌ Error during validation: $e");
      emit(NoBackOrderValidationError('Error during validation: $e'));
    }
  }
}
