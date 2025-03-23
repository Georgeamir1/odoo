abstract class InventoryReceiptsState {}

class InventoryReceiptsInitial extends InventoryReceiptsState {}

class InventoryReceiptsLoading extends InventoryReceiptsState {}

class InventoryReceiptsLoaded extends InventoryReceiptsState {
  final List<dynamic> orders;
  InventoryReceiptsLoaded(this.orders);
}
class InventoryReceiptsSuccess extends InventoryReceiptsState {
  final int saleOrderId;
  InventoryReceiptsSuccess(this.saleOrderId);
}
class InventoryReceiptsError extends InventoryReceiptsState {
  final String message;
  InventoryReceiptsError(this.message);
}
abstract class InventoryReceiptsDetailState {}

class InventoryReceiptsDetailLoading extends InventoryReceiptsDetailState {}
class InventoryReceiptsDetailLoaded extends InventoryReceiptsDetailState {
  final Map<String, dynamic> detail;
  final Map<String, dynamic> picking;
  InventoryReceiptsDetailLoaded(this.detail, this.picking);
}
class InventoryReceiptsDetailError extends InventoryReceiptsDetailState {
  final String message;
  InventoryReceiptsDetailError(this.message);
}
class InventoryReceiptsvalidationError extends InventoryReceiptsDetailState {
  final String message;
  InventoryReceiptsvalidationError(this.message);
}
class InventoryReceiptsvalidationSuccess extends InventoryReceiptsDetailState {}
class NavigateToInventoryReceiptsPage extends InventoryReceiptsDetailState {}
class InventoryReceiptsvalidationLoadin extends InventoryReceiptsDetailState {}
class BackOrderValidationSuccess extends InventoryReceiptsDetailState {}
class NoBackOrderValidationSuccess extends InventoryReceiptsDetailState{}
class BackOrderValidationError extends InventoryReceiptsDetailState{
  final String message;
  BackOrderValidationError(this.message);
}
class NoBackOrderValidationError extends InventoryReceiptsDetailState{
  final String message;
  NoBackOrderValidationError(this.message);
}

