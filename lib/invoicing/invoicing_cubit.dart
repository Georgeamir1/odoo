import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo/invoicing/invoicing_status.dart';
import 'package:odoo/sales_order/sales_order_status.dart';
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
          ['move_id', '=', pickingId]
        ],
        [
          "name",
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
}
