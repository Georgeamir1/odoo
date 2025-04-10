import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo/sales_order/sales_order_status.dart';
import '../InventoryReceipts/new_inventory_receipt.dart';
import '../networking/odoo_service.dart';

class PartnersCubit extends Cubit<PartnersState> {
  final odooService = OdooRpcService();

  PartnersCubit() : super(PartnersLoadingState());
  static PartnersCubit get(context) => BlocProvider.of(context);

  void getPartners() async {
    emit(
        PartnersLoadingState()); // Emit loading state before starting the request
    try {
      List<dynamic> partners = await odooService.fetchRecords(
        "res.partner",
        [
          ["active", "=", true],
          ["customer_rank", "=", "1"]
        ],
        ["name", "email", "id", "property_product_pricelist"],
      );
      emit(PartnersLoadedState(partners)); // Emit success state with partners
    } catch (e) {
      emit(PartnersErrorState(
          e.toString())); // Emit error state if something goes wrong
    }
  }

  void setSelectedCustomer(String? customerName, String? customerId) {
    if (state is PartnersLoadedState) {
      final currentState = state as PartnersLoadedState;
      emit(PartnersLoadedState(
        currentState.partners,
        selectedCustomer: customerName,
        selectedCustomerId: customerId,
      ));
    }
  }

  List<dynamic> get Customers {
    if (state is PartnersLoadedState) {
      return (state as PartnersLoadedState).partners;
    }
    return []; // Return an empty list if partners are not loaded yet
  }
}

class ProductsCubit extends Cubit<ProductsState> {
  final odooService = OdooRpcService();

  ProductsCubit() : super(ProductsLoadingState());
  static ProductsCubit get(context) => BlocProvider.of(context);

  void getProducts() async {
    emit(
        ProductsLoadingState()); // Emit loading state before starting the request
    try {
      List<dynamic> Products =
          await odooService.fetchRecords("product.template", [
        ["active", "=", true]
      ], [
        "name",
        "id",
        "list_price",
        "qty_available",
        "product_variant_ids",
        "taxes_id",
      ]);
      emit(ProductsLoadedState(Products)); // Emit success state with Products
    } catch (e) {
      emit(ProductsErrorState(
          e.toString())); // Emit error state if something goes wrong
    }
  }

  void setSelectedProduct(String? ProductName) {
    if (state is ProductsLoadedState) {
      final currentState = state as ProductsLoadedState;
      emit(ProductsLoadedState(currentState.Products,
          selectedProducts: ProductName));
    }
  }

  List<dynamic> get Products {
    if (state is ProductsLoadedState) {
      return (state as ProductsLoadedState).Products;
    }
    return []; // Return an empty list if partners are not loaded yet
  }
}

class PricelistCubit extends Cubit<ProductsState> {
  final OdooRpcService odooService = OdooRpcService();

  PricelistCubit() : super(ProductsLoadingState());

  static PricelistCubit get(context) => BlocProvider.of(context);

  // جلب السعر بناءً على pricelist_id و product_id
  void getProductPrice(
    int pricelistId,
    int productId,
  ) async {
    emit(ProductsLoadingState());
    try {
      List<dynamic> result = await odooService.fetchRecords(
        "product.pricelist.item",
        [
          ["pricelist_id", "=", pricelistId],
          ["product_tmpl_id", "=", productId]
        ],
        ["fixed_price"],
      );

      if (result.isNotEmpty) {
        double price = result.first["fixed_price"] ?? 0.0;

        emit(ProductPriceLoadedState(price));
      } else {
        emit(ProductsErrorState("No price found for this product"));
      }
    } catch (e) {
      emit(ProductsErrorState(e.toString()));
    }
  }
}

class ProductPriceLoadedState extends ProductsState {
  final double price;
  ProductPriceLoadedState(this.price);
}

class TaxesCubit extends Cubit<TaxesState> {
  final odooService = OdooRpcService();

  TaxesCubit() : super(TaxesLoadingState());
  static TaxesCubit get(context) => BlocProvider.of(context);
  void getTaxes() async {
    emit(TaxesLoadingState()); // Emit loading state before starting the request
    try {
      List<dynamic> taxes = await odooService.fetchRecords("account.tax", [
        ["type_tax_use", "=", "sale"]
      ], [
        "id",
        "name",
        "amount",
        "type_tax_use"
      ]);
      emit(TaxesLoadedState(taxes)); // Emit success state with Taxes
    } catch (e) {
      emit(TaxesErrorState(
          e.toString())); // Emit error state if something goes wrong
    }
  }

