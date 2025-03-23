
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo/sales_order/sales_order_status.dart';
import 'package:odoo_rpc/odoo_rpc.dart';

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
      List<dynamic> partners =
          await odooService.fetchRecords("res.partner", [], ["name", "email","id"], );
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
          await odooService.fetchRecords("product.template", [], [
        "name",
        "id",
        "list_price",
        "qty_available",
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

  void setSelectedPaymentTerm(String? PaymentTermName,PaymentTermId) {
    if (state is PaymentTermLoadedState) {
      final currentState = state as PaymentTermLoadedState;
      emit(PaymentTermLoadedState(
          currentState.paymentTerm,
          selectedPaymentTerm: PaymentTermName,
          selectedPaymentTermId: PaymentTermId
      ));
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
  // Convenience getter to retrieve the cubit instance from the context.
  static SaleOrderCubit get(BuildContext context) => BlocProvider.of<SaleOrderCubit>(context);

  final odooService = OdooRpcService();

  SaleOrderCubit() : super(SaleOrderInitial());

  /// Creates a sale order using the provided [orderData] map,
  /// then confirms the order by calling the 'action_confirm' method.
  Future<void> createAndConfirmSaleOrder(Map<String, dynamic> orderData) async {
    emit(SaleOrderLoading());
    try {
      // Create the sale order.
      final saleOrderId = await odooService.createRecord("sale.order", orderData);
      if (saleOrderId != null) {
        // Confirm the sale order by calling action_confirm.
        await odooService.client.callKw({
          'model': 'sale.order',
          'method': 'action_confirm',
          'args': [
            [saleOrderId]
          ],
          'kwargs': {}
        });
        print("Sale Order Created and Confirmed: $saleOrderId");
        emit(SaleOrderSuccess(saleOrderId));
      } else {
        emit(SaleOrderError("Failed to create sale order."));
      }
    } catch (e) {
      print(e);
      emit(SaleOrderError(e.toString()));
    }
  }

  /// Creates a delivery order based on the provided [orderData].
  Future<void> createAndConfirmStockPicking({
    required int partnerId,
    required int pickingTypeId,
    required int locationId,
    required int locationDestId,
    required List<OrderLine> orderLines,
  }) async {
    try {
      final moveIdsWithoutPackage = orderLines.map((line) {
        if (line.productId == null || line.quantity == null || line.unitId == null) {
          throw Exception("🚨 Invalid order line data: ${jsonEncode(line.toJson())}");
        }
        return [
          0,
          0,
          {
            "name": line.selectedProduct ?? "Unnamed Product",
            "product_id": line.productId,
            "product_uom_qty": line.quantity,
            "product_uom": line.unitId,
            "location_id": locationId,
            "location_dest_id": locationDestId,
          }
        ];
      }).toList();

      final pickingData = {

        "partner_id": partnerId,
        "picking_type_id": pickingTypeId,
        "location_id": locationId,
        "location_dest_id": locationDestId,
        "move_ids_without_package": moveIdsWithoutPackage,
      };

      print("📦 Sending Picking Data: ${jsonEncode(pickingData)}");

      // Step 1: Create Stock Picking
      final pickingId = await odooService.client.callKw({
        'model': 'stock.picking',
        'method': 'create',
        'args': [pickingData],
        'kwargs': {},
      });

      print("✅ Stock Picking Created Successfully: ID = $pickingId");

      // Step 2: Confirm Stock Picking
      final confirmResponse = await odooService.client.callKw({
        'model': 'stock.picking',
        'method': 'action_confirm',
        'args': [[pickingId]],
        'kwargs': {},
      });

      print("✅ Stock Picking Confirmed: $confirmResponse");
    } catch (e) {
      print("❌ Error creating or confirming stock picking: ${e.toString()}");
      if (e is OdooException) {
        print("OdooException Details: ${e.message}");
      }
    }
  }

  Future<void> createInventoryReceipt(Map<String, dynamic> pickingData) async {
    emit(SaleOrderLoading());
    try {
      final receiptId = await odooService.createRecord("stock.picking", pickingData);
      if (receiptId != null) {
        await odooService.client.callKw({
          'model': 'stock.picking',
          'method': 'button_validate', // Confirms the inventory receipt
          'args': [[receiptId]],
          'kwargs': {}
        });
        print("Inventory Receipt Created & Confirmed: $receiptId");
        emit(SaleOrderSuccess(receiptId));
      } else {
        emit(SaleOrderError("Failed to create Inventory Receipt."));
      }
    } catch (e) {
      print(e);
      emit(SaleOrderError(e.toString()));
    }
  }
}