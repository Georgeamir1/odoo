abstract class DeliveryOrderState {}

class DeliveryOrderInitial extends DeliveryOrderState {}

class DeliveryOrderLoading extends DeliveryOrderState {}

class DeliveryOrderLoaded extends DeliveryOrderState {
  final List<dynamic> orders;
  DeliveryOrderLoaded(this.orders);
}
class DeliveryOrderSuccess extends DeliveryOrderState {
  final int saleOrderId;
  DeliveryOrderSuccess(this.saleOrderId);
}
class DeliveryOrderError extends DeliveryOrderState {
  final String message;
  DeliveryOrderError(this.message);
}
abstract class DeliveryOrderDetailState {}

class DeliveryOrderDetailLoading extends DeliveryOrderDetailState {}
class DeliveryOrderDetailLoaded extends DeliveryOrderDetailState {
  final Map<String, dynamic> detail;
  final Map<String, dynamic> picking;
  DeliveryOrderDetailLoaded(this.detail, this.picking);
}
class DeliveryOrderDetailError extends DeliveryOrderDetailState {
  final String message;
  DeliveryOrderDetailError(this.message);
}
class DeliveryOrdervalidationError extends DeliveryOrderDetailState {
  final String message;
  DeliveryOrdervalidationError(this.message);
}
class DeliveryOrdervalidationSuccess extends DeliveryOrderDetailState {}
class NavigateToDeliveryOrderPage extends DeliveryOrderDetailState {}
class DeliveryOrdervalidationLoadin extends DeliveryOrderDetailState {}
class BackOrderValidationSuccess extends DeliveryOrderDetailState {}
class NoBackOrderValidationSuccess extends DeliveryOrderDetailState{}
class BackOrderValidationError extends DeliveryOrderDetailState{
  final String message;
  BackOrderValidationError(this.message);
}
class NoBackOrderValidationError extends DeliveryOrderDetailState{
  final String message;
  NoBackOrderValidationError(this.message);
}

