class PartnersState {}

class PartnersLoadingState extends PartnersState {}

class PartnersErrorState extends PartnersState {
  final String error;
  PartnersErrorState(this.error);
}

class PartnersLoadedState extends PartnersState {
  final String? selectedCustomer;
  final String? selectedCustomerId;
  final List<dynamic> partners;

  PartnersLoadedState(
    this.partners, {
    this.selectedCustomer,
    this.selectedCustomerId,
  });
}

//_______________________________________________________________________
class ProductsState {}

class ProductsLoadingState extends ProductsState {}

class ProductsErrorState extends ProductsState {
  final String error;
  ProductsErrorState(this.error);
}

class ProductsLoadedState extends ProductsState {
  final List<dynamic> Products;
  final String? selectedProducts; // Add selectedCustomer here

  ProductsLoadedState(this.Products, {this.selectedProducts});
}

//_______________________________________________________________________
class TaxesState {} // Create a new state class for taxes

class TaxesLoadingState
    extends TaxesState {} // Create a new loading state for taxes

class TaxesamountLoadedState extends TaxesState {
  TaxesamountLoadedState(double amount);
} // Create a new loading state for taxes

class TaxesErrorState extends TaxesState {
  // Create a new error state for taxes
  final String error;
  TaxesErrorState(this.error);
}

class TaxesLoadedState extends TaxesState {
  // Create a new loaded state for taxes
  final List<dynamic> taxes;
  final String? selectedTaxes; // Add selectedTaxes here

  TaxesLoadedState(this.taxes, {this.selectedTaxes});
}
//_______________________________________________________________________

abstract class SalesOrderState {}

class SalesOrderInitial extends SalesOrderState {}

class SalesOrderLoading extends SalesOrderState {}

class SalesOrderCreated extends SalesOrderState {
  final int orderId;
  SalesOrderCreated(this.orderId);
}

class SalesOrderError extends SalesOrderState {
  final String error;
  SalesOrderError(this.error);
}

class SalesOrderStatusUpdated extends SalesOrderState {
  final String status;
  SalesOrderStatusUpdated(this.status);
}

//_______________________________________________________________________

class PaymentTermState {}

class PaymentTermLoadingState extends PaymentTermState {}

class PaymentTermErrorState extends PaymentTermState {
  final String error;
  PaymentTermErrorState(this.error);
}

class PaymentTermLoadedState extends PaymentTermState {
  final List<dynamic> paymentTerm;
  final String? selectedPaymentTerm;
  final String? selectedPaymentTermId;

  PaymentTermLoadedState(this.paymentTerm,
      {this.selectedPaymentTerm, this.selectedPaymentTermId});
}
//_______________________________________________________________________

abstract class SaleOrderState {}

/// The initial state before any action is taken.
class SaleOrderInitial extends SaleOrderState {}

/// Indicates that the sale order creation is in progress.
class SaleOrderLoading extends SaleOrderState {}

class SaleOrderLoaded extends SaleOrderState {
  final List<Map<String, dynamic>> orders;
  final bool hasReachedMax;
  SaleOrderLoaded(this.orders, {this.hasReachedMax = false});
  @override
  List<Object> get props => [orders, hasReachedMax];
}

/// Indicates that the sale order was created successfully.
class SaleOrderSuccess extends SaleOrderState {
  final int saleOrderId;
  SaleOrderSuccess(this.saleOrderId);
}

/// Indicates an error occurred while creating the sale order.
class SaleOrderError extends SaleOrderState {
  final String message;
  SaleOrderError(this.message);
}

//_______________________________________________________________________
abstract class SaleOrderdetailsState {}

class SaleOrderdetailsLoading extends SaleOrderdetailsState {}

class SaleOrderdetailsLoaded extends SaleOrderdetailsState {
  final Map<String, dynamic> detail;
  final Map<String, dynamic> picking;
  SaleOrderdetailsLoaded(this.detail, this.picking);
}

class SaleOrderdetailsError extends SaleOrderdetailsState {
  final String message;
  SaleOrderdetailsError(this.message);
}

class SaleOrderdetailsvalidationError extends SaleOrderdetailsState {
  final String message;
  SaleOrderdetailsvalidationError(this.message);
}

class SaleOrderdetailsvalidationSuccess extends SaleOrderdetailsState {}

class NavigateToSaleOrderdetailsPage extends SaleOrderdetailsState {}

class SaleOrderdetailsvalidationLoadin extends SaleOrderdetailsState {}

class BackOrderValidationSuccess extends SaleOrderdetailsState {}

class NoBackOrderValidationSuccess extends SaleOrderdetailsState {}

class BackOrderValidationError extends SaleOrderdetailsState {
  final String message;
  BackOrderValidationError(this.message);
}

class NoBackOrderValidationError extends SaleOrderdetailsState {
  final String message;
  NoBackOrderValidationError(this.message);
}
