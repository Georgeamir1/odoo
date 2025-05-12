abstract class invoicingState {}

/// The initial state before any action is taken.
class invoicingInitial extends invoicingState {}

/// Indicates that the sale order creation is in progress.
class invoicingLoading extends invoicingState {}

class invoicingReturnSuccess extends invoicingdetailsState {
  final int? returnPickingId;
  invoicingReturnSuccess(this.returnPickingId);
}

class invoicingLoaded extends invoicingState {
  final List<Map<String, dynamic>> orders;
  final bool hasReachedMax;
  invoicingLoaded(this.orders, {this.hasReachedMax = false});
  @override
  List<Object> get props => [orders, hasReachedMax];
}

/// Indicates that the sale order was created successfully.
class invoicingSuccess extends invoicingState {
  final int saleOrderId;
  invoicingSuccess(this.saleOrderId);
}

/// Indicates an error occurred while creating the sale order.
class invoicingError extends invoicingState {
  final String message;
  invoicingError(this.message);
}

//_______________________________________________________________________
abstract class invoicingdetailsState {}

class invoicingdetailsLoading extends invoicingdetailsState {}

class deliveryOrderLoading extends invoicingdetailsState {}

class invoicingdetailsLoaded extends invoicingdetailsState {
  final Map<String, dynamic> detail;
  final Map<String, dynamic> picking;
  invoicingdetailsLoaded(this.detail, this.picking);
}

class invoicingdetailsError extends invoicingdetailsState {
  final String message;
  invoicingdetailsError(this.message);
}

class deliveryOrderSuccess extends invoicingdetailsState {
  final int pickingId;
  deliveryOrderSuccess(this.pickingId);
}

class deliveryOrderLoaded extends invoicingdetailsState {
  final List<dynamic> deliveries;
  deliveryOrderLoaded(this.deliveries);
}

class deliveryOrderError extends invoicingdetailsState {
  final String message;
  deliveryOrderError(this.message);
}

class invoicingdetailsvalidationError extends invoicingdetailsState {
  final String message;
  invoicingdetailsvalidationError(this.message);
}

class invoicingdetailsvalidationSuccess extends invoicingdetailsState {}

class NavigateToinvoicingdetailsPage extends invoicingdetailsState {}

class invoicingdetailsvalidationLoadin extends invoicingdetailsState {}

class BackOrderValidationSuccess extends invoicingdetailsState {}

class NoBackOrderValidationSuccess extends invoicingdetailsState {}

class BackOrderValidationError extends invoicingdetailsState {
  final String message;
  BackOrderValidationError(this.message);
}

class NoBackOrderValidationError extends invoicingdetailsState {
  final String message;
  NoBackOrderValidationError(this.message);
}

class invoicingdetailsReversalSuccess extends invoicingdetailsState {
  final int? reversedInvoiceId;
  invoicingdetailsReversalSuccess(this.reversedInvoiceId);
}

class invoicingUpdateSuccess extends invoicingdetailsState {
  final int invoiceId;
  invoicingUpdateSuccess(this.invoiceId);
}

class invoicingPostSuccess extends invoicingdetailsState {
  final int invoiceId;
  invoicingPostSuccess(this.invoiceId);
}