  void setSelectedProduct(String? taxName) {
    if (state is TaxesLoadedState) {
      final currentState = state as TaxesLoadedState;
      emit(TaxesLoadedState(currentState.taxes, selectedTaxes: taxName));
    }
  }

  void getTaxesamount(int? taxid) async {
    emit(TaxesLoadingState());
    try {
      List<dynamic> result = await odooService.fetchRecords(
        "account.tax",
        [
          ["id", "=", taxid],
        ],
        ["amount"],
      );

      if (result.isNotEmpty) {
        double amount = result.first["amount"] ?? 0.0;

        emit(TaxesamountLoadedState(amount));
      } else {
        emit(TaxesErrorState("No price found for this product"));
      }
    } catch (e) {
      emit(TaxesErrorState(e.toString()));
    }
  }

  List<dynamic> get taxes {
    if (state is TaxesLoadedState) {
      return (state as TaxesLoadedState).taxes;
    }
    return []; // Return an empty list if partners are not loaded yet
  }
}

class PaymentTermCubit extends Cubit<PaymentTermState> {
  final odooService = OdooRpcService();

  PaymentTermCubit() : super(PaymentTermLoadingState());
  static PaymentTermCubit get(context) => BlocProvider.of(context);

  void getPaymentTerm() async {
    emit(
        PaymentTermLoadingState()); // Emit loading state before starting the request
    try {
      List<dynamic> PaymentTerm = await odooService.fetchRecords(
          "account.payment.term", [], ["id", "name", "note", "line_ids"]);
      emit(PaymentTermLoadedState(
          PaymentTerm)); // Emit success state with PaymentTerm
    } catch (e) {
      emit(PaymentTermErrorState(
          e.toString())); // Emit error state if something goes wrong
    }
  }

  void setSelectedPaymentTerm(String? PaymentTermName, PaymentTermId) {
    if (state is PaymentTermLoadedState) {
      final currentState = state as PaymentTermLoadedState;
      emit(PaymentTermLoadedState(currentState.paymentTerm,
          selectedPaymentTerm: PaymentTermName,
          selectedPaymentTermId: PaymentTermId));
    }
  }

  List<dynamic> get PaymentTerm {
    if (state is PaymentTermLoadedState) {
      return (state as PaymentTermLoadedState).paymentTerm;
    }
    return []; // Return an empty list if partners are not loaded yet
  }
}

class SaleOrderCubit extends Cubit<SaleOrderState> {
  static SaleOrderCubit get(BuildContext context) =>
      BlocProvider.of<SaleOrderCubit>(context);
  final odooService = OdooRpcService();

  List<Map<String, dynamic>> allOrders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  int currentDisplayLength = 5;

  SaleOrderCubit() : super(SaleOrderInitial());

  Future<void> fetchSaleOrder() async {
    try {
      emit(SaleOrderLoading());

      final orders = await odooService.fetchRecords(
        'sale.order',
        [],
        [
          'invoice_status',
          'amount_total',
          'partner_id',
          'create_date',
          'name',
          "id"
        ],
      );

      allOrders = List<Map<String, dynamic>>.from(orders);
      filteredOrders = allOrders;
      currentDisplayLength = 5;

      emit(SaleOrderLoaded(
        filteredOrders.take(currentDisplayLength).toList(),
        hasReachedMax: currentDisplayLength >= filteredOrders.length,
      ));
    } catch (e) {
      emit(SaleOrderError("Failed to fetch delivery orders: ${e.toString()}"));
    }
  }

