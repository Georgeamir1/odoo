import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../networking/odoo_service.dart';
import 'warehouse_stock_status.dart';

class WarehouseStockCubit extends Cubit<WarehouseStockState> {
  WarehouseStockCubit() : super(WarehouseStockInitial());

  static WarehouseStockCubit get(context) => BlocProvider.of(context);
  final OdooRpcService odooService = OdooRpcService();
  List<Map<String, dynamic>> allStockItems = [];
  List<Map<String, dynamic>> filteredStockItems = [];
  int currentDisplayLength = 20;
  String searchQuery = '';

  // Fetch stock quantities for the logged-in user's warehouse
  Future<void> fetchWarehouseStock() async {
    try {
      emit(WarehouseStockLoading());
      final prefs = await SharedPreferences.getInstance();
      final userData = await odooService.getCurrentUser();
      if (userData == null) {
        emit(const WarehouseStockError('User data not found'));
        return;
      }
      // Fetch stock quants from Odoo - get all stock items with positive quantity
      final stockItems = await odooService.fetchRecords(
        'stock.quant', // Model name for stock quantities
        [
          [
            'warehouse_id',
            '=',
            userData['property_warehouse_id'][0]
          ], // Only show items with positive quantity
        ],
        [
          'id',
          'product_id',
          'location_id',
          'quantity',
          'reserved_quantity',
          'product_uom_id',
          'lot_id',
          'package_id',
        ],
      );

      // Process the stock items
      allStockItems = List<Map<String, dynamic>>.from(stockItems);
      _applyFilters();

      emit(WarehouseStockLoaded(
        filteredStockItems.take(currentDisplayLength).toList(),
        hasMore: currentDisplayLength < filteredStockItems.length,
      ));
    } catch (e) {
      emit(WarehouseStockError('Failed to fetch stock data: ${e.toString()}'));
    }
  }

  // Load more items when scrolling
  void loadMore() {
    if (state is WarehouseStockLoaded) {
      final currentState = state as WarehouseStockLoaded;
      if (currentState.hasMore) {
        currentDisplayLength += 20;
        emit(WarehouseStockLoaded(
          filteredStockItems.take(currentDisplayLength).toList(),
          hasMore: currentDisplayLength < filteredStockItems.length,
        ));
      }
    }
  }

  // Search functionality
  void search(String query) {
    searchQuery = query.toLowerCase();
    _applyFilters();
    currentDisplayLength = 20;

    emit(WarehouseStockLoaded(
      filteredStockItems.take(currentDisplayLength).toList(),
      hasMore: currentDisplayLength < filteredStockItems.length,
    ));
  }

  // Apply filters to the stock items
  void _applyFilters() {
    if (searchQuery.isEmpty) {
      // If no search query, show all items
      filteredStockItems = List.from(allStockItems);
      return;
    }

    filteredStockItems = allStockItems.where((item) {
      // Get product name and location name
      final productName = item['product_id'] != null &&
              item['product_id'] is List &&
              item['product_id'].length > 1
          ? item['product_id'][1].toString().toLowerCase()
          : '';

      final locationName = item['location_id'] != null &&
              item['location_id'] is List &&
              item['location_id'].length > 1
          ? item['location_id'][1].toString().toLowerCase()
          : '';

      // Get lot/serial number if available
      final lotId = item['lot_id'];
      final lotName = lotId != null && lotId is List && lotId.length > 1
          ? lotId[1].toString().toLowerCase()
          : '';

      // Get package if available
      final packageId = item['package_id'];
      final packageName =
          packageId != null && packageId is List && packageId.length > 1
              ? packageId[1].toString().toLowerCase()
              : '';

      // Check if any of these fields contain the search query
      return productName.contains(searchQuery) ||
          locationName.contains(searchQuery) ||
          lotName.contains(searchQuery) ||
          packageName.contains(searchQuery);
    }).toList();
  }

  // Fetch details for a specific stock item
  Future<void> fetchStockItemDetail(int stockItemId) async {
    emit(WarehouseStockDetailLoading());
    try {
      final result = await odooService.fetchRecords(
        'stock.quant',
        [
          ['id', '=', stockItemId]
        ],
        [],
      );

      if (result.isEmpty) {
        emit(const WarehouseStockDetailError(
            'No details found for this stock item.'));
        return;
      }

      final stockItem = result.first;
      emit(WarehouseStockDetailLoaded(stockItem));
    } catch (e) {
      emit(WarehouseStockDetailError(
          'Failed to fetch stock item details: ${e.toString()}'));
    }
  }
}
