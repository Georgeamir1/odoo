import 'package:equatable/equatable.dart';

abstract class StockPickingRequestState extends Equatable {
  const StockPickingRequestState();

  @override
  List<Object?> get props => [];
}

// Initial state
class StockPickingRequestInitial extends StockPickingRequestState {}

// Loading states
class StockPickingRequestLoading extends StockPickingRequestState {}

class StockPickingRequestDetailLoading extends StockPickingRequestState {}

// Success states
class StockPickingRequestLoaded extends StockPickingRequestState {
  final List<Map<String, dynamic>> requests;
  final bool hasMore;

  const StockPickingRequestLoaded(this.requests, {this.hasMore = false});

  @override
  List<Object?> get props => [requests, hasMore];
}

class StockPickingRequestDetailLoaded extends StockPickingRequestState {
  final Map<String, dynamic> detail;
  final Map<String, dynamic> originalPicking;

  const StockPickingRequestDetailLoaded(this.detail, this.originalPicking);

  @override
  List<Object?> get props => [detail, originalPicking];
}

// Error states
class StockPickingRequestError extends StockPickingRequestState {
  final String message;

  const StockPickingRequestError(this.message);

  @override
  List<Object?> get props => [message];
}

class StockPickingRequestDetailError extends StockPickingRequestState {
  final String message;

  const StockPickingRequestDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

// Action states
class ValidationSuccess extends StockPickingRequestState {}

class ValidationError extends StockPickingRequestState {
  final String message;

  const ValidationError(this.message);

  @override
  List<Object?> get props => [message];
}

class NoBackOrderValidationSuccess extends StockPickingRequestState {}

class NoBackOrderValidationError extends StockPickingRequestState {
  final String message;

  const NoBackOrderValidationError(this.message);

  @override
  List<Object?> get props => [message];
}

class NavigateToStockPickingRequestPage extends StockPickingRequestState {}