  void loadMore() {
    if (state is SaleOrderLoaded && !(state as SaleOrderLoaded).hasReachedMax) {
      final newLength = currentDisplayLength + 5;
      final hasReachedMax = newLength >= filteredOrders.length;
      print(1);
      emit(SaleOrderLoaded(
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
          return (order['invoice_status']?.toString().toLowerCase() ?? '')
                  .contains(queryLower) ||
              (order['name']?.toString().toLowerCase() ?? '')
                  .contains(queryLower) ||
              (order['origin']?.toString().toLowerCase() ?? '')
                  .contains(queryLower);
        }).toList();
      }

      currentDisplayLength = 5;
      emit(SaleOrderLoaded(
        filteredOrders.take(currentDisplayLength).toList(),
        hasReachedMax: currentDisplayLength >= filteredOrders.length,
      ));
    } catch (e) {
      emit(SaleOrderError("Error filtering orders: ${e.toString()}"));
    }
  }

  Future<void> createAndConfirmSaleOrder(Map<String, dynamic> orderData) async {
    try {
      emit(SaleOrderLoading());
      final saleOrderId =
          await odooService.createRecord("sale.order", orderData);

      if (saleOrderId != null) {
        await odooService.client.callKw({
          'model': 'sale.order',
          'method': 'action_confirm',
          'args': [
            [saleOrderId]
          ],
          'kwargs': {}
        });
        emit(SaleOrderSuccess(saleOrderId));
        await fetchSaleOrder(); // Refresh the list
      } else {
        emit(SaleOrderError("Failed to create sale order"));
      }
    } catch (e) {
      emit(SaleOrderError("Order creation failed: ${e.toString()}"));
    }
  }

  Future<void> createInventoryReceipt(Map<String, dynamic> pickingData) async {
    try {
      emit(SaleOrderLoading());
      final receiptId =
          await odooService.createRecord("stock.picking", pickingData);

      if (receiptId != null) {
        await odooService.client.callKw({
          'model': 'stock.picking',
          'method': 'button_validate',
          'args': [
            [receiptId]
          ],
          'kwargs': {}
        });
        emit(SaleOrderSuccess(receiptId));
        await fetchSaleOrder(); // Refresh the list
      } else {
        emit(SaleOrderError("Failed to create inventory receipt"));
      }
    } catch (e) {
      emit(SaleOrderError("Receipt creation failed: ${e.toString()}"));
    }
  }

  Future<void> createAndConfirmStockPicking({
    required int partnerId,
    required int pickingTypeId,
    required int locationId,
    required int locationDestId,
    required List<OrderLine> orderLines,
  }) async {
    try {
      emit(SaleOrderLoading());
      final moveIds = orderLines.map((line) {
        if (line.productId == null ||
            line.quantity == null ||
            line.unitId == null) {
          throw Exception("Invalid order line data");
        }
        return [
          0,
          0,
          {
            "name": line.selectedProduct ?? "Product",
            "product_id": line.productId,
            "product_uom_qty": line.quantity,
            "product_uom": line.unitId,
            "location_id": locationId,
            "location_dest_id": locationDestId,
          }
        ];
      }).toList();

      final pickingId = await odooService.client.callKw({
        'model': 'stock.picking',
        'method': 'create',
        'args': [
          {
            "partner_id": partnerId,
            "picking_type_id": pickingTypeId,
            "location_id": locationId,
            "location_dest_id": locationDestId,
            "move_ids_without_package": moveIds,
          }
        ],
        'kwargs': {},
      });

      await odooService.client.callKw({
        'model': 'stock.picking',
        'method': 'action_confirm',
        'args': [
          [pickingId]
        ],
        'kwargs': {},
      });

      emit(SaleOrderSuccess(pickingId));
      await fetchSaleOrder(); // Refresh the list
    } catch (e) {
      emit(SaleOrderError("Picking creation failed: ${e.toString()}"));
    }
  }
}

class SaleOrderdetailsCubit extends Cubit<SaleOrderdetailsState> {
  final OdooRpcService odooService;
  static SaleOrderdetailsCubit get(context) => BlocProvider.of(context);

  SaleOrderdetailsCubit(this.odooService) : super(SaleOrderdetailsLoading());
  List<dynamic> allOrders = []; // Original unfiltered orders list

  /// Fetches delivery orders from Odoo and enriches each order with move details.

  Future<void> fetchDetail(int pickingId) async {
    emit(SaleOrderdetailsLoading());
    try {
      // 1) Fetch picking record
      final result = await odooService.fetchRecords(
        'sale.order',
        [
          ['id', '=', pickingId]
        ],
        [
          'name',
          'amount_untaxed',
          'partner_id',
          'amount_tax',
          'date_order',
          'amount_total',
          'amount_to_invoice',
          'pricelist_id',
          'payment_term_id',
        ],
      );

      if (result.isEmpty) {
        emit(SaleOrderdetailsError('No details found for this order.'));
        return;
      }

      final picking = result.first;

      // 2) Fetch move details
      final moves = await odooService.fetchRecords(
        'sale.order.line',
        [
          ['order_id', '=', pickingId]
        ],
        [
          'name',
          'product_uom_qty',
          'price_total',
          'qty_delivered',
          'qty_invoiced',
          'product_uom',
          'price_unit',
          'tax_id',
          'price_tax',
          'discount',
          'price_subtotal',
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
        'payment_term_id': picking['payment_term_id'],
        'moves': moves,
      };

      emit(SaleOrderdetailsLoaded(detail, picking));
    } catch (e) {
      emit(SaleOrderdetailsError('Failed to fetch delivery order details: $e'));
    }
  }
}
